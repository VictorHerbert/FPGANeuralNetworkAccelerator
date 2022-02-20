from random import randint
import numpy as np


class NeuralProcessor:

    def __init__(self, nu_size, xy_mem_size, w_mem_size) -> None:                
        self.nu_size = nu_size
        self.xy_mem_size = xy_mem_size
        self.w_mem_size = w_mem_size

        self.xy_mem = [0]*self.xy_mem_size
        self.w_mem = [[0]*self.w_mem_size for _ in range(self.nu_size)]
        self.acc = [0]*self.nu_size
        self.mac_reg = [0]*self.nu_size



    def act_func(self,x):
        return x

    def numpy_to_xy_mem(self, a, offset):
        assert a.shape[0] <= self.nu_size

        for i in range(w.shape[0]):
            self.xy_mem[offset+i] = int(a[i,0])
        
    def numpy_to_w_mem(self, a, offset):
        assert a.shape[0] <= self.nu_size

        for i in range(w.shape[0]):
            for j in range(w.shape[1]):
                self.w_mem[i][j+offset] = int(a[i,j])
    
    # acc = w[i]*x
    # acc = dot(w,x)
    def matmul(self, x_addr, w_addr, length):
        self.acc = [0]*self.nu_size

        for l in range(length):
            for i in range(self.nu_size): # Parallel
                self.acc[i] += self.xy_mem[x_addr+l]*self.w_mem[i][w_addr+l]
        
    #x[a] = acc
    def acc_to_xy_mem(self,y_addr, length):
        self.xy_mem[y_addr : y_addr+length] = self.act_func(self.acc[0:length])

    #dE_dX = dot(W.T, dE_dV)
    def matmul_t(self, x_addr, y_addr, w_addr, length, accumulate):
        self.mac_reg = self.xy_mem[x_addr:self.nu_size+x_addr]

        for l in range(length):
            self.xy_mem[y_addr+l] = self.act_func(
                self.xy_mem[y_addr+l]*(0 if accumulate else 1) + sum(
                    self.mac_reg[i]*self.w_mem[i][w_addr+l] for i in range(self.nu_size))
            )

    #w[a:a+l] = temp[0:NU_SIZE]*x[b:b+l]
    #dE_dW = np.dot(self.X, dE_dV.T).T
    #8*ceil(dE_dW/8) must be right padded with zeros
    def vect_to_mat(self, x_addr, de_dv_addr, w_addr, length):
        self.mac_reg = self.xy_mem[de_dv_addr:de_dv_addr+self.nu_size]
        
        for i in range(length):
            for j in range(self.nu_size): # Parallel
                self.w_mem[j][w_addr+i] = self.mac_reg[j]*self.xy_mem[x_addr+i]
                
    #w[a] = w[b]*x
    #learning_rate * dE_dW
    def w_prod_by_const(self, x_addr, w_addr, dw_addr, length):
        for l in range(length):
            for j in range(self.nu_size): # Parallel
                self.w_mem[j][dw_addr+l] = self.xy_mem[x_addr]*self.w_mem[j][w_addr+l]

    #w[a] += w[b]
    #self.W -= learning_rate * dE_dW
    def w_acc(self, w_addr, dw_addr, length):
        for l in range(length):
            self.acc = [0]*self.nu_size # by setting b to 0 in a+b

            for j in range(self.nu_size): # Parallel
                self.acc[j] += self.w_mem[j][w_addr+l]
                self.w_mem[j][dw_addr+l] = self.w_mem[j][dw_addr+l]+self.acc[j]




'''
dE_dV = dE_dY*self.d_func(self.V)
dE_dW = np.dot(self.X, dE_dV.T).T
dE_dX = np.dot(self.W.T, dE_dV)

self.W -= learning_rate * dE_dW
'''
    

w = np.array(
    [
        [1,2,3,4],
        [5,6,7,8],
        [9,10,11,12],
        [13,14,15,16]
    ]
)
x = np.array([1,-1,3,4], ndmin=2).T
y = np.array([5,6,7,8], ndmin=2).T

z = np.dot(x, y.T).T

nproc = NeuralProcessor(nu_size=4, xy_mem_size=32, w_mem_size=32)
nproc.numpy_to_xy_mem(x,0)
nproc.numpy_to_xy_mem(y,4)
nproc.numpy_to_w_mem(w,0)

#nproc.matmul_t(x_addr=0, y_addr=4, w_addr=0, length=4, accumulate=False)
#nproc.vect_to_mat(x_addr=0, de_dv_addr=4, w_addr=4, length=4)

nproc.w_prod_by_const(x_addr=1,w_addr=0,dw_addr=4,length=3)
nproc.w_acc(w_addr=4,dw_addr=0, length=3)

pass