import numpy as np
from itertools import pairwise

from .activation_function import ActivationFunction


class NeuralProcessor:

    builtin_activation_functions = {
        'id' : ActivationFunction(mask = 1 << 2, fx = lambda x: x), 
        'step' : ActivationFunction(mask = 2 << 2, fx = lambda x: 1 if x >= 0 else 0),
        'relu' : ActivationFunction(mask = 3 << 2, fx = lambda x: x if x >= 0 else 0)
    }    

    def __init__(self,
        layers : int,
        nu_count : int,
        xy_mem_len : int,
        w_mem_len : int,

        q : tuple,
        act_func_mask_len : int,
        act_func_depth : int,
        act_func_a_q : int,
        act_func_b_q : int,

        activation_functions : int = None
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

        for func in ['id', 'step', 'relu']:
            if func in self.activation_functions:
                raise ValueError(f'Activaction function "{func}" already defined in hardware')

        for i, func in enumerate(self.activation_functions.values()):
            func.mask = i

        for layer in layers:
            layer.nu_count = self.nu_count      
            
            layer.func_mask = NeuralProcessor.builtin_activation_functions[layer.func_name].mask \
                if layer.func_name in NeuralProcessor.builtin_activation_functions \
                else self.activation_functions[layer.func_name].mask
          

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