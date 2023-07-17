# Hundred Finance Firewall Hack Replication

## Running the hack

1. Move to `modified-hundred-finance` and rn `forge compile` to compile the modified Hundred Finance Contracts (including the Firewall).
   This will automatically compile the contracts and place them in the artifacts folder of the `hack-replication` repository.

2. Move to `hack-replication` and run `forge test -vvv` to run the actual tests.
   These tests will now use the modified, firewall-guarded, Hundred Finance contracts form the `modified-hundred-finance` folder.

## Run tests on anvil

### Start local node

`anvil --chain-id 10 --fork-block-number 90760765 --fork-url optimism`

### Run tests

`forge test --mc HundredFinanceHackReplicator -vvvv --fork-url localhost:8545`

### Run script

`forge script ./scripts/HundredFinance_Original.s.sol --tc HundredFinanceHackReplicator --rpc-url localhost`

## Gas coverage

`forge test --mc HundredFinanceHackReplicator --fork-url localhost:8545 --gas-report`
