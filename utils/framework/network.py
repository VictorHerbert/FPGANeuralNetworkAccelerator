import numpy as np
from itertools import pairwise

mse = lambda y, yl: sum((yl-y)**2)/len(y)
d_mse = lambda y, yl: (2/len(y))*(y-yl)

class Network:

    def __init__(self, layers, nu_count, xy_mem_len, w_mem_len) -> None:
        # TODO check prev.output = next.input
        self.nu_count = nu_count
        self.layers = layers
        self.nu_count = nu_count
        self.xy_mem_len = xy_mem_len
        self.w_mem_len = w_mem_len

        for layer in layers:
            layer.nu_count = self.nu_count
        

    def allocate(self) -> None:   
        xy_offset, w_offset = self.layers[0].allocate(0, 0)

        for l_prev, l_next in pairwise(self.layers):                        
            xy_offset, w_offset = l_next.allocate(xy_offset, w_offset, prev_layer=l_prev)

    def predict(self):
        for layer in self.layers:
            layer.forward_propagate()


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
                for layer in reversed(self.layers[:-1]):
                    dE_dY = layer.backward_propagation(dE_dY, learning_rate)

            error /= len(x_train)
            if verbose == True:
                print(f'Epoch {epoch_index}  error={error}')

            error_list.append(error)
        return error_list



    def evaluate(self, x, y):
        return sum(self.loss(self.predict(x),y))/len(y)