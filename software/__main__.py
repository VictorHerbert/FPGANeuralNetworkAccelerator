import numpy as np

from .neural_processor.layer import Layer
from .neural_processor.activation_function import sigmoid, tanh
from .neural_processor.neural_processor import NeuralProcessor
from .neural_processor.memory_interface import MemoryInterface, list_to_mem

from .compiler.compiler import compile

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
        Layer(4, 3, func_name='id'),
        Layer(3, 6, func_name='sig'),
        Layer(6, 6, func_name='tanh'),
        Layer(6, 2, func_name='sig'),
    ],
    activation_functions={
        'sig': sigmoid,
        'tanh': tanh
    }
)

binary = compile(nn.predict())
if binary:
    list_to_mem(binary, 'src/memories/inst.mem')


x = np.array([0,1,2,3], ndmin=2).T
w = [np.random.rand(layer.x_size, layer.y_size).T for layer in nn.layers]

mi = MemoryInterface(nn)
mi.xy_input_write(x)
for i, _ in enumerate(w):
    mi.w_write(w[i], nn.layers[i].W[0])

mi.save_xy_mem('src/memories/xy.mem')
mi.save_w_mem([f'src/memories/w{i}.mem' for i in range(4)])
mi.save_act_mem('src/memories/act_func.mem')

def forward():
    global w, x
    for w, layer in zip(w, nn.layers):
        if layer.has_bias:
            x = np.append(x,np.array([1], ndmin=2), axis=0)
            
        v = np.dot(w, x)

        x = NeuralProcessor.builtin_activation_functions[layer.func_name].fx(v) \
            if layer.func_name in NeuralProcessor.builtin_activation_functions \
            else nn.activation_functions[layer.func_name].fx(v)
        

        print('v:',v)
        print()
        print('x:', x)
        print()

forward()