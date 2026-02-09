---
name: initia-appchain-dev
description: End-to-end Initia development and operations guide. Use when asked to build Initia smart contracts (MoveVM/WasmVM/EVM), build React frontends (InterwovenKit or EVM direct JSON-RPC), launch or operate Interwoven Rollups with Weave CLI, or debug appchain/transaction integration across these layers.
---

# Initia Appchain Dev

Deliver practical guidance for full-stack Initia development: contracts, frontend integration, and appchain operations.

## Intake Questions (Ask First)

Collect missing inputs before implementation:

1. Which VM is required (`evm`, `move`, `wasm`)?
2. Which network is targeted (`testnet` or `mainnet`)?
3. Is this a fresh rollup launch or operation/debug on an existing rollup?
4. For frontend work, is this an EVM JSON-RPC app or an InterwovenKit wallet/bridge app?
5. What chain-specific values are known (`chain_id`, RPC URL, module address, denom)?

If critical values are missing, ask concise follow-up questions before generating final code/config.

If `chain_id`/endpoints/VM are missing, run the discovery flow in `runtime-discovery.md` before assuming defaults.

Then ask a context-specific confirmation:
- Frontend task: "I found a local rollup config/runtime. Should I use this rollup for frontend integration?"
- Non-frontend task: "I found local runtime values (VM, chain ID, endpoints). Should I use these for this task?"

## Opinionated Defaults

| Area | Default | Notes |
|---|---|---|
| VM | `evm` | Use `move`/`wasm` only when requested |
| Network | `testnet` | Use `mainnet` only when explicitly requested |
| Frontend (EVM VM) | wagmi + viem direct JSON-RPC | Default for pure EVM apps |
| Frontend (Move/Wasm or bridge wallet UX) | `@initia/interwovenkit-react` | Use when InterwovenKit features are required |
| Frontend wallet flow (InterwovenKit path) | `requestTxBlock` | Prefer confirmation UX |
| Frontend provider order (InterwovenKit path) | Query -> Wagmi -> InterwovenKit | Baseline path |
| Rollup DA | `INITIA` | Prefer Celestia only when explicitly needed |
| Rollup moniker | `operator` | Override for production naming |
| EVM denom | `GAS` | Typical test/internal default |
| Move/Wasm denom | `umin` | Typical default |

## Operating Procedure (How To Execute Tasks)

When solving an Initia task:

1. Classify the task layer:
- Contract layer (Move/Wasm/EVM)
- Frontend/wallet/provider layer
- Appchain/Weave operations layer
- Integration and transaction execution layer
- Testing/CI and infra layer (RPC/LCD/indexer health)
2. Resolve runtime context first:
- If VM/`chain_id`/endpoint values are missing, run `runtime-discovery.md`.
- Confirm with user whether discovered local rollup should be used.
3. Pick task-specific references from the Progressive Disclosure list below.
4. Implement with Initia-specific correctness:
- Be explicit about network (`testnet`/`mainnet`), VM, `chain_id`, and endpoints (RPC/REST/JSON-RPC).
- Keep denom and fee values aligned (`l1_config.gas_prices`, `l2_config.denom`, funded genesis balances).
- Ensure wallet/provider stack matches selected frontend path.
- Ensure tx message `typeUrl` and payload shape match chain/VM expectations.
- Keep address formats correct (`init1...`, `0x...`, `celestia1...`) per config field requirements.
5. Validate before handoff:
- Run layer-specific checks (for example `scripts/verify-appchain.sh`, `scripts/check-provider-setup.sh`, contract build/test commands).
- Mark interactive commands clearly when the user must run them.
- If confidence is low on Initia behavior, verify against official docs first.

## Progressive Disclosure (Read When Needed)

- Runtime discovery and local rollup detection: `runtime-discovery.md`
- Contracts (Move/Wasm/EVM): `contracts.md`
- Frontend (EVM direct JSON-RPC): `frontend-evm-rpc.md`
- Frontend (InterwovenKit): `frontend-interwovenkit.md`
- Weave command lookup: `weave-commands.md`
- Launch config field reference: `weave-config-schema.md`
- Failure diagnosis and recovery: `troubleshooting.md`
- End-to-end workflows: `e2e-recipes.md`

## Documentation Fallback

When uncertain about any Initia-specific behavior, prefer official docs:

- Core docs: `https://docs.initia.xyz`
- InterwovenKit docs: `https://docs.initia.xyz/interwovenkit`

Do not guess when an authoritative answer can be confirmed from docs.

## Script Usage

- Contract scaffolding: `scripts/scaffold-contract.sh`
- Frontend provider sanity check: `scripts/check-provider-setup.sh`
- Appchain health verification: `scripts/verify-appchain.sh`
- Address conversion (hex/bech32): `scripts/convert-address.py`
- System key generation (`bip_utils`; pass `--vm <evm|move|wasm>` for denom-aware defaults; mnemonics are redacted unless `--include-mnemonics --output <file>`): `scripts/generate-system-keys.py`

## Expected Deliverables

When implementing substantial changes, return:

1. Exact files changed.
2. Commands to run for setup/build/test.
3. Verification steps and expected outputs.
4. Short risk notes for signing, key material, fees, or production-impacting changes.

## Output Rules

- Keep examples internally consistent.
- Include prerequisites for every command sequence.
- Avoid unsafe fallback logic in key or signing workflows.
- Never print raw mnemonics in chat output; if needed, write them to a protected local file.
- If uncertain about Initia specifics, consult official Initia docs first.
