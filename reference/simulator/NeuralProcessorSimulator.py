import numpy as np

class NeuralProcessor:

    def __init__(self, nu_size, xy_mem_size, w_mem_size) -> None:
        self.nu_size = nu_size
        self.xy_mem_size = xy_mem_size
        self.w_mem_size = w_mem_size

        self.xy_mem = [0]*self.xy_mem_size
        self.w_mem = [[0]*self.w_mem_size for _ in range(self.nu_size)]
        self.acc = [0]*self.nu_size
        self.mac_reg = [0]*self.nu_size

        self.shift_reg = [0]*self.nu_size
        self.mux1_out = [0]*self.nu_size
        self.mux2_out = [0]*self.nu_size
        self.prod = [0]*self.nu_size
        self.sum = [0]*self.nu_size
        self.mac_reg = [0]*self.nu_size

        self.xy_mem[0] = 0
        self.xy_mem[1] = 1

    def numpy_to_xy_mem(self, a, offset):
        assert a.shape[0] <= self.nu_size

        for i in range(a.shape[0]):
            self.xy_mem[offset+i] = int(a[i,0])

    def numpy_to_w_mem(self, a, offset):
        assert a.shape[0] <= self.nu_size

        for i in range(a.shape[0]):
            for j in range(a.shape[1]):
                self.w_mem[i][j+offset] = int(a[i,j])

    def clock(
        self,
        mux1 = 0,
        mux2 = 0,
        xy_r_addr = 0,
        xy_w_addr = 0,
        xy_write_enable = 0,
        w_r_addr = 0,
        w_w_addr = 0,
        w_write_enable = 0,
        mac_reg_enable = None,
        acc_loopback = 0,
        shift_reg_enable = 0,
        act_func_select = 0,
        xy_acc_loopback = 0,
        act_func = lambda x: x
    ):
        if not mac_reg_enable:
            mac_reg_enable = [0]*self.nu_size

        for i in range(self.nu_size):
            self.mux1_out[i] = self.mac_reg[i] if mux1 else self.xy_mem[xy_r_addr]
            self.mux2_out[i] = self.xy_mem[xy_r_addr] if mux2 else self.w_mem[i][w_r_addr]

            self.prod[i] = self.mux1_out[i]*self.mux2_out[i]
            self.sum[i] = self.prod[i] + (self.acc[i] if acc_loopback else 0)

        self.sum_total = sum(self.prod)

        self.act_func_in = self.shift_reg[0] if act_func_select else self.sum_total
        self.act_func_out = act_func(self.act_func_in)

        # Registered signals
        # Grab values before update
        self.shift_reg = self.acc.copy() if shift_reg_enable else self.shift_reg[1:self.nu_size] + self.shift_reg[0:1]
        for i in range(self.nu_size):
            self.acc[i] = self.sum[i]

        self.xy_mem[xy_w_addr] = \
            self.act_func_out + (self.xy_mem[xy_w_addr] if xy_acc_loopback else 0) \
                if xy_write_enable else self.xy_mem[xy_w_addr]

        for i in range(self.nu_size):
            self.w_mem[i][w_w_addr] =  self.sum[i]\
                if w_write_enable else self.w_mem[i][w_w_addr]

        self.mac_reg = [self.xy_mem[xy_r_addr] if e else self.mac_reg[i]  for i,e in enumerate(mac_reg_enable)]


    def mat_mul(self, x_addr, w_addr, length):
        self.clock(
            mux1 = 0,
            mux2 = 0,
            xy_r_addr = x_addr,
            w_r_addr = w_addr,
            acc_loopback = 0
        )
        for i in range(1,length):
            self.clock(
                mux1 = 0,
                mux2 = 0,
                xy_r_addr = x_addr+i,
                w_r_addr = w_addr+i,
                acc_loopback = 1
            )
        self.clock(shift_reg_enable = 1)

    def acc_mov(self, y_addr, length):
        for i in range(length):
            self.clock(
                shift_reg_enable = 0,
                act_func_select = 1,
                xy_write_enable = 1,
                xy_w_addr = y_addr+i
            )

    def xy_to_mac_reg(self, x_addr):
        v = [1] + [0]*(self.nu_size-1)
        for i in range(self.nu_size):
            self.clock(
                mac_reg_enable = v,
                xy_r_addr = x_addr+i
            )
            v = v[-1:] + v[0:-1]

    def matmul_t(self, w_addr, y_addr, length, accumulate = False):
        for i in range(length):
            self.clock(
                mux1 = 1,
                mux2 = 0,
                w_r_addr = w_addr+i,
                xy_w_addr = y_addr+i,
                xy_write_enable = 1,
                act_func_select = 0,
                acc_loopback=accumulate
            )

    def vect_to_mat(self, x_addr, de_dv_addr, w_addr, length):
        raise NotImplementedError

    def mat_update(self, x_addr, w_addr, dw_addr, result_addr, length):
        for i in range(length):
            self.clock(
                mux1=0,
                mux2=0,
                acc_loopback = 0,
                xy_r_addr=x_addr,
                w_r_addr=w_addr+i
            )
            self.clock(
                mux1=0,
                mux2=0,
                acc_loopback = 1,
                xy_r_addr=1, # xy = 1
                w_r_addr=dw_addr+i,
                w_w_addr=result_addr+i,
                w_write_enable=1
            )

            pass