#pragma version 0.4.1

# Low-level endpoint with explicit integration requirement.
# Companion property tests validate ABI compatibility with all callers.
@external
@raw_return
def low_level(data: Bytes[32]) -> Bytes[32]:
    assert len(data) == 32
    return data
