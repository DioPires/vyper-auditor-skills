#pragma version ^0.4.0

stored: uint256

@external
def set_value(v: uint256):
    self.stored = v

@external
@view
def get_value() -> uint256:
    return self.stored
