from typing import Callable, List, Tuple
import numpy as np

from .fixed_point import to_fx_signed

class ActivationFunction:

    def __init__(self, fx: Callable = None, dfx: Callable = None, mask: int = None) -> None:
        self.fx = fx
        self.dfx = dfx
        self.mask = mask

    def interpolate(self, q : tuple, a_q : tuple, b_q : tuple, depth: int) -> List:
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


linear  = ActivationFunction(
    mask = 1 << 2,
    fx = lambda x: x,
    dfx = lambda x: 1)

step = ActivationFunction(
    mask = 2 << 2,
    fx = lambda x: 1 if x >= 0 else 0,
    dfx = lambda x: 0)

relu = ActivationFunction(
    mask = 3 << 2,
    fx = lambda x: x * (x >= 0),
    dfx = lambda x: 1 * (x >= 0))

sigmoid = ActivationFunction(
    fx = lambda x: 1/(1+np.exp(-x)),
    dfx = lambda x: 1/(1+np.exp(-x))*(1-1/(1+np.exp(-x))))

tanh = ActivationFunction(
    fx = lambda x: 2/(1+np.exp(-2*x))-1,
    dfx = lambda x: 1 - np.power(2/(1+np.exp(-2*x))-1,2))

