#pragma version 0.4.1

implementation: public(address)

@external
def set_impl(new_impl: address):
    self.implementation = new_impl

@external
def spawn():
    # Mutable implementation without integrity checks.
    create_copy_of(self.implementation)
