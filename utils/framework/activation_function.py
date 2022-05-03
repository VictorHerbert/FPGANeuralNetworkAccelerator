import numpy as np

from utils import to_fx_signed

class ActivationFunction:

    def __init__(self, fx) -> None:
        self.fx = fx

    def interpolate(self, q_int, a_q, b_q, depth):
        a_len = a_q[1] + a_q[0]
        b_len = b_q[1] + b_q[0]

        limits = (-2**(q_int-1), 2**(q_int-1))
        length = 2**depth
        step = 2*limits[1]/length

        x = np.arange(*limits, step=step)

        a = (self.fx(x+step)-self.fx(x))/step
        b = self.fx(x)-a*x

        a = np.clip(a, -2**(a_q[0]-1), 2**(a_q[0]-1)-2**(-a_q[1]))
        b = np.clip(b, -2**(b_q[0]-1), 2**(b_q[0]-1)-2**(-b_q[1]))
      
        v = [to_fx_signed(a, a_q[0], a_q[1])*2**b_len + to_fx_signed(b, b_q[0], b_q[1]) for a,b in zip(a, b)]
        v = list(v[2**(depth-1):2**depth]) + list(v[0:2**(depth-1)])

        return v

sigmoid = ActivationFunction(fx=lambda x: 1/(1+np.exp(-x)))
tanh = ActivationFunction(fx=lambda x: 2/(1+np.exp(-2*x))-1)

