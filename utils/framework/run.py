import numpy as np

from network import Network
from layer import Layer

x = np.array([1,2,3,4],ndmin=2).T

nn = Network(
    nu_count=4,
    xy_mem_len=32,
    w_mem_len=32,
    layers = [
        Layer(4, 3, func=0, d_func=1),
        Layer(3, 6, func=0, d_func=1),
        Layer(6, 2, func=0, d_func=1),
    ]
)
nn.allocate()

print('x:', [l.X for l in nn.layers])
print('y:', [l.Y for l in nn.layers])
print('w:', [l.W for l in nn.layers])

nn.predict()

pass