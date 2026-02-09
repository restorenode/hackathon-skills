# End-to-End Recipes

Use these recipes when users need a full workflow, not isolated snippets.

## Table of Contents

1. Recipe 1: New Rollup + Contract + Frontend
2. Recipe 2: Existing Rollup + Frontend Integration
3. Recipe 3: Debug Broken End-to-End Flow
4. Completion Criteria

## Recipe 1: New Rollup + Contract + Frontend

### Step 1: Preflight and setup

Run the `Preflight` commands from `weave-commands.md`.  
If dependencies are missing, install before continuing.

### Step 2: Create/fund gas station (interactive)

Run the `Gas Station` commands from `weave-commands.md`.

### Step 3: Create launch config

Create `~/.weave/launch_config.json` using `weave-config-schema.md` defaults.

### Step 4: Launch rollup (interactive)

Run the `Rollup Lifecycle` launch command from `weave-commands.md` with `--vm evm`.

### Step 5: Verify rollup health

```bash
scripts/verify-appchain.sh --chain-id <CHAIN_ID> --rpc-url <RPC_URL>
```

Expected: latest block height > 0.

### Step 6: Implement contract workflow

Use `contracts.md` for the VM-specific scaffold/build/deploy flow.

For a minimal starter:

```bash
scripts/scaffold-contract.sh <evm|move|wasm> <target-dir>
```

### Step 7: Wire frontend providers

Choose frontend path by VM:
- `evm` (default): use `frontend-evm-rpc.md`, then verify:

```bash
scripts/check-provider-setup.sh --mode evm-rpc <providers-file.tsx>
```

- `move`/`wasm` or explicit InterwovenKit request: use `frontend-interwovenkit.md`, then verify:

```bash
scripts/check-provider-setup.sh --mode interwovenkit <providers-file.tsx>
```

### Step 8: Run transaction smoke test

Use wallet connect + one tx flow from the chosen frontend reference file.
Expected: transaction hash returned and visible in logs/explorer.

## Recipe 2: Existing Rollup + Frontend Integration

### Step 0: Resolve missing VM/chain/endpoints first

If VM, `chain_id`, or endpoints are missing, check local Weave runtime/config and confirm with user:

Use `runtime-discovery.md`.

### Step 1: Confirm appchain health

```bash
scripts/verify-appchain.sh --chain-id <CHAIN_ID> --rpc-url <RPC_URL>
```

### Step 2: Add provider stack

Choose frontend path by VM:
- `evm`: default to direct JSON-RPC frontend from `frontend-evm-rpc.md`.
- `move`/`wasm` or explicit InterwovenKit request: apply `frontend-interwovenkit.md`.

### Step 3: Add wallet and tx flow

Implement wallet/tx flow from the selected frontend reference file:
- `evm`: `frontend-evm-rpc.md`
- `move`/`wasm` or explicit InterwovenKit request: `frontend-interwovenkit.md`

### Step 4: Validate network alignment

Confirm frontend runtime values match rollup:
- `chain_id`
- RPC/LCD endpoints
- module addresses (if contract calls are enabled)
- environment defaults (`TESTNET` vs `MAINNET`) and wallet active network

## Recipe 3: Debug Broken End-to-End Flow

### Step 1: Isolate layer

Identify which layer fails first:
- rollup health
- contract logic/deployment
- frontend provider/wallet
- tx serialization/execution

### Step 2: Run deterministic checks

```bash
scripts/verify-appchain.sh --chain-id <CHAIN_ID> --rpc-url <RPC_URL>
scripts/check-provider-setup.sh --mode auto <providers-file.tsx>
python3 scripts/convert-address.py <ADDRESS> --prefix init
```

### Step 3: Reproduce with minimal path

1. Verify rollup up and producing blocks.
2. Send a minimal bank tx via frontend `requestTxBlock`.
3. Add contract query only after base tx path works.

### Step 4: Resolve common mismatches

- Wrong VM assumptions (`evm` vs `move` vs `wasm`)
- Wrong chain/network environment
- Missing wallet connection (`initiaAddress` undefined)
- Bad address format in config (`0x...` instead of `init1...` where required)

## Completion Criteria

Treat a recipe as complete only when:

1. Rollup health is verified.
2. One successful tx path is confirmed.
3. Relevant snippets/config are saved in project files.
4. User can rerun the core commands without manual troubleshooting.
