#pragma version 0.4.1

@external
def clone_any(target: address):
    # User-controlled source.
    clone: address = create_copy_of(target)
    self.last_clone = clone

last_clone: public(address)
