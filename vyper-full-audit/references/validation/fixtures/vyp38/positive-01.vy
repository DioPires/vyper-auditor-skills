#pragma version 0.4.1

interface PriceFeed:
    def latest() -> uint256: view

@external
@view
def read_price(feed: address) -> uint256:
    # User-supplied feed + check bypass.
    return staticcall PriceFeed(feed, skip_contract_check=True).latest()
