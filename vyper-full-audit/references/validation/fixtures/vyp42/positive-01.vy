#pragma version 0.4.1

owner: public(address)

@external
def kill(recipient: address):
    assert msg.sender == self.owner
    # Relies on selfdestruct to disable all future interactions.
    selfdestruct(recipient)
