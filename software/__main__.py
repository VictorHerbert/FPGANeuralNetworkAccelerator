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


df = pd.read_csv('software/example/iris.csv')
df = pd.get_dummies(df)

x = df[['sepal_length','sepal_width','petal_length','petal_width']].to_numpy().T
y = df[['species_setosa','species_versicolor','species_virginica']].to_numpy().T

mse = nn.fit(x,y, epochs=5000, learning_rate=0.01, verbose=True)
print('NN trained with mse =', mse[-1])

p = pd.DataFrame(nn.predict(x).T, columns=['p_species_setosa','p_species_versicolor','p_species_virginica'])
p = pd.concat([df,p], axis=1)

plt.plot(mse)
plt.show()

'''

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

binary = compile(nproc.predict())
if binary:
    list_to_mem(binary, 'src/memories/inst.mem')


mi = MemoryInterface(processor=nproc, neural_network=nn)
#mi.xy_input_write(x)

mi.save_xy_mem('src/memories/xy.mem')
#mi.save_w_mem([f'src/memories/w{i}.mem' for i in range(4)])
mi.save_act_mem('src/memories/act_func.mem')


plt.plot(mse)
plt.show()

pass
'''