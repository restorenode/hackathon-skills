---
name: weave
description: 'Assists with managing Initia appchains (Interwoven Rollups) using the Weave CLI. This skill helps guide the user through the interactive setup process.'
---

# Weave Skill

This skill helps you scaffold and manage Initia appchains (Interwoven Rollups) by providing guidance on how to use the `weave` CLI.

## First-Time Setup: `weave init`

The most important step for any user is to run `weave init` interactively. This command will guide you through the entire setup process, including:

*   Installing necessary dependencies (`minitiad`, `jq`).
*   Setting up a Gas Station account.
*   Funding the Gas Station account.
*   Choosing the L1 network to connect to (e.g., `Testnet (initiation-2)`).
*   Launching your first rollup.

**As an AI assistant, you cannot run `weave init` for the user.** You must instruct the user to run this command in their terminal and follow the interactive prompts.

## Agent Instructions

When a user asks to "prepare the environment" or "launch an appchain" for the first time, your primary instruction should be:

**"Please run `weave init` in your terminal and follow the interactive prompts. This will guide you through the entire setup process."**

After the user has completed the interactive `weave init`, you can then assist them with other `weave` commands, such as:

*   `weave gas-station show`: To show the gas station address.
*   `weave rollup`: Manage your appchain. Subcommands: `launch`, `start`, `stop`, `restart`, `log`, `indexer`.
*   `weave initia`: Manage the Initia L1 node. Subcommands: `init`, `start`, `stop`, `restart`, `log`.
*   `weave opinit`: Manage OPinit bots (the glue between L1 and L2). Subcommands: `init`, `start`, `stop`, `restart`, `log`, `setup-keys`, `reset`.
*   `weave relayer`: Manage the IBC relayer between your rollup and L1. Subcommands: `init`, `start`, `stop`, `restart`, `log`.

## Rollup Interaction (`minitiad`)

While `weave` manages the infrastructure, you will use `minitiad` to interact with the rollup's ledger. As an AI assistant, use these patterns to help the user build their application.

### 1. Account Management
Users often need to check their addresses or create new ones for testing.
```bash
# Show the address of a key (e.g., 'operator' created during weave init)
minitiad keys show operator -a --keyring-backend test

# Create a new testing account
minitiad keys add alice --keyring-backend test
```

### 2. MiniMove Interaction
The core loop for Move developers.
```bash
# Build a Move module (run inside the project directory)
minitiad move build

# Publish a compiled module
minitiad tx move publish <path_to_mv_file> --from operator --chain-id <chain_id> --gas auto --gas-adjustment 1.2 -y

# Call an entry function
minitiad tx move run --module_address <addr> --module_name <name> --function_name <func> --args "<type>:<value>" --from operator --chain-id <chain_id> -y

# Query a view function
minitiad query move view --module_address <addr> --module_name <name> --function_name <func> --args "<type>:<value>"
```

### 3. MiniWasm Interaction
For developers building with CosmWasm (Rust).
```bash
# Store a Wasm code binary
minitiad tx wasm store <path_to_wasm_file> --from operator --chain-id <chain_id> --gas auto --gas-adjustment 1.2 -y

# Instantiate a contract
minitiad tx wasm instantiate <code_id> <init_msg_json> --label "my-contract" --from operator --chain-id <chain_id> --no-admin -y

# Execute a contract function
minitiad tx wasm execute <contract_addr> <exec_msg_json> --from operator --chain-id <chain_id> -y

# Query a contract
minitiad query wasm contract-state smart <contract_addr> <query_msg_json>
```

### 4. General Queries
```bash
# Check token balances
minitiad query bank balances $(minitiad keys show operator -a)

# Check transaction status
minitiad query tx <tx_hash>
```

## Core Commands

### verify_appchain

Verifies that an appchain is running correctly.

**Usage:**

```bash
# Set environment variables for your specific appchain
export CHAIN_ID="your-chain-id"
export RPC_URL="http://localhost:26657" # Default for local rollups

# Configure minitiad to talk to your appchain
minitiad config set client chain-id "$CHAIN_ID"
minitiad config set client node "$RPC_URL"

# Check if blocks are being produced
minitiad status | jq -r '.SyncInfo.latest_block_height'

# Check the balance of a genesis account
# (replace 'mykey' with the key name you chose during `weave init`)
minitiad query bank balances $(minitiad keys show mykey -a)
```