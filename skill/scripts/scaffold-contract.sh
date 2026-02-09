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
    
    echo "Cloning movevm locally for fast builds (depth 1)..."
    git clone --depth 1 https://github.com/initia-labs/movevm.git "$target/deps/movevm" > /dev/null 2>&1 || echo "Warning: git clone failed, check connectivity."

    cat > "$target/Move.toml" <<TOML
[package]
name = "$pkg_name"
version = "0.0.1"

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
    mkdir -p "$target/src" "$target/script" "$target/lib"
    cat > "$target/foundry.toml" <<'TOML'
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
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
    cat > "$target/script/Deploy.s.sol" <<'SOL'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Fill in deployment logic for your environment.
SOL
    ;;
  *)
    usage
    exit 1
    ;;
esac

echo "Scaffolded $vm project at $target"
