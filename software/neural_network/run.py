import numpy as np
from matplotlib import pyplot as plt
import pandas as pd

from network import Network
from layer import Layer

plt.rcParams['figure.figsize'] = [10, 6]


identity = lambda x: x
d_identity = lambda x: 1

sigmoid = lambda x: 1/(1+np.exp(-x))
d_sigmoid = lambda x: sigmoid(x)*(1-sigmoid(x))

nn = Network(layers = [
    Layer(4, 6, identity, d_identity),
    Layer(6, 2, identity, d_identity),
])
nn.compile()


x = np.array([[1],[2],[3],[4]])
y = np.array([[60],[61]])

nn.predict(x)


for lr in [0.001,0.0001]:
    nn.compile()
    mse = nn.fit(x,y, epochs=100, learning_rate=lr)
    plt.plot(mse, label = str(lr))

plt.legend()
plt.show()