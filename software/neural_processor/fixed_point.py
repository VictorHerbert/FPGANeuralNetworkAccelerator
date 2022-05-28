def to_fx(x, q : tuple[int]):
    q_int, q_frac = q
    assert -2**(q_int-1) <= x <= 2**(q_int-1)-2**(-q_frac)
    return int(round(x*2**q_frac))
    
def to_fx_signed(x, q : tuple[int]):
    q_int, q_frac = q
    assert -2**(q_int-1) <= x <= 2**(q_int-1)-2**(-q_frac)
    if x >= 0:
        return int(round(x*2**q_frac))
    else:
        return int(round(x*2**q_frac+2**(q_frac+q_int)))