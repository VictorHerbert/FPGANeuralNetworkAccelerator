def to_fx(x, q_int, q_frac):
    assert -2**(q_int-1) <= x <= 2**(q_int-1)-2**(-q_frac)
    return int(round(x*2**q_frac))
    

def to_fx_signed(x, q_int, q_frac):
    assert -2**(q_int-1) <= x <= 2**(q_int-1)-2**(-q_frac)
    if x >= 0:
        return int(round(x*2**q_frac))
    else:
        return int(round(x*2**q_frac+2**(q_frac+q_int)))


def list_to_mem(l, filename):
    with open(filename, 'w') as f:
        f.write('//format=mti addressradix=d dataradix=d version=1.0 wordsperline=1\n')
        for i, x in enumerate(l):
            f.write(f'{i}: {int(x)}\n')