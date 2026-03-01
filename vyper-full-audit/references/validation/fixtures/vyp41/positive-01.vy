#pragma version 0.4.1

@external
@raw_return
def quote(amount: uint256) -> Bytes[32]:
    # Raw return on user-facing endpoint without integration guardrails.
    return concat(convert(amount, bytes32))
