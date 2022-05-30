import numpy as np
from itertools import pairwise

from software.neural_processor.layer import Layer
from software.neural_network.neural_network import NeuralNetwork
from software.activation_function import ActivationFunction, linear, step, relu


class NeuralProcessor:

    builtin_activation_functions = {
        linear, step, relu
    }

    def __init__(self,
        nu_count : int,
        xy_mem_len : int,
        w_mem_len : int,

        q : tuple,
        act_func_mask_len : int,
        act_func_depth : int,
        act_func_a_q : int,
        act_func_b_q : int,

        layers : int = None,
        neural_network : NeuralNetwork = None
    ) -> None:

        if (layers is None) & (neural_network is None):
            raise ValueError('Layers or NeuralNetwork model must be provided')

        self.layers = layers

        if neural_network:
            self.layers = [Layer(
                layer.x_size,
                layer.y_size,
                layer.func
            ) for layer in neural_network.layers]
            
        for l_prev, l_next in pairwise(self.layers):                        
            if l_prev.y_size != l_next.x_size:
                raise ValueError('Layers input and output between consecutive layers must be matched')
        
        self.activation_functions = {
            layer.func for layer in self.layers
            if not layer.func in NeuralProcessor.builtin_activation_functions}

        if len(self.activation_functions) > 2**act_func_mask_len:
            raise ValueError(f'There should be at most {2**act_func_mask_len} activation functions')

        self.nu_count = nu_count
        self.xy_mem_len = xy_mem_len
        self.w_mem_len = w_mem_len

        self.q = q
        self.act_func_depth = act_func_depth
        self.act_func_a_q = act_func_a_q
        self.act_func_b_q = act_func_b_q

        for i, func in enumerate(self.activation_functions):
            func.mask = i

        for layer in self.layers:
            layer.nu_count = self.nu_count            

        self.allocate()

    def allocate(self) -> None:   
        xy_offset, w_offset = self.layers[0].allocate(2, 0)

        for l_prev, l_next in pairwise(self.layers):                        
            xy_offset, w_offset = l_next.allocate(xy_offset, w_offset, prev_layer=l_prev)
    

    def predict(self):
        return '\n'.join(
            ('\n'.join(layer.forward_propagate()) for layer in self.layers))

    def fit(self,
        x_train : np.array,
        y_train : np.array,
        epochs : int = 100,
        learning_rate : float = 0.1,
        verbose : bool = False
    ):
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