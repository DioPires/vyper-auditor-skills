#pragma version 0.4.1

paused: public(bool)

@external
def disable():
    self.paused = True
