---
name: weave
description: 'Scaffolds and manages Initia appchains (Interwoven Rollups) using the Weave CLI. Use this skill to launch, configure, and interact with a new appchain.'
---

# Weave Skill

This skill helps you scaffold and manage Initia appchains (Interwoven Rollups) using the Weave CLI. It provides a non-interactive way to launch and manage your appchain.

## Prerequisites

Before you start, you need three tools:

1.  **[Weave CLI](https://docs.initia.xyz/developers/developer-guides/tools/clis/weave-cli/installation)** - Initializes and launches your rollup
2.  **[minitiad](https://docs.initia.xyz/developers/developer-guides/tools/clis/minitiad-cli/introduction)** - Interacts with your rollup
3.  **jq** - For parsing command output (usually comes with your system or install via package manager)

You also need testnet tokens. Get them from:

-   **Initia L1 faucet** - https://faucet.testnet.initia.xyz/

## First-Time Setup: Your Gas Station Account

Before you can launch an appchain, you need to set up a "gas station" account. This is a one-time setup that needs to be done manually in your terminal.

**1. Start the Interactive Setup**

Run the following command in your terminal:

```bash
weave gas-station setup
```

**2. Follow the Prompts**

The command will guide you through the setup process. You will be asked a couple of questions:

-   First, it will ask if you want to generate a new account or import from a seed phrase. The default option is to **generate a new account**. Press **Enter** to select the default.
-   Next, you will be prompted to type **`continue`** to proceed. Type `continue` and press **Enter**.

**3. Get Your Gas Station Address**

After completing the setup, the command will display your gas station address. You can also run the following command at any time to see your address again:

```bash
weave gas-station show
```

**4. Fund Your Account**

Copy the `initia` address from the output. Then, go to the Initia Testnet Faucet and paste the address to receive testnet INIT tokens.

-   **Initia Testnet Faucet:** https://app.testnet.initia.xyz/faucet

Once your account is funded, you can use the AI assistant to launch your appchain.


## Agent Instructions

When a user asks to launch an appchain, follow these steps:

1.  **Verify Gas Station Setup:** First, check if the user has a gas station account set up by running `weave gas-station show`.
2.  **Retrieve Gas Station Address:** If the account exists, parse the output of `weave gas-station show` to extract the **Initia Address**. You will need this for the `launch_appchain` command.
3.  **Construct `launch_appchain` Command:** When you use the `launch_appchain` script, you must include the retrieved gas station address in the `GENESIS_ACCOUNTS_JSON` parameter. The user does not need to provide this to you.

## Core Commands

### launch_appchain

Launches a new appchain by generating a configuration file and using `weave init`.

**Usage Template:**

```bash
/path/to/scripts/launch_appchain.sh [L1_CHAIN_ID] [L1_RPC] [VM_TYPE] [CHAIN_ID] [GAS_DENOM] [MONIKER] [GENESIS_ACCOUNTS_JSON] [MINITIAD_BINARY_PATH] [MINITIA_HOME] [DA_LAYER]
```
**Important:** The path to `launch_appchain.sh` is relative to the `weave` skill directory.

**Parameters:**

*   `L1_CHAIN_ID`: The chain ID of the L1 network to connect to (e.g., `initiation-1`).
*   `L1_RPC`: The RPC URL of the L1 network (e.g., `https://rpc.testnet.initia.xyz`).
*   `VM_TYPE`: The virtual machine to use (`Move`, `Wasm`, or `EVM`).
*   `CHAIN_ID`: The chain ID for your new appchain (e.g., `myapp-1`).
*   `GAS_DENOM`: The gas denomination for your appchain (e.g., `uapp`).
*   `MONIKER`: A name for your node (e.g., `my-operator`).
*   `GENESIS_ACCOUNTS_JSON`: A JSON string of genesis accounts and their balances. **You must include the user's gas station address here.** Example: `'[{"address":"<GAS_STATION_ADDRESS>", "coins":"1000000000uapp"}]'`
*   `MINITIAD_BINARY_PATH`: The path to the `minitiad` binary. Your agent should manage this.
*   `MINITIA_HOME`: The home directory for the minitia data. Your agent should manage this.
*   `DA_LAYER`: The data availability layer to use for batch submission. Defaults to "Initia". (e.g., `Initia`)

### verify_appchain

Verifies that the appchain is running correctly.

**Usage:**

```bash
# Set environment variables
export CHAIN_ID="your-chain-id"
export RPC_URL="http://localhost:26657"

# Configure minitiad
minitiad config chain-id "$CHAIN_ID"
minitiad config node "$RPC_URL"

# Check block production
minitiad status | jq -r '.SyncInfo.latest_block_height'

# Check account balance
minitiad query bank balances $(minitiad keys show owner -a)

# Send a test transaction
minitiad keys add alice
export OWNER_ADDR=$(minitiad keys show owner -a)
export ALICE_ADDR=$(minitiad keys show alice -a)
minitiad tx bank send "$OWNER_ADDR" "$ALICE_ADDR" "1000uapp" --gas auto --gas-adjustment 1.2 --yes
sleep 3
minitiad query bank balances "$ALICE_ADDR"
```

## Management Commands

*   **Stopping your rollup:**
    ```bash
    ps aux | grep minitiad
    kill <process-id>
    ```
*   **Restarting your rollup:**
    ```bash
    weave rollup restart
    ```
*   **Viewing logs:** Check the terminal where you ran the launch script.

## File Locations

*   **Configuration:** `~/.weave/data/minitia.config.json`
*   **Chain data:** `~/.minitia/`
*   **Artifacts:** `~/.minitia/artifacts/`