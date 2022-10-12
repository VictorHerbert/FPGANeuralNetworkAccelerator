from math import ceil

from ..activation_function import linear

class Layer:

    XY_ONE_ADDR = 1

    def __init__(self, x_size, y_size, func = linear, has_bias = False) -> None:
        self.x_size = x_size
        self.y_size = y_size

        self.func = func
        self.has_bias = has_bias
        self.is_output = False


    def allocate(self, xy_offset, w_offset, prev_layer = None) -> None:
        if prev_layer is None:
            self.X = xy_offset
            xy_offset += self.x_size
        else:
            self.X = prev_layer.Y

        self.Y = xy_offset

        self.W = []
        self.B = []
        for _ in range(0,ceil(self.y_size/self.nu_count)):
            self.W.append(w_offset)
            w_offset += self.x_size

            if self.has_bias:
                self.B.append(w_offset)
                w_offset += 1

        xy_offset += self.y_size

        return xy_offset, w_offset