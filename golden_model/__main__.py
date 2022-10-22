import numpy as np

from .neural_processor.fixed_point import to_fx_signed

from .neural_processor.activation_function import sigmoid, tanh, linear, relu
from .neural_processor.neural_processor import NeuralProcessor
from .neural_processor.memory_interface import MemoryInterface

from .neural_network.neural_network import NeuralNetwork
from .neural_network.layer import Layer as NNLayer

import random
from itertools import pairwise



IT_COUNT = 100

def test(v, file, verbose = False):
    nn = NeuralNetwork(layers = [NNLayer(x, y, random.choice([sigmoid, tanh, linear, relu])) for x,y in pairwise(v)])
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

    x = np.random.uniform(low=-1, high=1, size=(nn.layers[0].x_size, 1))

    mi = MemoryInterface(processor=nproc, neural_network=nn)
    mi.compile_inst_mem()
    mi.compile_act_mem()
    mi.xy_write(x, nproc.layers[0].X)

    print(len(mi.memory_map()), file=file)
    for addr, value in mi.memory_map().items():
        print(addr, value, file=file)

    y = nn.predict(x)

    print(nproc.layers[-1].y_size, file=file)
    for n, i in zip(y, range(nproc.layers[-1].Y, nproc.layers[-1].Y + nproc.layers[-1].y_size)):
        print(i, to_fx_signed(n[0], nproc.q), file=file)
    
    print('', file=f)

    return y

for it_number in range(IT_COUNT):    
    with open(f'src/testbench/vectors/case{it_number}.txt', 'w') as f:
            
        v = random.choices(range(1,7),[4,1,1,1,1,1], k=random.randint(2,5))
        y = test(v, f)
        
        print(v, file = f)
        print(y, file = f)
    
    