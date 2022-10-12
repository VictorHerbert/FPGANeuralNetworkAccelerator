import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from scipy import rand

from software.neural_processor.fixed_point import fx_to_float

from .neural_processor.layer import Layer
from .activation_function import sigmoid, tanh, linear, relu
from .neural_processor.neural_processor import NeuralProcessor
from .neural_processor.memory_interface import MemoryInterface, list_to_mem

from .neural_network.neural_network import NeuralNetwork
from .neural_network.layer import Layer as NNLayer

import os 
import re
import random
from itertools import pairwise

from termcolor import colored 

#np.random.seed(5641)

EPS = .1
IT_COUNT = 1000

def test():
    
    v = random.choices(range(1,7),[4,1,1,1,1,1], k=random.randint(2,5))
    #v = [3,2,4]
    print('input:', v)

    nn = NeuralNetwork(layers = [NNLayer(x, y, random.choice([linear, sigmoid, tanh, relu])) for x,y in pairwise(v)])
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
    mi.xy_write(x, nproc.layers[0].X)

    mi.save_inst_mem('src/memories/inst.mem')
    mi.save_xy_mem('src/memories/xy.mem')
    mi.save_w_mem([f'src/memories/w{i}.mem' for i in range(4)])
    mi.save_act_mem('src/memories/act_func.mem')

    y = nn.predict(x)

    mi.output_write(y, nproc.layers[-1].Y%2**11)


    os.system('cd src/simulation && vsim -c -do run_auto.do > null')
    #os.system('cd src/simulation && vsim -c -do run_auto.do')

    s = open('src/memories/output.mem', 'r').read()
        
    output_mem = {int(entry[0]) : int(entry[1]) for entry in re.findall('(\d+): *(-*\d+)', s)}
    assert mi.output_mem.keys() == output_mem.keys()
    
    errors = np.array([fx_to_float(mi.output_mem[key], (4,12)) - fx_to_float(output_mem[key], (4,12)) for key in mi.output_mem.keys()])
    mse = np.square(errors).mean()

    print('prediction:', y.T)
    print('mse:', mse)
    print('verdict:', colored('PASSED', color='green') if mse < EPS else colored('FAILED', color='red'))
    print()

    return mse



for it_number in range(IT_COUNT):
    print(colored(f'Test number {it_number}', color='blue', attrs=['bold']))
    assert test() < EPS, f'Test {it_number} failed'