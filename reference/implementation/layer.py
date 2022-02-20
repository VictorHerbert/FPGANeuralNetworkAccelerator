import numpy as np

class Layer:

    def __init__(self, input_size, func, d_func) -> None:
        self.input_size = input_size
        self.output_size = -1
        self.func = func
        self.d_func = d_func

    def allocate(self) -> None:
        self.W = np.random.rand(self.output_size, self.input_size) - 0.5

    def forward_propagate(self, X):
        self.X = X
        self.V = np.dot(self.W, self.X)
        self.Y = self.func(self.V)
        return self.Y

    def backward_propagation(self, dE_dY, learning_rate):
        dE_dV = dE_dY*self.d_func(self.V)
        dE_dW = np.dot(self.X, dE_dV.T).T
        dE_dX = np.dot(self.W.T, dE_dV)

        self.W -= learning_rate * dE_dW

        return dE_dX