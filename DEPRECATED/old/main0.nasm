main:
    NOP
layer1:
    LOADMAC 1,0
    LOADMAC 2,1
    LOADMAC 3,2
    LOADMAC 4,3
    MATMUL 1,1,0
    MATMUL 1,1,0
    MATMUL 1,1,0
    MATMUL 1,1,0
    MATMUL 1,1,0
    ACCMOV 4,3,0,1,1,0,0
layer2:
    MATMUL 1,1,0
    MATMUL 2,2,0
    MATMUL 3,3,0
    MATMUL 4,4,1
    ACCMOV 8,3,0,1,1,0,0
    MATMUL 1,1,0
    MATMUL 1,1,0
    MATMUL 1,1,0
    MATMUL 1,1,0
    MATMUL 1,1,0
    MATMUL 1,1,0
    ACCMOV 8,4,0,1,1,0,0
    NOP
    NOP
    NOP
    NOP
    LOADMAC 1,2    