import numpy as np
from itertools import chain

from ..neural_network.neural_network import NeuralNetwork

from .fixed_point import to_fx, to_fx_signed
from .neural_processor import NeuralProcessor

def long_to_short_word(w: int):
    ''' Converts 64 bit int to tuple of 4 x 16 bit'''
    t = [0,0,0,0]
    for k in range(4):
        t[k] = w%(1<<16)
        w //= (1<<16)
    return t

def int_to_short_word(w: int):
    ''' Converts 64 bit int to tuple of 4 x 16 bit'''
    t = [0,0]
    for k in range(2):
        t[k] = w%(1<<16)
        w //= (1<<16)
    return t
            
class MemoryInterface:

    XY_OFFSET = 0x0000
    ACT_OFFSET = 0x2000
    W_OFFSET = [0x4000, 0x6000, 0x8000, 0xA000]
    INST_OFFSET = 0xE000
    

    def __init__(self, processor: NeuralProcessor, neural_network: NeuralNetwork = None) -> None:
        self.processor = processor
        self.xy_mem = {}
        self.w_mem = [{} for _ in range(processor.nu_count)]

        self.layer_inst = []
        self.act_mem = []
        self.memory = {}

        if neural_network:
            for i, _ in enumerate(neural_network.layers):
                self.w_write(neural_network.layers[i].W, processor.layers[i].W[0])
    
    def memory_map(self):       
        offsets = [
            (self.layer_inst, MemoryInterface.INST_OFFSET),
            (self.xy_mem, MemoryInterface.XY_OFFSET),
            *((self.w_mem[i], MemoryInterface.W_OFFSET[i]) for i in range(self.processor.nu_count)),
            (self.act_mem, MemoryInterface.ACT_OFFSET),
        ]

        for l, offset in offsets:
            for i, v in l.items():
                self.memory[offset+i] = v

        return self.memory

    
    def compile_inst_mem(self) -> None:        
        layer_inst_64 = [(0<<63)|(l.X<<52)|(l.W[0]<<40)|((1 if l.is_output else 0)<<39)|(l.Y<<28)|((l.x_size)<<16)|((l.y_size)<<4)|(l.func.mask) for l in self.processor.layers]
        layer_inst_64[-1] |= (1<<63)
        
        self.layer_inst = list(chain(*(long_to_short_word(l) for l in layer_inst_64)))
        self.layer_inst = {i: e for i,e in enumerate(self.layer_inst)}

    def compile_act_mem(self) -> list[str]:
        for func in self.processor.activation_functions:
            self.act_mem += func.interpolate(self.processor.q, self.processor.act_func_a_q, self.processor.act_func_b_q, self.processor.act_func_depth)

        self.act_mem = list(chain(*(int_to_short_word(l) for l in self.act_mem)))
        self.act_mem = {i: e for i,e in enumerate(self.act_mem)}

    def xy_write(self, array : np.array, offset : int):
        for i in range(array.shape[0]):
            self.xy_mem[offset+i] = to_fx_signed(array[i,0], self.processor.q)

    def w_write(self, array: np.array, offset : int):
        for i in range(array.shape[0]):
            for j in range(array.shape[1]):
                self.w_mem[i%self.processor.nu_count][j+offset+(i//self.processor.nu_count)*array.shape[1]] = to_fx_signed(array[i,j], self.processor.q)