import numpy as np

from utils import list_to_mem
from activation_function import ActivationFunction, sigmoid, tanh
from neural_processor import NeuralProcessor
from layer import Layer
from compiler import compile
import random
from itertools import pairwise

x = np.array([0,1,2,3], ndmin=2).T
w1 = np.array([x/4 for x in list(range(-6,6))]).reshape(4,3).T
w2 = np.array([x/4 for x in list(range(-9,9))]).reshape(3,6).T
w3 = np.array([x/8 for x in list(range(-18,18))]).reshape(6,6).T
w4 = np.array([x/4 for x in list(range(-6,6))]).reshape(6,2).T


nn = NeuralProcessor(
    nu_count=4,
    xy_mem_len=32,
    w_mem_len=32,   
    q = (4,12),
    act_func_depth = 6,
    act_func_mask_len=2,
    act_func_a_q=(4,12),
    act_func_b_q=(4,12),
    layers = [
        Layer(4, 3, func_name='sig', w_np=np.random.rand(3,4)),
        Layer(3, 6, func_name='sig', w_np=np.random.rand(6,3)),
        Layer(6, 6, func_name='tanh', w_np=np.random.rand(6,6)),
        Layer(6, 2, func_name='sig', w_np=np.random.rand(2,6)),
    ],
    activation_functions={
        'sig': sigmoid,
        'tanh': tanh,
        'sin': ActivationFunction(fx=lambda x: .3*np.sin(x)),
    }
)


with open('src\instructions\main.nasm', 'w') as f:
    binary = compile(nn.predict())
    if binary:
        list_to_mem(binary, 'src/memories/inst.mem')

for i, mem in enumerate(nn.get_w_mem()):
    list_to_mem(mem, f'src/memories/w{i}.mem')

list_to_mem(nn.get_act_func_mem(),'src/memories/act_func.mem')

for layer in nn.layers:
    x = nn.activation_functions[layer.func_name].fx(np.dot(layer.w_np,x))

print(x)
