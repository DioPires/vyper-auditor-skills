#pragma version 0.4.1

interface Router:
    def quote() -> uint256: view

router: public(address)

@external
def set_router(new_router: address):
    self.router = new_router

@external
@view
def quote() -> uint256:
    # Mutable target + check bypass.
    return staticcall Router(self.router, skip_contract_check=True).quote()
