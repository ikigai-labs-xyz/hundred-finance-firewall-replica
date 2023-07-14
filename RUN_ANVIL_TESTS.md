# Run tests on anvil

## Start local node

`anvil --chain-id 10 --fork-block-number 90760765 --fork-url optimism`

## Run tests

`forge test --mc HundredFinanceHackReplicator -vvvv --fork-url localhost:8545`
