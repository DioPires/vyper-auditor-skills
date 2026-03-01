#pragma version 0.4.1

interface PrecompileIdentity:
    def identity(data: Bytes[32]) -> Bytes[32]: view

IDENTITY: constant(address) = 0x0000000000000000000000000000000000000004

@external
@view
def echo(data: Bytes[32]) -> Bytes[32]:
    out: Bytes[32] = staticcall PrecompileIdentity(IDENTITY, skip_contract_check=True).identity(data)
    assert len(out) == len(data)
    return out
