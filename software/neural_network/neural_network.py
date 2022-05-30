import numpy as np
from itertools import pairwise

mse = lambda y, yl: sum((yl-y)**2)/len(y)
d_mse = lambda y, yl: (2/len(y))*(y-yl)

class NeuralNetwork:

    def __init__(self, layers) -> None:
        self.layers = layers
        self.loss = mse
        self.d_loss = d_mse

    def compile(self) -> None:
        for layer in self.layers:
            layer.allocate()

    def predict(self, x):
        for layer in self.layers:
            x = layer.forward_propagate(x)

        return x

    def fit(self, x_train, y_train, epochs = 100, learning_rate = 0.1, verbose = False):
        error_list = []
        for epoch_index in range(epochs):
            error = 0
            for i in range(x_train.shape[1]):
                x = x_train[:,i].reshape((x_train.shape[0],1))
                y = y_train[:,i].reshape((y_train.shape[0],1))
                
                y_pred = self.predict(x)
                error += self.loss(y_pred, y)[0]

                dE_dY = self.d_loss(y_pred, y)
                for layer in reversed(self.layers):
                    dE_dY = layer.backward_propagation(dE_dY, learning_rate)

            error /= len(x_train)
            if (verbose == True) & (epoch_index%50 == 0):
                print(f'Epoch {epoch_index}  error={error}')

            error_list.append(error)
        return error_list

        

    def evaluate(self, x, y):
        return sum(self.loss(self.predict(x),y))/len(y)