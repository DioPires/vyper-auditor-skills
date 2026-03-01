#pragma version 0.4.1

@external
def emergency_exit(recipient: address):
    selfdestruct(recipient)
