#pragma version 0.4.1

allowed: public(HashMap[address, bool])

@external
def allow(target: address):
    self.allowed[target] = True

@external
def clone_allowed(target: address) -> address:
    assert self.allowed[target]
    assert target.codehash != empty(bytes32)
    return create_copy_of(target)
