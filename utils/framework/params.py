def check_limits(limits, *args):
    if len(args) != len(limits) : raise ValueError('Invalid argument count')

    for arg,i in zip(args,limits):
        if arg > 2**i : raise ValueError(f'Argument wrong size')


def format_nop(*args):
    return 0

def format_matmul(*args):
    check_limits([12,12], *args)

    return (1 << 28)|(args[0] << 16)|(args[1] << 4)

def format_accmov(*args):
    check_limits([12,12,1,1,1,1,1], *args)

    return (2 << 28)|(args[0] << 16)|(args[1] << 13)|(args[2] << 9)|(args[3] << 8)|(args[4] << 7)|(args[5] << 6)|(args[5] << 6)

def format_loadmac(*args):
    check_limits([12,3], *args)

    return (3 << 28)|(args[0] << 16)|(args[1] << 13)

def format_matmult(*args):
    check_limits([12], *args)

    return (4 << 28)|(args[0] << 16)

def format_vecttomat(*args):
    check_limits([12,12], *args)

    return (5 << 28)|(args[0] << 16)|(args[1] << 4)

def format_wconstprod(*args):
    check_limits([12,12], *args)

    return (6 << 28)|(args[0] << 16)|(args[1] << 4)

def format_wacc(*args):
    check_limits([12,12], *args)

    return (7 << 28)|(args[0] << 16)|(args[1] << 4)

def format_repeat(*args):
    check_limits([28], *args)

    return (10 << 28)|(args[0] << 0)

def format_jmp(*args):
    check_limits([28], *args)

    return (11 << 28)|(args[0] << 0)

instructions = {
    'NOP' : format_nop,
    'MATMUL' : format_matmul,
    'ACCMOV' : format_accmov,
    'LOADMAC' : format_loadmac,
    'MATMULT' : format_matmult,
    'VECTTOMAT' : format_vecttomat,
    'WCONSTPROD' : format_wconstprod,
    'WACC' : format_wacc,
    'REPEAT' : format_repeat,
    'JMP' : format_jmp
}