from math import ceil
from timeit import repeat
import numpy as np

class Layer:

    def __init__(self, x_size, y_size, func_name = None, d_func_name = None, w_np = None) -> None:
        self.x_size = x_size
        self.y_size = y_size
        self.func_name = func_name
        self.d_func_name = d_func_name
        self.w_np = w_np

    def allocate(self, xy_offset, w_offset, prev_layer = None) -> None:
        if prev_layer is None:
            self.X = xy_offset
            xy_offset += self.x_size
        else:
            self.X = prev_layer.Y

        self.Y = xy_offset

        self.W = []
        for _ in range(0,ceil(self.y_size/self.nu_count)):
            self.W.append(w_offset)
            w_offset += self.x_size

        xy_offset += self.y_size

        return xy_offset, w_offset



    def forward_propagate(self):
        y_offset = self.Y
        length = [self.nu_count]*(self.y_size//self.nu_count) + [self.y_size%self.nu_count]

        instructions = []
        
        for w_offset, l in zip(self.W, length):
            instructions.append(f'MATMUL {self.X},{w_offset}')
            instructions.append(f'REPEAT {self.x_size-1}')
            instructions.append(f'ACCMOV {y_offset},{l},{self.func_mask if self.func_mask is not None else 0},{1 if self.func_mask is None else 0},1,0,0')
            for _ in range(l):
                instructions.append('NOP')

            y_offset += self.nu_count

        return instructions

    def backward_propagation(self, dE_dY, learning_rate):
        raise NotImplementedError()

        dE_dV = dE_dY*self.d_func(self.V)
        dE_dW = np.dot(self.X, dE_dV.T).T
        dE_dX = np.dot(self.W.T, dE_dV)

        self.W -= learning_rate * dE_dW

        return dE_dX