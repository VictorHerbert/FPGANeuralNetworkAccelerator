main:
    NOP
layer1:
    MATMUL 0,0
    REPEAT 3
    ACCMOV 4,4,0,0,1,0,0
    MATMUL 0,4
    REPEAT 3
    ACCMOV 8,2,0,0,1,0,0
    MATMUL 4,8
    REPEAT 3
    ACCMOV 10,2,0,0,1,0,0
    MATMUL 1,0
    ACCMOV 4,4,0,0,1,0,0
    NOP
    REPEAT 3
    JMP 0