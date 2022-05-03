import numpy as np
from itertools import pairwise, chain

from utils import to_fx

class NeuralProcessor:

    def __init__(self,
        layers,
        nu_count,
        xy_mem_len,
        w_mem_len,
        q,
        act_func_mask_len,
        act_func_depth,
        act_func_a_q,
        act_func_b_q,
        activation_functions = None
    ) -> None:
        self.layers = layers
        self.activation_functions = activation_functions

        for l_prev, l_next in pairwise(self.layers):                        
            if l_prev.y_size != l_next.x_size:
                raise ValueError('Layers input and output between consecutive layers must be matched')
        
        if len(self.activation_functions) > 2**act_func_mask_len:
            raise ValueError(f'There should be at most {2**act_func_mask_len} activation functions')

        self.nu_count = nu_count
        self.xy_mem_len = xy_mem_len
        self.w_mem_len = w_mem_len

        self.q = q
        self.act_func_depth = act_func_depth
        self.act_func_a_q = act_func_a_q
        self.act_func_b_q = act_func_b_q

        self.xy_mem = [0]*self.xy_mem_len
        self.w_mem = [[0]*self.w_mem_len for _ in range(self.nu_count)]

        for i, func in enumerate(self.activation_functions.values()):
            func.mask = i

        for layer in layers:
            layer.nu_count = self.nu_count
            layer.func_mask = activation_functions[layer.func_name].mask if layer.func_name is not None else None
            layer.d_func_mask = activation_functions[layer.d_func_name].mask if layer.d_func_name is not None else None

        self.allocate()

    def allocate(self) -> None:   
        xy_offset, w_offset = self.layers[0].allocate(0, 0)

        for l_prev, l_next in pairwise(self.layers):                        
            xy_offset, w_offset = l_next.allocate(xy_offset, w_offset, prev_layer=l_prev)
    
    def numpy_to_xy_mem(self, array, offset):
        for i in range(array.shape[0]):
            self.xy_mem[offset+i] = int(array[i,0])        

    def numpy_to_w_mem(self, array, offset):
        for i in range(array.shape[0]):
            for j in range(array.shape[1]):
                self.w_mem[i%self.nu_count][j+offset+(i//self.nu_count)*array.shape[1]] = to_fx(array[i,j], *self.q)
        
    def get_act_func_mem(self) -> None:
        return list(chain(*(func.interpolate(self.q[0], self.act_func_a_q, self.act_func_b_q, self.act_func_depth) for func in self.activation_functions.values())))

    def get_w_mem(self) -> None:
        for layer in self.layers:
            if layer.w_np is None:
                raise ValueError('Layer weights not given')

            if layer.w_np.shape != (layer.y_size, layer.x_size):
                raise ValueError('Layer shape with wrong size')

            self.numpy_to_w_mem(layer.w_np, layer.W[0])

        return self.w_mem

    def predict(self):
        return '\n'.join(('\n'.join(layer.forward_propagate()) for layer in self.layers))
            


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