
from __future__ import division
"""
Date: 2012-3-13
Author: Yao-zhong Zhang
Description:  The first implementation of PLSA algorithm

Input: Y - matrix:   I*K
           X - matrix    I*J

Advantage of PLSR: when the feature is far more large than #(instance)  <singular>,
solution 1:  SVD(X) = SDV', where S'S = V'V =I. 
                     S is used to do regression for Y
                     Problem: optium subset is only for explain X, not Y

Advantage: PLSR, find components from X that are also relevent for Y

Output:  components (latent vectors) from X that are also relvent for Y
Process: search for a set of componets that performs a simultaneous decomposition of X and Y 
               s.t.,  latent vectors explain as much as possible of the covariance between X and Y.
                The following is regression for decomposition of X to predict Y
                
Point for performance:   find the number of latent variables
                                          General solution:  cross-validation tech, like bootstrapping.
"""

"""
Test Example:
Y:   14   7    8
      10   7    6
      8     5    5
      2     4    7
      6     2    4
      
 X:   7   7   13   7
       4    3   14  7
      10   5   12  5
      16   7   11  3
      13   3   10  3  
       
"""
from numpy import *
from numpy.linalg import *
from random import sample


Y = array([  [14 ,  7 ,  8],
                    [10 ,  7,    6],
                    [8 ,    5,    5],
                    [2,    4,     7],
                    [6,    2,    4]   ])

X= array([  [7,  7,   13,   7],
                    [4,  3,   14,  7],
                    [10, 5,  12,  5],
                    [16, 7,  11,  3],
                    [13, 3,  10,  3] ])
"""
U, sigma, V = svd(X)

print "X shape is :", X.shape
print "U shape is:", U.shape
print "V shape is:", V.shape

Sigma = zeros_like(X)
n = min(X.shape)
Sigma[:n, :n] = diag(sigma)
"""
###############################
# play with the NIPAL algorithms for PLSR
###############################
"""
Standard algorithm for computing PLSR components
X and Y should transform to the zero means
"""
"""
Zero mean for the matrix
Zscore
"""


def zscore(X):
	Xmean = mean(X, axis=0)
	Xstd = std(X, axis=0)
	Xnew = (X-Xmean)/Xstd
	
	return Xnew


def PLSR_NIPALS1(X, Y, ncomp):
    X = zscore(X)
    Y = zscore(Y)

    # Initialization
    A = dot(X.T, Y)
    M = dot(X.T, X)
    C  = eye(A.shape[0])
    
    W = zeros((A.shape[0], ncomp))
    P =  zeros((M.shape[0], ncomp))
    Q =  zeros((A.shape[1], ncomp))
    
    for i in range(ncomp):
        U,sigma, V = svd(dot(A.T, A))
        n = min(U.shape)
        eV = U[:n, 0]
        w = dot(C, dot(A, eV))
        w = w/norm(w, 2)
        #store w as a column of W
        W[:W.shape[0], i] = w
        
        
        p = dot(M, w)
        c = dot(w.T, p)
        p = p/c
        # store p as a column of P
        P[:P.shape[0], i] = p
        
        q = dot(A.T, w)/c
        # store q as a column of Q
        Q[:Q.shape[0], i] = q
        
        A = A - c*outer(p,q)
        M = M - c*outer(p,p)
        C = C - outer(w, p)
        
    # calculate factor scores
    T = dot(X, W)
    B = dot(W, Q.T)

    return (T, B)


def update(u, X, Y):
	
	w = dot(X.T, u)/(dot(u.T, u))
	w = w/norm(w)
	t = dot(X, w)/(dot(w.T, w))	
        t = t/norm(t)
        q = dot(Y.T, t)/(dot(t.T, t))
	q = q/norm(q)
	u_new = dot(Y, q)/(dot(q.T, q))
	
	return w, t, q, u_new 


def PLSR_NIPALS2(X, Y, ncomp, epsilon):

        X_ori = X.copy()
        Y_ori = Y.copy()

	Xmean = mean(X, axis=0)
	Ymean = mean(Y, axis=0)
	Xc = X - Xmean
	Yc = Y - Ymean
	
	Xstd = std(X, axis=0)
	Ystd = std(Y, axis=0)
	
	X = Xc/Xstd
	Y = Yc/Ystd

	# initial guess for w, check other selection creitia
	u = Y[:,0]

	for i in range(ncomp):
		eps = 1
		while(eps > epsilon):
			w,t,q,u_new = update(u,X,Y)
			eps = norm(u-u_new)
			u = u_new
		
		# compute loadings for the current compoent
		p = dot(X.T, t)/(dot(t.T,t))
		
		# calcualte b
		b = dot(t.T, u)
		
		if i == 0:
			W = w
			T = t
			Q = q
			P = p
			U = u
			BD = b
		else:
			#Take care of the meaning 
			T = vstack((T,t))
			P = vstack((P,p))		
			W = vstack((W,w))
			Q = vstack((Q,q))
			U = vstack((U,u))
			BD = hstack((BD,b))
			
		X_new = X - outer(t, p.T)
		Y_new = Y - outer(t, q.T)*b
		
		X = X_new
		Y = Y_new
		
		# reset u for the next iteration
		u = Y[:,0]
	
	#Caluate coefficients --- ?
	

        BD = diag(BD)
    
	Wstar = dot(W.T, inv(dot(P, W.T)))
        B_pls = dot(dot(Wstar, BD),Q)

        # calculate B_pls_star
        Xstd = reshape(Xstd,(-1,1))
        Ystd = reshape(Ystd,(1,-1))
        B_pls_star = B_pls.T/Xstd*Ystd
        x_unit_score = dot(-Xmean, B_pls_star) + Ymean
        B_pls_star = vstack((B_pls_star, x_unit_score))

	return  B_pls_star, B_pls 

"""
(T, B) = PLSR_NIPALS1(X,Y,3)
print B


B = PLSR_NIPALS2(X,Y,3, 1e-6, True)
print B

"""

# row normalization
def len_norm(X):
    
    for i in range(X.shape[0]):
        length = norm(X[i,:])
        X[i,:] = X[i,:]/length

    return X


def len_norm_center(X):
    
    for i in range(X.shape[0]):
        center = mean(X[i,:])
        length = norm(X[i,:])
        X[i,:] = (X[i,:]-center)/length

    return X

def len_center(X):

    for i in xrange(X.shape[0]):
        center = mean(X[i,:])
        X[i,:] = X[i,:]-center

    return X


def PLSR_R(X, Y, ncomp):
    
    # zscore normalization, normalize are done before call for the function

    # Initialization
    S = dot(X.T, Y)
    
    for i in range(ncomp):
        U,sigma, V = svd(S)
        #store w as a column of W
        
        w = U[:,0]
        q = V[:,0]

        t = dot(X, w)
        u = dot(Y, q)

        t = t/norm(t)

        p = dot(X.T, t)
        q = dot(Y.T, t)


        if i == 0:
            W = w
            T = t
            P = p
            Q = q
        else:
            W = vstack((W,w))
            T = vstack((T,t))
            P = vstack((P,p))
            Q = vstack((Q,q))

        X = X - outer(t, p.T)
        Y = Y - outer(t, q.T)

        S = dot(X.T, Y)
        
    # calculate factor scores
    R = dot(W.T, inv(dot(P, W.T)))
    B = dot(R,Q)
    return B


def linReg(X, Y, lamda):
    
    P = lamda * eye(X.shape[1])
    P[-1,-1] = 0
    try:
        R = inv( dot(X.T, X) + P )
    except:
        R = pinv( dot(X.T, X) + P )

    C = dot(R, X.T)

    S = dot(X, C)
    W = dot(C, Y)

    return W, S

# generate the idx for cross-validation
def cv_idx_gen(nSample, nfold):
    all = set(xrange(nSample))
    included = set(xrange(nSample))
    count = nfold
    
    test_idx = []
    train_idx = []

    while count > 0:
        testing = set(sample(included,int(nSample/nfold)))
        included -= testing
        training = all - testing
        test = list(testing)
        train = list(training)
        count -= 1
        
        test_idx.append(test)
        train_idx.append(train)
        
        #yield test, train

    return train_idx, test_idx

