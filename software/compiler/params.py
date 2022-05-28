def check_limits(limits, *args):
    if len(args) != len(limits) : raise ValueError('Invalid argument count')

    for arg,i in zip(args,limits):
        if arg > 2**i : raise ValueError(f'Argument wrong size')


def format_nop(*args):
    check_limits([], *args)
    return 0

def format_matmul(*args):
    check_limits([12,12], *args)
    return (1 << 28)|(args[0] << 16)|(args[1] << 4)

def format_repeat(*args):
    check_limits([12], *args)
    return (2 << 28)|((args[0]-1) << 16)

def format_accmov(*args):
    check_limits([12,5,5], *args)
    return (3 << 28)|(args[0] << 16)|((args[1]-1) << 11)|(args[2] << 6)
    
def format_jmp(*args):
    check_limits([14], *args)
    return (14 << 28)|(args[0] << 14)

instructions = {
    'NOP' : format_nop,
    'MATMUL' : format_matmul,
    'ACCMOV' : format_accmov,
    'REPEAT' : format_repeat,
    'JMP' : format_jmp
}
