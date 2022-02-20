import numpy as np

from NeuralProcessorSimulator import NeuralProcessor


w = np.array([
    [1,2,3,4],
    [5,6,7,8],
    [9,10,11,12],
    [13,14,15,16]
])
x = np.array([5,6,7,8], ndmin=2).T

proc = NeuralProcessor(nu_size=4, xy_mem_size=32, w_mem_size=32)
w_addr = 0
x_addr = 4 
proc.numpy_to_xy_mem(x, x_addr)
proc.numpy_to_w_mem(w, w_addr)


def check_numpy_in_xy(v, proc, addr):
    return list(v.T[0]) == proc.xy_mem[addr:addr+v.shape[0]]

def check_numpy_in_w(w, proc, addr):
    for i in range(w.shape[0]):
        for j in range(w.shape[1]):
            if w[i][j] != proc.w_mem[i][addr+j]:
                return False
    return True

#w.T*x
def test1():
    result_addr = 8
    proc.xy_to_mac_reg(x_addr)
    proc.matmul_t(w_addr=w_addr, y_addr=result_addr, length=w.shape[1], accumulate=0)

    assert check_numpy_in_xy(np.dot(w.T,x), proc, result_addr)
    
#w1+a*w2
def test3():
    x_addr = 4
    result_addr = 4
    proc.mat_update(x_addr=x_addr, w_addr=w_addr, dw_addr=w_addr, result_addr=result_addr, length=4)

    assert check_numpy_in_w(proc.xy_mem[x_addr]*w+w, proc, result_addr)

test1()
test3()

pass

