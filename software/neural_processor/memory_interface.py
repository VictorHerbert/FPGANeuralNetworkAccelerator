import numpy as np
from itertools import chain

from software.neural_network.neural_network import NeuralNetwork

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

    INST_HALT = 2
    INST_JUMP = 3

    XY_ZERO_ADDR = 0
    XY_ONE_ADDR = 1

    def __init__(self, processor: NeuralProcessor, neural_network: NeuralNetwork = None) -> None:
        self.processor = processor
        self.xy_mem = {}
        self.output_mem = {}
        self.w_mem = [{} for _ in range(processor.nu_count)]

        self.xy_mem[MemoryInterface.XY_ZERO_ADDR] = 0
        self.xy_mem[MemoryInterface.XY_ONE_ADDR] = to_fx(1, processor.q)

        if neural_network:
            for i, _ in enumerate(neural_network.layers):
                self.w_write(neural_network.layers[i].W, processor.layers[i].W[0])
    
    def save_inst_mem(self, filename: str) -> None:
        layer_inst = [(0<<63)|(l.X<<52)|(l.W[0]<<40)|((1 if l.is_output else 0)<<39)|(l.Y<<28)|((l.x_size)<<16)|((l.y_size)<<4)|(l.func.mask) for l in self.processor.layers]
        layer_inst += [1<<63|MemoryInterface.INST_HALT<<60]
        list_to_mem(layer_inst, filename)

    def save_xy_mem(self, filename : str) -> None:
        dict_to_mem(self.xy_mem, filename)
    
    def save_w_mem(self, filellist: list[str]) -> None:
        for mem, w_path in zip(self.w_mem, filellist):
            dict_to_mem(mem, w_path)

    def save_act_mem(self, filename: str) -> list[str]:
        func_mem = []
        for func in self.processor.activation_functions:
            func_mem += func.interpolate(self.processor.q, self.processor.act_func_a_q, self.processor.act_func_b_q, self.processor.act_func_depth)

        list_to_mem(func_mem, filename)

    def xy_write(self, array : np.array, offset : int):
        for i in range(array.shape[0]):
            self.xy_mem[offset+i] = to_fx(array[i,0], self.processor.q)

    
    def output_write(self, array : np.array, offset : int):
        for i in range(array.shape[0]):
            self.output_mem[offset+i] = to_fx(array[i,0], self.processor.q)

    def w_write(self, array: np.array, offset : int):
        for i in range(array.shape[0]):
            for j in range(array.shape[1]):
                self.w_mem[i%self.processor.nu_count][j+offset+(i//self.processor.nu_count)*array.shape[1]] = to_fx(array[i,j], self.processor.q)