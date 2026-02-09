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

The Weave CLI workflow has two distinct phases:

1.  **Interactive Setup (Manual)**: `weave init` requires human input for faucets and security decisions. **You cannot run this command.** When a user needs to start or prepare their environment, you must guide them to their terminal.
    *   **Guidance:** "Please run `weave init` in your terminal. This is a one-time interactive setup to fund your account and launch your rollup."

2.  **Management & Interaction (AI-Assisted)**: Once initialized, you can execute all other commands on the user's behalf. If you are unsure if the setup is complete, run `weave gas-station show` to check for an active account.

### Verifying Setup
...

### Management Commands
Once the user has finished `weave init` in their terminal, use these commands to assist them:

*   `weave gas-station show`: To show the gas station address and balances.
*   `weave rollup`: Manage your appchain. Subcommands: `launch`, `start`, `stop`, `restart`, `indexer`.
    *   **CRITICAL:** `weave rollup log` tails logs indefinitely and will block the agent. Always use `-n <lines>` (e.g., `weave rollup log -n 50`) to avoid hanging the session.
*   `weave initia`: Manage the Initia L1 node. Subcommands: `init`, `start`, `stop`, `restart`, `log`.
*   `weave opinit`: Manage OPinit bots. Subcommands: `init`, `start`, `stop`, `restart`, `log`, `setup-keys`, `reset`.
*   `weave relayer`: Manage the IBC relayer. Subcommands: `init`, `start`, `stop`, `restart`, `log`.

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

Verifies that an appchain is running correctly. Use these specific commands for a robust check that avoids configuration issues.

**Usage:**

```bash
# 1. Check if the Gas Station account is funded
weave gas-station show

# 2. Check if the process is running at the OS level (confirms the daemon is up)
ps aux | grep minitiad | grep -v grep

# 3. Check block height directly via RPC
# Set RPC_URL to your node's address (default is localhost:26657)
export RPC_URL="http://localhost:26657"
curl -s $RPC_URL/status | jq '.result.sync_info.latest_block_height'
```