#pragma version 0.4.1

# No selfdestruct in production path.
@external
@view
def status() -> bool:
    return True
