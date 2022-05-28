from math import ceil

from .neural_processor import NeuralProcessor
from .memory_interface import MemoryInterface

class Layer:

    def __init__(self, x_size, y_size, func_name = 'id', has_bias = False) -> None:
        self.x_size = x_size
        self.y_size = y_size

        self.func_name = func_name

        self.has_bias = has_bias


    def allocate(self, xy_offset, w_offset, prev_layer = None) -> None:
        if prev_layer is None:
            self.X = xy_offset
            xy_offset += self.x_size
        else:
            self.X = prev_layer.Y

        self.Y = xy_offset

        self.W = []
        self.B = []
        for _ in range(0,ceil(self.y_size/self.nu_count)):
            self.W.append(w_offset)
            w_offset += self.x_size

            if self.has_bias:
                self.B.append(w_offset)
                w_offset += 1

        xy_offset += self.y_size

        return xy_offset, w_offset



    def forward_propagate(self):
        y_offset = self.Y
        length = [self.nu_count]*(self.y_size//self.nu_count) + [self.y_size%self.nu_count]

        instructions = []
        
        for w_offset, l in zip(self.W, length):
            b_offset = 0
            instructions.append(f'MATMUL {self.X},{w_offset}')
            instructions.append(f'REPEAT {self.x_size-1}')

            if self.has_bias:
                instructions.append(f'MATMUL {MemoryInterface.XY_ONE_ADDR},{w_offset+self.x_size}')

            # TODO identity func
            instructions.append(f'ACCMOV {y_offset},{l},{1 if self.func_mask is None else self.func_mask}')
            instructions.append(f'NOP')
            instructions.append(f'NOP')

            y_offset += self.nu_count

        return instructions