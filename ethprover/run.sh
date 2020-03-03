#!/usr/bin/env bash

# Exit script as soon as a command fails.
set -o errexit

./build.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
NODE_URL="https://rpc.nearprotocol.com"

# The master account ID to create accounts
NEAR_MASTER_ACCOUNT_ID="ethrelay"
# The account ID to push blocks
NEAR_CALLER_ACCOUNT_ID="ethprover-caller"
# The account ID used as ETH Prover
NEAR_ETHPROVER_ACCOUNT_ID="ethprover"
# The account ID used as ETH bridge
NEAR_ETHBRIDGE_ACCOUNT_ID="ethbridge"

echo "Creating account to call prover:"
NODE_ENV=local yarn run near --nodeUrl=$NODE_URL --homeDir "$DIR/.near" --keyPath "$DIR/.near/validator_key.json" create_account $NEAR_CALLER_ACCOUNT_ID --masterAccount=NEAR_MASTER_ACCOUNT_ID --initialBalance 100000000 || echo "Skip creating caller accout"
echo "Creating account for smart contract:"
NODE_ENV=local yarn run near --nodeUrl=$NODE_URL --homeDir "$DIR/.near" --keyPath "$DIR/.near/validator_key.json" create_account $NEAR_ETHPROVER_ACCOUNT_ID --masterAccount=NEAR_MASTER_ACCOUNT_ID --initialBalance 100000000 || echo "Skip creating ethprover accout"
echo "Deploying smart contract:"
NODE_ENV=local yarn run near --nodeUrl=$NODE_URL --homeDir "$DIR/.near" --keyPath "$DIR/.near/validator_key.json" deploy --contractName $NEAR_ETHPROVER_ACCOUNT_ID --wasmFile "$DIR/../../res/res/eth_prover.wasm" || echo "Skip deploying ethprover smart contract"

NEAR_BLOCK_NUMBER=9591235
NEAR_EXPECTED_BLOCK_HASH="0x4825597982da98143abc4720083439ebd2e698637a2edd7565a2e198b18f17cd"

echo "Good block"
# Launch EthProver call
NEAR_NODE_URL=$NODE_URL \
  NEAR_BLOCK_NUMBER=$NEAR_BLOCK_NUMBER \
  NEAR_EXPECTED_BLOCK_HASH=$NEAR_EXPECTED_BLOCK_HASH \
  NEAR_NODE_NETWORK_ID=default \
  NEAR_CALLER_ACCOUNT_ID=$NEAR_CALLER_ACCOUNT_ID \
  NEAR_ETHPROVER_ACCOUNT_ID=$NEAR_ETHPROVER_ACCOUNT_ID \
  NEAR_ETHBRIDGE_ACCOUNT_ID=$NEAR_ETHBRIDGE_ACCOUNT_ID \
  node "$DIR/index.js"

NEAR_BLOCK_NUMBER=9591234
NEAR_EXPECTED_BLOCK_HASH="0x4825597982da98143abc4720083439ebd2e698637a2edd7565a2e198b18f17cd"

echo "Bad block"
# Launch EthProver call
NEAR_NODE_URL=$NODE_URL \
  NEAR_BLOCK_NUMBER=$NEAR_BLOCK_NUMBER \
  NEAR_EXPECTED_BLOCK_HASH=$NEAR_EXPECTED_BLOCK_HASH \
  NEAR_NODE_NETWORK_ID=default \
  NEAR_CALLER_ACCOUNT_ID=$NEAR_CALLER_ACCOUNT_ID \
  NEAR_ETHPROVER_ACCOUNT_ID=$NEAR_ETHPROVER_ACCOUNT_ID \
  NEAR_ETHBRIDGE_ACCOUNT_ID=$NEAR_ETHBRIDGE_ACCOUNT_ID \
  node "$DIR/index.js"
