from typing import Callable, Tuple
import numpy as np

from .fixed_point import to_fx_signed

class ActivationFunction:

    def __init__(self, fx: Callable = None, mask: int = None) -> None:
        self.fx = fx
        self.mask = mask

    def interpolate(self, q : tuple, a_q : tuple, b_q : tuple, depth: int):
        a_len = a_q[1] + a_q[0]
        b_len = b_q[1] + b_q[0]

        limits = (-2**(q[0]-1), 2**(q[0]-1))
        length = 2**depth
        step = 2*limits[1]/length

        x = np.arange(*limits, step=step)

        a = (self.fx(x+step)-self.fx(x))/step
        b = self.fx(x)-a*x

        a = np.clip(a, -2**(a_q[0]-1), 2**(a_q[0]-1)-2**(-a_q[1]))
        b = np.clip(b, -2**(b_q[0]-1), 2**(b_q[0]-1)-2**(-b_q[1]))
      
        v = [to_fx_signed(a, a_q)*2**b_len + to_fx_signed(b, b_q) \
                for a,b in zip(a, b)]
        v = list(v[2**(depth-1):2**depth]) + list(v[0:2**(depth-1)])

        return v

sigmoid = ActivationFunction(fx=lambda x: 1/(1+np.exp(-x)))
tanh = ActivationFunction(fx=lambda x: 2/(1+np.exp(-2*x))-1)