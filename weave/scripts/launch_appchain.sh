#!/bin/bash
set -e

# This script is for demonstration purposes and assumes a simplified configuration.
# A production-ready script would have more robust error handling and parameter validation.

# Parameters
L1_CHAIN_ID=$1
L1_RPC=$2
VM_TYPE=$3
CHAIN_ID=$4
GAS_DENOM=$5
MONIKER=$6
GENESIS_ACCOUNTS=$7
BINARY_PATH=$8
MINITIA_HOME=$9

# Generate system keys
OPERATOR_MNEMONIC=$($BINARY_PATH keys add operator --keyring-backend test --output json | jq -r .mnemonic)
BRIDGE_EXECUTOR_MNEMONIC=$($BINARY_PATH keys add bridge_executor --keyring-backend test --output json | jq -r .mnemonic)
OUTPUT_SUBMITTER_MNEMONIC=$($BINARY_PATH keys add output_submitter --keyring-backend test --output json | jq -r .mnemonic)
BATCH_SUBMITTER_MNEMONIC=$($BINARY_PATH keys add batch_submitter --keyring-backend test --output json | jq -r .mnemonic)
CHALLENGER_MNEMONIC=$($BINARY_PATH keys add challenger --keyring-backend test --output json | jq -r .mnemonic)

# Create the minitia.config.json file
cat > minitia.config.json <<EOF
{
  "l1_config": {
    "chain_id": "${L1_CHAIN_ID}",
    "rpc_url": "${L1_RPC}",
    "gas_prices": "0.015uinit"
  },
  "l2_config": {
    "chain_id": "${CHAIN_ID}",
    "denom": "${GAS_DENOM}",
    "moniker": "${MONIKER}"
  },
  "op_bridge": {
    "output_submission_interval": "1m",
    "output_finalization_period": "168h",
    "output_submission_start_height": 1,
    "batch_submission_target": "Initia",
    "enable_oracle": true
  },
  "system_keys": {
    "validator": {
      "mnemonic": "${OPERATOR_MNEMONIC}"
    },
    "bridge_executor": {
      "mnemonic": "${BRIDGE_EXECUTOR_MNEMONIC}"
    },
    "output_submitter": {
      "mnemonic": "${OUTPUT_SUBMITTER_MNEMONIC}"
    },
    "batch_submitter": {
      "mnemonic": "${BATCH_SUBMITTER_MNEMONIC}"
    },
    "challenger": {
      "mnemonic": "${CHALLENGER_MNEMONIC}"
    }
  },
  "genesis_accounts": ${GENESIS_ACCOUNTS}
}
EOF

# Launch the appchain
weave init --with-config minitia.config.json --home ${MINITIA_HOME}