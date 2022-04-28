from math import ceil
import numpy as np

class Layer:

    def __init__(self, input_size, output_size, func, d_func, nu_count = None) -> None:
        self.input_size = input_size
        self.output_size = output_size
        self.func = func
        self.d_func = d_func
        self.nu_count = nu_count

    def allocate(self, xy_offset, w_offset, prev_layer = None) -> None:
        if prev_layer is None:
            self.X = (xy_offset, xy_offset + self.input_size)
            xy_offset += self.input_size
        else:
            self.X = prev_layer.Y

        self.Y = (xy_offset, xy_offset + self.output_size)

        self.W = []
        for _ in range(0,ceil(self.output_size/self.nu_count)):
            self.W.append((w_offset, w_offset + self.input_size))
            w_offset += self.input_size

        return xy_offset + self.output_size, w_offset



    def forward_propagate(self):
        y_offset = self.Y[0]
        length = [self.nu_count]*(self.output_size//self.nu_count) + [self.output_size%self.nu_count]
        
        range(0,ceil(self.output_size/4))
        for subrange, l in zip(self.W, length):
            for x_offset, w_offset in zip(range(*self.X), range(*subrange)):
                print(f'MATMUL {x_offset},{w_offset}')

            for _ in range(self.nu_count-self.input_size):
                print('NOP')
            print(f'ACCMOV {y_offset},{l},{self.func},0,1,0,0')
            y_offset += self.nu_count

        return
        self.X = X
        self.V = np.dot(self.W, self.X)
        self.Y = self.func(self.V)
        return self.Y

    def backward_propagation(self, dE_dY, learning_rate):
        raise NotImplementedError()

        dE_dV = dE_dY*self.d_func(self.V)
        dE_dW = np.dot(self.X, dE_dV.T).T
        dE_dX = np.dot(self.W.T, dE_dV)

        self.W -= learning_rate * dE_dW

        return dE_dX