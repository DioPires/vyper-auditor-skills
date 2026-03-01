#pragma version 0.4.1

blueprint: public(address)

@external
def deploy_clone(data: Bytes[128]):
    deployed: address = create_from_blueprint(self.blueprint, data)
    # Missing non-zero/code checks before trust.
    self.child = deployed

child: public(address)
