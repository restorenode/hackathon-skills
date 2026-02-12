# Troubleshooting Playbook

## Table of Contents

1. Weave / Rollup
2. Frontend / InterwovenKit
3. Contracts
4. Configuration

## Weave / Rollup

### 1. Gas station missing or underfunded

Symptoms:
- Launch/setup fails with funding errors.

Checks:

```bash
weave gas-station show
```

Actions:
- Re-run `weave gas-station setup`.
- Fund the account (testnet faucet for testnet).

### 2. Rollup not producing blocks

Checks:

```bash
weave rollup log -n 100
curl http://localhost:26657/status
```

Then run:

```bash
scripts/verify-appchain.sh --chain-id <CHAIN_ID> --rpc-url <RPC_URL>
```

Actions:
- Confirm `chain_id` and RPC URL alignment.
- Restart rollup: `weave rollup restart`.

### 3. Port conflicts

Symptoms:
- Startup fails due to occupied ports (`1317`, `26657`, `9090`, `8545`).

Checks:

```bash
lsof -i :1317 -i :26657 -i :9090 -i :8545
```

Actions:
- Stop conflicting processes or update service config.

## Frontend / InterwovenKit

### 4. Missing VM/chain/endpoints before frontend work

Checks:

Use `runtime-discovery.md`.

Actions:
- If rollup details are found, confirm with user before wiring frontend values.
- If VM resolves to `evm` and no InterwovenKit features are needed, use `frontend-evm-rpc.md`.

### 5. Wallet/connect UI does not appear

Checks:
- Provider order includes `QueryClientProvider` -> `WagmiProvider` -> `InterwovenKitProvider`.
- If `PrivyProvider` is present, ensure it wraps the stack.

Run:

```bash
scripts/check-provider-setup.sh --mode interwovenkit <providers-file.tsx>
```

### 6. Chain not found / wrong chain selected

Symptoms:
- Runtime error like `Chain not found: <CHAIN_ID>`.

Checks:
- Do not mix `TESTNET` config with mainnet chain id (`interwoven-1`).
- For testnet, prefer `defaultChainId={TESTNET.defaultChainId}`.
- Ensure wallet network, frontend defaults, and endpoints target the same environment.

### 7. Transaction submission fails

Checks:
- Wallet connected and `initiaAddress` is present.
- Correct message `typeUrl` and serialized args.
- Network/chain values match the active wallet environment.
- For minievm calls, use `typeUrl: "/minievm.evm.v1.MsgCall"`.

### 8. NPM install interrupted / dependency state corrupted

Symptoms:
- Repeated install errors after timeout/interrupted install (`ENOTEMPTY`, rename conflicts).

Actions:

```bash
rm -rf node_modules package-lock.json
npm install
```

## Contracts

### 9. Build/import errors from wrong VM assumptions

Checks:
- Confirm VM target first (`evm`, `move`, `wasm`).
- Confirm toolchain and dependency set for that VM.
- **Move 2.0 Compatibility:** Projects default to Move 2.0 (`edition = "2024.alpha"`). If you see "unsupported language construct", ensure your `minitiad` version is `v1.1.10` or higher. You can update it by running `make install` in the `minimove` repository.
- **Hex Addresses:** `Move.toml` requires addresses in hex format (`0x...`). Use `scripts/to_hex.py <address>` to convert Bech32 addresses.
- **Library Naming:** Use `initia_std` (not `initia_stdlib`) when importing core modules: `use initia_std::table;`.
- **Receiver Syntax:** Not all standard library modules support receiver functions yet. If `account.address_of()` fails, use the classic `signer::address_of(account)`.

Actions:
- Re-scaffold using:

```bash
scripts/scaffold-contract.sh <evm|move|wasm> <target-dir>
```

## Configuration

### 10. Launch config rejected by Weave

Checks:
- Field names are snake_case.
- Required sections exist (`l1_config`, `l2_config`, `op_bridge`).
- `chain_id`, `rpc_url`, and denom values are valid for target network/VM.

Reference:
- `weave-config-schema.md`
