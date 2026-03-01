#pragma version 0.4.1

@external
@raw_return
def read(flag: bool) -> Bytes[32]:
    if flag:
        return concat(convert(1, bytes32))
    return b""
