import numpy as np

class NeuralProcessor:

    def __init__(self, nu_size, xy_mem_size, w_mem_size) -> None:
        self.xy_mem_size = xy_mem_size
        self.nu_size = nu_size
        self.w_mem_size = w_mem_size

        self.xy_mem = [0]*self.xy_mem_size
        self.w_mem = [[0]*self.w_mem_size for _ in range(self.nu_size)]

    def numpy_to_xy_mem(self, a, offset):
        for i in range(a.shape[0]):
            self.xy_mem[offset+i] = to_fx(a[i,0])

    def numpy_to_w_mem(self, a, offset):
        assert a.shape[0] <= self.nu_size

        for i in range(a.shape[0]):
            for j in range(a.shape[1]):
                self.w_mem[i][j+offset] = to_fx(a[i,j])

def list_to_mem(l, filename):
    with open(filename, 'w') as f:
        f.write('//format=mti addressradix=d dataradix=d version=1.0 wordsperline=1\n')
        for i, x in enumerate(l):
            f.write(f'{i}: {int(x)}\n')

def to_fx(x, q_int = 4, q_frac = 12):
    assert -2**(q_int-1) <= x <= 2**(q_int-1)-2**(-q_frac)
    return round(x*2**q_frac)


NU_SIZE = 4
XY_MEM_DEPTH = 2**5
W_MEM_DEPTH = 2**5


if __name__ == '__main__':
    nn = NeuralProcessor(NU_SIZE, XY_MEM_DEPTH, W_MEM_DEPTH)
    nn.numpy_to_xy_mem(np.array([0,1,2,3,4], ndmin=2).T, 0)
    nn.numpy_to_w_mem(np.array([x/4 for x in list(range(-32,32))]).reshape(16,4).T, 0)

    list_to_mem(nn.xy_mem, 'src/memories/xy.mem')

    for i in range(NU_SIZE):
        list_to_mem(nn.w_mem[i], f'src/memories/w{i}.mem')

