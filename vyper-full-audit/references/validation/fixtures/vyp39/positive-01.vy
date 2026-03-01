#pragma version 0.4.1

@external
def deploy_unchecked(code: Bytes[1024]):
    # Failure path ignored.
    new_addr: address = raw_create(code, value=0, revert_on_failure=False)
    self.last_deployed = new_addr

last_deployed: public(address)
