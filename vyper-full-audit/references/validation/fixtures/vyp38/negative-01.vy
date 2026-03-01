#pragma version 0.4.1

interface SafeFeed:
    def latest() -> uint256: view

FEED: immutable(address)

@deploy
def __init__(feed: address):
    assert feed != empty(address)
    FEED = feed

@external
@view
def latest() -> uint256:
    return staticcall SafeFeed(FEED).latest()
