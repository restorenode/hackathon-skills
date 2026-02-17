#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scaffold-contract.sh <move|wasm|evm> <target-dir>

Examples:
  scaffold-contract.sh move ./my-move-contract
  scaffold-contract.sh wasm ./my-wasm-contract
  scaffold-contract.sh evm ./my-evm-contract
USAGE
}

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

vm="$1"
target="$2"
pkg_name=$(basename "$target")

mkdir -p "$target"

case "$vm" in
  move)
    mkdir -p "$target/sources"
    mkdir -p "$target/deps"
    
    echo "Cloning movevm locally for fast builds (latest main)..."
    git clone --depth 1 https://github.com/initia-labs/movevm.git "$target/deps/movevm" > /dev/null 2>&1 || echo "Warning: git clone failed, check connectivity."

    cat > "$target/Move.toml" <<TOML
[package]
name = "$pkg_name"
version = "0.0.1"
edition = "2024.alpha"

[dependencies]
InitiaStdlib = { local = "deps/movevm/precompile/modules/initia_stdlib" }
MoveStdlib = { local = "deps/movevm/precompile/modules/move_stdlib" }

[addresses]
$pkg_name = "_"
std = "0x1"
TOML

    cat > "$target/sources/${pkg_name}.move" <<MOVE
module ${pkg_name}::${pkg_name} {
    use std::signer;

    struct State has key {
        value: u64,
    }

    public entry fun initialize(account: &signer) {
        move_to(account, State { value: 0 });
    }

    #[view]
    public fun get_value(addr: address): u64 acquires State {
        borrow_global<State>(addr).value
    }
}
MOVE
    ;;
  wasm)
    mkdir -p "$target/src"
    cat > "$target/Cargo.toml" <<'TOML'
[package]
name = "example"
version = "0.1.0"
edition = "2021"

[dependencies]
cosmwasm-schema = "2.0.1"
cosmwasm-std = { version = "2.0.1", features = ["cosmwasm_1_3"] }
cw-storage-plus = "2.0.0"
cw2 = "2.0.0"
schemars = "0.8.16"
thiserror = "1.0.58"
serde = { version = "1.0.197", default-features = false, features = ["derive"] }
TOML
    cat > "$target/src/lib.rs" <<'RS'
pub mod contract;
RS
    cat > "$target/src/contract.rs" <<'RS'
use cosmwasm_std::{DepsMut, Env, MessageInfo, Response, StdResult};

pub fn instantiate(_deps: DepsMut, _env: Env, _info: MessageInfo) -> StdResult<Response> {
    Ok(Response::new())
}
RS
    touch "$target/src/error.rs" "$target/src/msg.rs" "$target/src/state.rs"
    ;;
  evm)
    mkdir -p "$target/src" "$target/script" "$target/lib" "$target/test"
    cat > "$target/foundry.toml" <<'TOML'
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
test = "test"
solc_version = "0.8.24"
TOML
    cat > "$target/src/Example.sol" <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Example {
    function hello() external pure returns (uint256) {
        return 1;
    }
}
SOL
    cat > "$target/test/Example.t.sol" <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Example.sol";

contract ExampleTest is Test {
    Example public example;

    function setUp() public {
        example = new Example();
    }

    function test_Hello() public {
        assertEq(example.hello(), 1);
    }
}
SOL
    cat > "$target/script/Deploy.s.sol" <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        vm.startBroadcast(deployerPrivateKey);

        // Deploy logic here
        
        vm.stopBroadcast();
    }
}
SOL

    cat > "$target/README.md" <<'EOF'
# EVM Contract Project

## Building
```bash
forge build
```

## Deploying with minitiad
Minitiad requires raw hex bytecode. Use the following to extract it:
```bash
jq -r '.bytecode.object' out/YourContract.sol/YourContract.json | sed 's/^0x//' | tr -d '\n' > your-contract.bin
minitiad tx evm create your-contract.bin --from gas-station --chain-id <chain-id> --yes
```

## Interacting
Encode your calls using `cast`:
```bash
# Get calldata
DATA=$(cast calldata "functionName(type)" arg1)
# Send transaction
minitiad tx evm call <contract-address> $DATA --from gas-station --chain-id <chain-id> --yes
```
EOF

    # Initialize git and install forge-std
    (cd "$target" && git init -q && forge install foundry-rs/forge-std --no-git -q || true)
    cat > "$target/remappings.txt" <<EOF
forge-std/=lib/forge-std/src/
EOF
    ;;
  *)
    usage
    exit 1
    ;;
esac

echo "Scaffolded $vm project at $target"
