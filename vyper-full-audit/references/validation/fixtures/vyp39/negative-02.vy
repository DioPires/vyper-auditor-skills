#pragma version 0.4.1

impl: immutable(address)

@deploy
def __init__(target: address):
    assert target != empty(address)
    impl = target

@external
def spawn():
    deployed: address = create_minimal_proxy_to(impl)
    assert deployed != empty(address)
    assert deployed.codehash != empty(bytes32)
