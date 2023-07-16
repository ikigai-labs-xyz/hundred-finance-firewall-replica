# Hundred Finance Firewall Hack Replication

## Running the hack

1. Move to `modified-hundred-finance` and rn `forge compile` to compile the modified Hundred Finance Contracts (including the Firewall).
   This will automatically compile the contracts and place them in the artifacts folder of the `hack-replication` repository.

2. Move to `hack-replication` and run `forge test -vvv` to run the actual tests.
   These tests will now use the modified, firewall-guarded, Hundred Finance contracts form the `modified-hundred-finance` folder.
