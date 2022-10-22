from typing import Callable
import numpy as np

class Layer:

    def __init__(self, x_size : int, y_size : int, func : Callable[[np.array], np.array]) -> None:
        self.x_size = x_size
        self.y_size = y_size
        self.func = func

    def allocate(self) -> None:
        self.W = np.random.rand(self.y_size, self.x_size) - 0.5

    def forward_propagate(self, X : np.array) -> np.array:
        self.X = X
        self.V = np.dot(self.W, self.X)
        self.Y = self.func.fx(self.V)
        return self.Y

    def backward_propagation(self, dE_dY: np.array, learning_rate : float) -> np.array:
        dE_dV = dE_dY*self.func.dfx(self.V)
        dE_dW = np.dot(self.X, dE_dV.T).T
        dE_dX = np.dot(self.W.T, dE_dV)

        self.W -= learning_rate * dE_dW

        return dE_dX