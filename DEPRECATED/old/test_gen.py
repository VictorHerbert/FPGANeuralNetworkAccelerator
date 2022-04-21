import enum
import numpy as np
from math import ceil
from itertools import cycle

w = np.array(
    [
        [1,2,3,4,5],
        [5,6,7,8,6],
        [9,10,11,12,7],
        [13,14,15,16,8],
        [17,18,19,20,21],
        [21,22,23,24,22]
    ]
)
x = np.array([1,1,3,4,5], ndmin=2).T




def list_to_mem(l, filename):
    with open(filename, 'w') as f:
        f.write('//format=mti addressradix=d dataradix=d version=1.0 wordsperline=1\n')
        for i, x in enumerate(l):
            f.write(f'{i}: {x}\n')

class NeuralProcessor:
    DUMMY_ADDR = 15

    def __init__(self, nu_size, xy_mem_size, w_mem_size) -> None:
        self.nu_size = nu_size
        self.xy_mem_size = xy_mem_size
        self.w_mem_size = w_mem_size

        self.xy_mem = [0]*self.xy_mem_size
        self.w_mem = [[0]*self.w_mem_size for _ in range(self.nu_size)]


    def numpy_to_xy_mem(self, a, offset):
        for i in range(a.shape[0]):
            self.xy_mem[offset+i] = int(a[i,0])

        return list(range(offset, offset+a.shape[0]))

    def numpy_to_w_mem(self, a, offset):
        #assert a.shape[0] <= self.nu_size
        r = []
        for i in range(a.shape[0]):
            for j in range(a.shape[1]):
                self.w_mem[i%self.nu_size][j+offset+(i//self.nu_size)*a.shape[1]] = int(a[i,j])
        
        for i in range(a.shape[0]//self.nu_size+1):
            r.append(range(offset + i*a.shape[1], offset + (i+1)*a.shape[1]))

        return r

    def to_file(self):
        list_to_mem(nn.xy_mem, 'src/memories/xy.mem')
        list_to_mem(nn.w_mem[0], 'src/memories/w0.mem')
        list_to_mem(nn.w_mem[1], 'src/memories/w1.mem')
        list_to_mem(nn.w_mem[2], 'src/memories/w2.mem')
        list_to_mem(nn.w_mem[3], 'src/memories/w3.mem')
    
    def forward_propagate(self, x_addrs, w_addrs, v_addrs, y_addrs):
        code = ''
        v = 0
        for w_range in w_addrs:
            for x,w in zip(x_addrs, w_range):
                code += f'matmul({x},{w})\n'
            
            for _ in range(self.nu_size):
                if v < len(v_addrs):
                    code += f'acc_mov({v_addrs[v]},1,0)\n'
                    v += 1


        return code
    





nn = NeuralProcessor(4,32,32)
x_addrs = nn.numpy_to_xy_mem(x,0)
w_addrs = nn.numpy_to_w_mem(w,0)
v_addrs = list(range(12,18))
y_addrs = range(8,14)

nn.to_file()
v = np.dot(w,x)

code = nn.forward_propagate(x_addrs, w_addrs, v_addrs, y_addrs)
print(code)

pass


    

