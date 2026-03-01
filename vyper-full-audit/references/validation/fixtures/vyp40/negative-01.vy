#pragma version 0.4.1

IMPLEMENTATION: immutable(address)

@deploy
def __init__(impl: address):
    assert impl != empty(address)
    IMPLEMENTATION = impl

@external
def spawn() -> address:
    out: address = create_copy_of(IMPLEMENTATION)
    assert out != empty(address)
    return out
