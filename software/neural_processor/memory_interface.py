import numpy as np
from itertools import chain

from .fixed_point import to_fx
from .neural_processor import NeuralProcessor

def list_to_mem(l, filename):
    with open(filename, 'w') as f:
        f.write('//format=mti addressradix=d dataradix=d version=1.0 wordsperline=1\n')
        for i, x in enumerate(l):
            f.write(f'{i}: {int(x)}\n')

def dict_to_mem(d, filename):
    with open(filename, 'w') as f:
        f.write('//format=mti addressradix=d dataradix=d version=1.0 wordsperline=1\n')
        for i, x in d.items():
            f.write(f'{i}: {int(x)}\n')
            
class MemoryInterface:

    XY_ZERO_ADDR = 0
    XY_ONE_ADDR = 1

    def __init__(self, processor: NeuralProcessor) -> None:
        self.processor = processor
        self.xy_mem = {}
        self.w_mem = [{} for _ in range(processor.nu_count)]

        self.xy_mem[MemoryInterface.XY_ZERO_ADDR] = 0
        self.xy_mem[MemoryInterface.XY_ONE_ADDR] = to_fx(1, processor.q)
    
    def save_xy_mem(self, filename : str) -> None:
        dict_to_mem(self.xy_mem, filename)
    
    def save_w_mem(self, filellist: list[str]) -> None:
        for mem, w_path in zip(self.w_mem, filellist):
            dict_to_mem(mem, w_path)

    def save_act_mem(self, filename: str) -> list[str]:
        func_mem = []
        for func in self.processor.activation_functions.values():
            func_mem += func.interpolate(self.processor.q, self.processor.act_func_a_q, self.processor.act_func_b_q, self.processor.act_func_depth)

        list_to_mem(func_mem, filename)

    def xy_input_write(self, array : np.array):
        self.xy_write(array, self.processor.layers[0].X)

    def xy_write(self, array : np.array, offset : int):
        for i in range(array.shape[0]):
            self.xy_mem[offset+i] = to_fx(array[i,0], self.processor.q)

    def w_write(self, array: np.array, offset : int):
        for i in range(array.shape[0]):
            for j in range(array.shape[1]):
                self.w_mem[i%self.processor.nu_count][j+offset+(i//self.processor.nu_count)*array.shape[1]] = to_fx(array[i,j], self.processor.q)

    def get_w_mem(self) -> None:
        for layer in self.layers:
            if layer.w_np is None:
                raise ValueError('Layer weights not given')

            if layer.w_np.shape != (layer.y_size, layer.x_size):
                raise ValueError('Layer shape with wrong size')

            self.w_write(layer.w_np, layer.W[0])

        return self.w_mem