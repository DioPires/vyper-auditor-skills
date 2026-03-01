#pragma version 0.4.1

child: public(address)

@external
def deploy_checked(code: Bytes[1024]):
    deployed: address = raw_create(code, value=0, revert_on_failure=True)
    assert deployed != empty(address)
    self.child = deployed
