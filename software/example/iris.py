import numpy as np
from matplotlib import pyplot as plt
import pandas as pd

from network import Network
from layer import Layer

plt.rcParams['figure.figsize'] = [10, 6]


df = pd.read_csv('iris.csv')
df = pd.get_dummies(df)

x = df[['sepal_length','sepal_width','petal_length','petal_width']].to_numpy().T
y = df[['species_setosa','species_versicolor','species_virginica']].to_numpy().T

identity = lambda x: x
d_identity = lambda x: 1

sigmoid = lambda x: 1/(1+np.exp(-x))
d_sigmoid = lambda x: sigmoid(x)*(1-sigmoid(x))

nn =  Network(layers = [
    Layer(4, 6,  sigmoid, d_sigmoid),
    Layer(6, 6, sigmoid, d_sigmoid),
    Layer(6, 3, identity, d_identity)
])

nn.compile()

for lr in [0.1,0.01]:
    nn.compile()
    mse = nn.fit(x,y, epochs=600, learning_rate=0.01)
    plt.plot(mse, label = str(lr))

plt.show()

pd.DataFrame(nn.predict(x).T)


