# Contracts (MoveVM, WasmVM, EVM)

## Table of Contents

1. Intake Questions
2. Opinionated Defaults
3. Toolchain Prerequisites
4. Implementation Checklist
5. MoveVM
6. WasmVM (CosmWasm)
7. EVM (Solidity)
8. Deployment Output Expectations
9. Gotchas

## Intake Questions

Ask for missing inputs before generating contract code:

1. Which VM (`evm`, `move`, `wasm`)?
2. Is this new contract scaffolding or edits to existing code?
3. Is oracle integration required?
4. Which network and chain IDs are targeted?
5. Which deployment toolchain is expected (Foundry, Move CLI, CosmWasm workflow)?

## Opinionated Defaults

| Area | Default | Notes |
|---|---|---|
| VM | `evm` | Use `move`/`wasm` only when requested |
| EVM toolchain | Foundry | Keep `solc` pinned |
| Move dependency | `InitiaStdlib` | Use official repo path |
| Wasm baseline | `cosmwasm-std` + `cw-storage-plus` | Add oracle libs only when needed |

## Toolchain Prerequisites

Install only the toolchain needed for the target VM.

### Common

```bash
# macOS
brew install git jq

# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y git jq
```

### EVM (Foundry)

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge --version
```

### WasmVM (Rust/CosmWasm)

```bash
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
rustup target add wasm32-unknown-unknown
cargo --version
```

### MoveVM / Appchain CLI

Use the CLI for your Initia environment and confirm it supports Move build/publish for your target chain. For Move 2 support, use `initiad` (v1.2.2+).

```bash
initiad version
initiad config view
```

## Implementation Checklist

1. Confirm VM and select matching section below.
2. Produce a minimal compile-ready starter first (`scripts/scaffold-contract.sh <evm|move|wasm> <target-dir>`).
3. Add feature-specific logic (oracle, execute paths, storage).
4. Add placeholders for chain/module-specific values.
5. Provide explicit build/deploy commands for the selected VM.

## MoveVM

### Quick Start (Fast-Path)

Use the provided script to scaffold a project with pre-cloned local dependencies. This avoids slow git resolution and provides a Move 2.1 compatible starter.

```bash
# Usage: scripts/scaffold-contract.sh move <target-dir>
scripts/scaffold-contract.sh move ./my-project
```

### Project Structure

```text
.
├── Move.toml
├── deps/
│   └── movevm/ (Pre-cloned for speed)
└── sources/
    └── <module_name>.move
```

### Baseline Move.toml (Move 2.1)

```toml
[package]
name = "MyProject"
version = "0.0.1"

[dependencies]
InitiaStdlib = { local = "deps/movevm/precompile/modules/initia_stdlib" }
MoveStdlib = { local = "deps/movevm/precompile/modules/move_stdlib" }

[addresses]
my_module = "_"
std = "0x1"
```

### Move 2.1 Features Example

```move
module my_module::game {
    use std::signer;

    struct Player has key {
        points: u64,
    }

    public entry fun join(account: &signer) {
        move_to(account, Player { points: 0 });
    }

    /// View functions use the #[view] attribute in Move 2.1
    #[view]
    public fun get_points(addr: address): u64 acquires Player {
        if (exists<Player>(addr)) {
            borrow_global<Player>(addr).points
        } else {
            0
        }
    }
}
```

### Oracle Integration (Move 2.1)

```move
module my_module::oracle_consumer {
    use std::string::utf8;
    use initia_std::oracle::get_price;

    #[view]
    public fun btc_price(): (u256, u64, u64) {
        let (price, timestamp, decimals) = get_price(utf8(b"BITCOIN/USD"));
        (price, timestamp, decimals)
    }
}
```

### Build and Test (Move)

```bash
# Build (Always specify version 2.1 for latest features)
# If your Move.toml uses "_" for an address, provide it via --named-addresses
minitiad move build --language-version=2.1 --named-addresses my_module=0x2

# Test
minitiad move test --language-version=2.1 --named-addresses my_module=0x2
```

### Deploy and Publish (Move)

The automated `deploy` command builds and publishes the entire package in one step.

```bash
# 1. Automated Deploy (Recommended)
# Run this from your Move project root
minitiad move deploy \
  --from gas-station \
  --keyring-backend test \
  --chain-id <CHAIN_ID> \
  --gas auto --gas-adjustment 1.4 --yes

# 2. Manual Publish (Specific bytecode files)
minitiad tx move publish <PATH_TO_BYTECODE> \
  --from gas-station \
  --keyring-backend test \
  --chain-id <CHAIN_ID> \
  --gas auto --gas-adjustment 1.4 --yes
```

### Execute and Query (Move)

```bash
# 1. Execute a function (entry point)
minitiad tx move execute <MODULE_ADDRESS> <MODULE_NAME> <FUNCTION_NAME> \
  --args <JSON_ARGS_ARRAY> \
  --from gas-station \
  --keyring-backend test \
  --chain-id <CHAIN_ID> \
  --gas auto --gas-adjustment 1.4 --yes

# 2. Call a view function
minitiad query move view <MODULE_ADDRESS> <MODULE_NAME> <FUNCTION_NAME> \
  --args <JSON_ARGS_ARRAY>
```

#### Move Argument Formatting (CRITICAL)
When using `--args` in `minitiad`, you MUST prefix values with their Move type to ensure correct BCS serialization.

| Type | Prefix Example |
|---|---|
| Address | `"address:0x1"` or `"address:init1..."` |
| U64 | `"u64:100"` |
| Bool | `"bool:true"` |
| String | `"string:hello"` |
| Vector | `"vector<u8>:1,2,3"` |

Example:
`minitiad query move view <ADDR> <MOD> <FUNC> --args '["address:init1...", "u64:5"]'`

## WasmVM (CosmWasm)

### Project Structure and Filenames

```text
.
├── Cargo.toml
└── src/
    ├── contract.rs
    ├── error.rs
    ├── lib.rs
    ├── msg.rs
    └── state.rs
```

Conventions:
- Core entry points in `src/contract.rs`
- Message types in `src/msg.rs`
- State models in `src/state.rs`

### Baseline Dependencies

```toml
[dependencies]
cosmwasm-schema = "2.0.1"
cosmwasm-std = { version = "2.0.1", features = ["cosmwasm_1_3"] }
cw-storage-plus = "2.0.0"
cw2 = "2.0.0"
schemars = "0.8.16"
serde = { version = "1.0.197", default-features = false, features = ["derive"] }
thiserror = "1.0.58"
```

### Oracle Query Pattern

```rust
use cosmwasm_std::{to_json_binary, Binary, Deps, QueryRequest, StdResult, WasmQuery};

pub fn query_price_raw(deps: Deps, oracle_addr: String) -> StdResult<Binary> {
    deps.querier.query(&QueryRequest::Wasm(WasmQuery::Smart {
        contract_addr: oracle_addr,
        msg: to_json_binary(&slinky_wasm::oracle::QueryMsg::GetPrice {
            base: "BTC".to_string(),
            quote: "USD".to_string(),
        })?,
    }))
}
```

### Build and Deploy (Wasm)

```bash
# Build wasm artifact
cargo build --target wasm32-unknown-unknown --release

# Upload/store code (using the default gas-station account)
minitiad tx wasm store <PATH_TO_WASM> \
  --from gas-station \
  --keyring-backend test \
  --gas auto \
  --gas-adjustment 1.4 \
  --fees <FEE_AMOUNT><FEE_DENOM> \
  -y

# Instantiate contract
minitiad tx wasm instantiate <CODE_ID> '<INIT_MSG_JSON>' \
  --label <LABEL> \
  --admin $(minitiad keys show gas-station -a --keyring-backend test) \
  --from gas-station \
  --keyring-backend test \
  --gas auto \
  --gas-adjustment 1.4 \
  --fees <FEE_AMOUNT><FEE_DENOM> \
  -y
```

## EVM (Solidity)

### Project Structure and Filenames

```text
.
├── foundry.toml
├── src/
│   └── <ContractName>.sol
├── script/
│   └── Deploy.s.sol
└── lib/
```

Conventions:
- Contract filenames use PascalCase (example: `OracleConsumer.sol`)
- Deploy script at `script/Deploy.s.sol`

### Oracle Example

```solidity
pragma solidity ^0.8.24;

import "initia-evm-contracts/src/interfaces/ISlinky.sol";

contract OracleConsumer {
    ISlinky public immutable slinky;

    constructor(address slinkyAddress) {
        slinky = ISlinky(slinkyAddress);
    }

    function oracleGetPrice() external view returns (uint256 price) {
        string memory base = "BTC";
        string memory quote = "USD";
        price = slinky.get_price(base, quote);
    }
}
```

### Build and Deploy (EVM)

> **Note:** For EVM deployment, you can use Foundry (recommended) or the `minitiad` CLI for raw bytecode.

#### Option 1: Foundry (Recommended)

```bash
# Build
forge build

# Deploy (using gas-station private key)
forge script script/Deploy.s.sol:Deploy \
  --rpc-url <EVM_RPC_URL> \
  --private-key <GAS_STATION_PRIVATE_KEY> \
  --broadcast
```

#### Option 2: Minitiad CLI (Raw Bytecode)

```bash
# Deploy a contract from a .bin file
minitiad tx evm create <PATH_TO_BIN> \
  --from gas-station \
  --keyring-backend test \
  --chain-id <CHAIN_ID> \
  --gas auto --gas-adjustment 1.4 --yes

# Example with constructor arguments (hex encoded)
# minitiad tx evm create MyContract.bin --input 010203... --from gas-station ...
```

### Execute and Query (EVM CLI)

```bash
# Execute a contract call
minitiad tx evm call <CONTRACT_ADDRESS> <INPUT_HEX> \
  --from gas-station \
  --keyring-backend test \
  --chain-id <CHAIN_ID> \
  --gas auto --gas-adjustment 1.4 --yes

# Query EVM state (via JSON-RPC)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"0x...","data":"0x..."},"latest"],"id":1}' \
  <EVM_RPC_URL>
```

## Deployment Output Expectations

For any deploy flow, return:

1. Deployed contract address.
2. Transaction hash.
3. Network/chain ID used.
4. One working read or write command to verify deployment.

## Gotchas

- **Move Build Hangs (Automatic Fix)**: Building Move packages with git dependencies is slow. 
  - **AI Strategy**: When starting a Move project, the AI should automatically set up a local `deps/` folder for the Initia framework to ensure fast builds. 
  - **Action**: Use `scripts/scaffold-contract.sh move <dir>` as the primary path. If modifying an existing project, explain: *"I'm setting up a local `deps/` folder for the Initia framework to speed up your builds."* and then run:
    `mkdir -p deps && cd deps && git clone --depth 1 https://github.com/initia-labs/movevm.git`
    Then update `Move.toml` to use `local` paths for dependencies.

- **Move Build Hangs (Manual Workaround)**: Clone the repository into a `deps/` folder at your project root with `--depth 1` and point to it using a `local` dependency in `Move.toml`:
    ```bash
    mkdir -p deps && cd deps
    git clone --depth 1 https://github.com/initia-labs/movevm.git
    ```
    ```toml
    [dependencies]
    # Adjust relative path if your Move package is in a subdirectory (e.g., ../deps/...)
    InitiaStdlib = { local = "deps/movevm/precompile/modules/initia_stdlib" }
    ```
- Move: module addresses and named addresses must align with deployment config.
- Wasm: keep query/execute/instantiate boundaries explicit and typed.
- EVM: pin compiler version and ensure imported Initia interfaces match deployed chain tooling.
- CLI subcommands/flags can vary by environment; adjust to your chain profile.
- If unsure, re-scaffold from scratch:

```bash
scripts/scaffold-contract.sh <evm|move|wasm> <target-dir>
```
