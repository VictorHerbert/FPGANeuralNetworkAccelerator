import numpy as np
import pandas as pd
from matplotlib import pyplot as plt

from .neural_processor.layer import Layer
from .activation_function import sigmoid, tanh, linear, relu
from .neural_processor.neural_processor import NeuralProcessor
from .neural_processor.memory_interface import MemoryInterface, list_to_mem

from .compiler.compiler import compile

from .neural_network.neural_network import NeuralNetwork
from .neural_network.layer import Layer as NNLayer


nn = NeuralNetwork(layers = [
    NNLayer(4, 6, relu),
    NNLayer(6, 6, sigmoid),
    NNLayer(6, 3, sigmoid)
])
nn.compile()

nproc = NeuralProcessor(
    nu_count=4,
    xy_mem_len=32,
    w_mem_len=32,   
    q = (4,12),
    act_func_depth = 6,
    act_func_mask_len=2,
    act_func_a_q=(4,12),
    act_func_b_q=(4,12),
    neural_network=nn
)

binary = compile('NOP\n'*4 + 'FLUSH\n' + nproc.predict() + '\nNOP'*4)
if binary:
    list_to_mem(binary, 'src/memories/inst.mem')

x = np.array([.125,1,0,.488], ndmin=2).T

mi = MemoryInterface(processor=nproc, neural_network=nn)
mi.xy_input_write(x)

mi.save_xy_mem('src/memories/xy.mem')
mi.save_w_mem([f'src/memories/w{i}.mem' for i in range(4)])
mi.save_act_mem('src/memories/act_func.mem')


y = nn.predict(x)

pass
