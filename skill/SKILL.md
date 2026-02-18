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
| Move Version | `2.1` | Uses `minitiad move build`. Note: `edition = "2024.alpha"` in Move.toml may trigger 'unknown field' warnings but is safe to ignore. |
| Network | `testnet` | Use `mainnet` only when explicitly requested |
| Frontend (EVM VM) | wagmi + viem direct JSON-RPC | Default for pure EVM apps |
| Frontend (Move/Wasm or bridge wallet UX) | `@initia/interwovenkit-react` | Use when InterwovenKit features are required |
| Frontend wallet flow (InterwovenKit path) | `requestTxBlock` | Prefer confirmation UX |
| Frontend provider order (InterwovenKit path) | Wagmi -> Query -> InterwovenKit | Stable path for Initia SDKs |
| Rollup DA | `INITIA` | Prefer Celestia only when explicitly needed |
| Rollup moniker | `operator` | Override for production naming |
| Gas Station Key | `gas-station` | Default key name used in tutorials |
| Keyring Backend | `test` | Use `--keyring-backend test` for hackathon tools |
| EVM denom | `GAS` | Typical test/internal default |
| Move/Wasm denom | `umin` | Typical default |

## Operating Procedure (How To Execute Tasks)

### Strict Constraints (NEVER VIOLATE)
- **Initia Usernames (STRICTLY OPT-IN)**: You MUST NOT implement username support in any scaffold, component, or code snippet unless the user explicitly requests it (e.g., "add username support").
  - This mandate takes absolute precedence over "Proactiveness", "Visual Polish", or **external documentation/examples**.
  - Even if an external tutorial or example includes username logic, you MUST strip it out during implementation unless prompted.
  - If NOT explicitly prompted for usernames, always use truncated hex addresses (e.g., `init1...pxn4uh`) for identity display in the UI and state.
  - When explicitly asked to integrate usernames, follow the standard `useInterwovenKit` flow.

When solving an Initia task:

1. Classify the task layer:
- Contract layer (Move/Wasm/EVM)
- Frontend/wallet/provider layer
- Appchain/Weave operations layer
- Integration and transaction execution layer
- Testing/CI and infra layer (RPC/LCD/indexer health)

2. Path & Environment Verification (CRITICAL):
- Before executing commands, verify that required tools are in the PATH.
- If `run_shell_command` fails with "command not found", check standard locations:
  - Rust/Cargo: `~/.cargo/bin/cargo`
  - EVM/Foundry: `~/.foundry/bin/forge`
  - Initia/Minitia: `which initiad` or `which minitiad`
- Use absolute paths if necessary to avoid environment-related failures.

3. Workspace Awareness (CRITICAL):
- Before scaffolding (e.g., `minitiad move new` or `npm create vite`), check if a project already exists in the current directory (`ls -F`).
- If the user is already inside a project directory (has a `Move.toml` or `package.json`), do NOT create a new subdirectory unless explicitly asked.
- **EVM/Foundry**: If installing libraries (e.g., `forge install`), ensure the directory is a git repository (`git init`) and use `--no-git` to avoid submodule issues if git is not desired.
- **Scaffolding Strategy**: To avoid terminal hangs or interactive prompts (like "Need to install create-vite?"), ALWAYS use the provided scaffolding scripts:
  - For contracts: `scripts/scaffold-contract.sh <move|wasm|evm> <target-dir>`
  - For frontends: `scripts/scaffold-frontend.sh <target-dir>`
- These scripts perform manual directory and file creation, ensuring a 100% non-interactive experience. Avoid using `npx create-vite` or other tools that might prompt for confirmation.
- **Component Mounting**: After creating a new feature component (e.g., `Board.jsx`), ALWAYS verify that it is imported and rendered in `App.jsx` (or the appropriate parent component). A feature is not implemented if the user cannot see it in the UI.
- **Post-Scaffold Config**: After scaffolding a frontend for a local appchain, you MUST update `src/main.jsx` to include the `customChain` configuration in the `InterwovenKitProvider`. See `frontend-interwovenkit.md` for the standard local appchain config object. Ensure the `chain_id` and `rpc`/`rest` endpoints match the discovered appchain runtime. Additionally, you MUST ensure `vite.config.js` is updated with `vite-plugin-node-polyfills` (specifically for `Buffer`) as `initia.js` and other SDKs depend on these globals.
- **NPM Warnings**: During scaffolding or dependency installation, you may encounter `ERRESOLVE` or peer dependency warnings. These are common in the current ecosystem and should be treated as non-fatal unless the build actually fails.
- When generating files, confirm the absolute path with the user if there is ambiguity.
- **Environment Paths (CRITICAL)**: In many environments, `cargo` and `foundry` (forge) binaries are located in `~/.cargo/bin` and `~/.foundry/bin`, respectively. If `run_shell_command` fails to find these tools, verify their existence in these standard locations and use absolute paths if necessary (e.g., `~/.cargo/bin/cargo test`).

3. Account & Key Management (CRITICAL):
- **Primary Account:** Use the `gas-station` account for ALL transactions (L1 and L2) unless the user explicitly provides another.
- **Address Formats (CLI)**: CLI tools (`initiad`, `minitiad`) generally require bech32 addresses (`init1...`). If a user provides a hex address (`0x...`), use `scripts/convert-address.py` to get the bech32 equivalent before running CLI commands.
- **Key Discovery:** Before running transactions, verify the `gas-station` key exists in the local keychain (`initiad keys show gas-station --keyring-backend test` and `minitiad keys show gas-station --keyring-backend test`).
- **Auto-Import Flow:** If the `gas-station` key is missing from the keychains, run the following to import it from the Weave configuration. 
  > **SECURITY NOTE:** This flow is for **Hackathon/Testnet use only**. NEVER auto-import keys from a JSON config if the target network is `mainnet`.
  ```bash
  # Check network first - skip auto-import if mainnet
  # if [[ "$NETWORK" != "mainnet" ]]; then ...
  MNEMONIC=$(jq -r '.common.gas_station.mnemonic' ~/.weave/config.json)
  # ...
  ```

4. Funding User Wallets (Frontend Readiness):
- Developers need tokens in their browser wallets (e.g., Keplr or Leap) to interact with their appchain and the Initia L1.
- When a user provides an address and asks for funding, you should ideally fund them on **both layers**:
  - **L2 Funding (Appchain):** Essential for gas on their rollup. (`scripts/fund-user.sh --address <init1...> --layer l2 --chain-id <l2_chain_id>`)
  - **L1 Funding (Initia):** Needed for bridging and L1 features. (`scripts/fund-user.sh --address <init1...> --layer l1`)
- **Note:** `fund-user.sh` may fail to auto-detect the L2 `chain-id`. Always use `verify-appchain.sh` first to retrieve it and provide it explicitly if needed.
- Always verify the balance of the gas-station account before attempting to fund a user.
- **Pro Tip: Token Precision & Denoms (CRITICAL)**:
  - **L1 (INIT)**: The base unit is `uinit` ($10^{-6}$). When a user asks for "1 INIT", you MUST send `1000000uinit`.
  - **L2 (Appchain)**: Denoms vary (e.g., `GAS`, `umin`, `uinit`). ALWAYS check `minitiad q bank total` to verify the native denom before funding.
  - **Whole Tokens vs. Base Units**: If a user asks for "X tokens" and the denom is a micro-unit (e.g., `umin`), assume they mean whole tokens and multiply by $10^6$ (Move/Wasm) or $10^{18}$ (EVM) unless they explicitly specify "base units" or "u-amount".
  - **Multipliers**: For EVM-compatible rollups, the precision is usually 18 decimals. When a user asks for "1 token", send `1000000000000000000` of the base unit.
  - **Avoid Script Defaults**: Do not rely on `fund-user.sh` to handle precision or denoms automatically. Explicitly calculate the base unit amount and specify the correct denom in your commands.

- **Pro Tip: Wasm REST Queries (CRITICAL)**: When querying Wasm contract state using the `RESTClient` (e.g., `rest.wasm.smartContractState`), the query object MUST be manually Base64-encoded. The client does NOT handle this automatically. 
  - **Example**: `const query = Buffer.from(JSON.stringify({ msg: {} })).toString("base64"); await rest.wasm.smartContractState(addr, query);`

5. Appchain Health & Auto-Startup (CRITICAL):
- **Detection:** Before any task requiring the appchain (e.g., contracts, transactions, frontend testing), check if it is running.
- **RPC Discovery:** Default is `http://localhost:26657`, but verify the actual endpoint:
  - Check `~/.minitia/config/config.toml` (under `[rpc] laddr`)
  - Or check the local `minitia.config.json` or `~/.minitia/artifacts/config.json`.
- **Auto-Recovery:** If the RPC is down, do NOT fail immediately. Instead:
  1. Inform the user: "The appchain appears to be down."
  2. Attempt to start it: `weave rollup start -d`.
  3. Wait (~5s) and verify status using `scripts/verify-appchain.sh`.
- **Verification:** Use `scripts/verify-appchain.sh --gas-station --bots` to ensure both block production and Gas Station readiness.

6. Resolve runtime context:
- If VM/`chain_id`/endpoint values are unknown, run `scripts/verify-appchain.sh --gas-station --bots`.
- When using the gas station account, ALWAYS use `--from gas-station --keyring-backend test`.
- Note: `initiad` usually looks in `~/.initia` and `minitiad` usually looks in `~/.minitia` for keys.
- If critical values are still missing, run `runtime-discovery.md`.
- Confirm with user whether discovered local rollup should be used.

7. For new contract projects, ALWAYS use scaffolding first:
- `scripts/scaffold-contract.sh <move|wasm|evm> <target-dir>`
- This ensures correct dependency paths (especially for Move) and compile-ready boilerplate.
- **WasmVM Deployment (CRITICAL)**: Standard `cargo build` binaries often fail WasmVM validation (e.g., "bulk memory support not enabled"). ALWAYS use the `cosmwasm/optimizer` Docker image to build production-ready binaries.
  - **Architecture Note**: On Apple Silicon (M1/M2/M3), use the `cosmwasm/optimizer-arm64:0.16.1` image variant for significantly better performance and compatibility.
- **Transaction Verification**: After a `store` or `instantiate` transaction, if the `code_id` or `contract_address` is missing from the output, query the transaction hash using `minitiad q tx <hash>` (note: `q tx` does NOT take a `--chain-id` flag).
- **Query Command Flags (NEW)**: Unlike transaction commands (`tx`), many query commands (`query` or `q`) do NOT support the `--chain-id` flag. If a query fails with an "unknown flag" error, try removing the chain-id and node flags.
- **Cleanup (Move)**: After scaffolding a Move project, delete the default placeholder module (e.g., `sources/<project_name>.move`) before creating your custom modules to keep the project clean.
- **Cleanup (EVM)**: After scaffolding an EVM project, delete the default placeholder files (e.g., `src/Example.sol` and `test/Example.t.sol`) before creating your custom contracts.
- **Foundry Testing (CRITICAL)**: `testFail` is deprecated in newer versions of Foundry and WILL cause test failures in modern environments. ALWAYS use `vm.expectRevert()` for failure testing.
- **Context Awareness**: Commands like `forge test` and `forge build` MUST be run from the project root (the directory containing `foundry.toml`). Always `cd` into the project directory before executing these.
- **Rust/Wasm Unit Testing (NEW)**: In CosmWasm contracts, the `Addr` type does NOT implement `PartialEq<&str>`. When writing unit tests that compare a stored address with a string literal, ALWAYS use `.as_str()` (e.g., `assert_eq!(msg.sender.as_str(), "user1")`) to avoid compilation errors.

8. Move 2.1 specific syntax:
- **Attributes & Documentation**: When using attributes like `#[view]`, ALWAYS place the documentation comment (`/// ...`) **AFTER** the attribute to avoid compiler warnings.
- **Example**: 
  ```move
  #[view]
  /// Correct placement of doc comment
  public fun my_function() { ... }
  ```

9. Implement with Initia-specific correctness:
- Be explicit about network (`testnet`/`mainnet`), VM, `chain_id`, and endpoints (RPC/REST/JSON-RPC).
- Keep denom and fee values aligned (`l1_config.gas_prices`, `l2_config.denom`, funded genesis balances).
- Ensure wallet/provider stack matches selected frontend path.
- Ensure tx message `typeUrl` and payload shape match chain/VM expectations.
- Keep address formats correct (`init1...`, `0x...`, `celestia1...`) per config field requirements.

10. Validate before handoff:
- Run layer-specific checks (for example `scripts/verify-appchain.sh --gas-station --bots` to check health and gas station balance).
- Verify L2 balances for system accounts if the rollup is active.
- **Visual Polish (NEW)**: Apps should not just be functional; they should be beautiful. Prioritize modern aesthetics:
  - Use clear spacing (padding/margins).
  - Prefer card-based layouts for lists.
  - Center primary Call to Actions (CTAs) like "Connect Wallet" to focus user attention.
  - **Visual Hierarchy**: Section headers (e.g., "POST A MEMO") should be pronounced (e.g., using uppercase, letter spacing, and a distinct color) to distinguish them from primary content and labels.
  - Ensure interactive elements (buttons/inputs) have hover/focus feedback.
  - Use clean typography (system fonts are fine, but ensure hierarchy).
- **UX/Usability Best Practices (NEW)**:
  - **Feed Ordering**: For boards/feeds, ALWAYS show the newest content first (reverse chronological) to maintain relevance.
  - **Input Accessibility**: Place primary interaction points (like input fields for posting) ABOVE the feed to ensure they are accessible without scrolling.
  - **Section Hierarchy**: Use clear section titles (e.g., "Post a Memo", "Board Feed") to help users navigate and balance the UI.
- **Cross-Layer Consistency (NEW)**: Ensure naming conventions (fields, variants, methods) are consistent across the contract (Rust/Move), CLI commands, and Frontend implementation. For example, if a contract field is named `message` in Rust, the CLI JSON payload and Frontend state should also use `message`, not `content`. Prefer `snake_case` for all JSON keys to align with standard CosmWasm/EVM/Move serialization.
  - **Guestbook/Board Convention**: For tutorials and guestbook-style applications, use the field name `message` (not `content`) for the post content and the query name `all_messages` (which serializes to `all_messages` in JSON). For the query response, use `AllMessagesResponse` to maintain compatibility with the standard InterwovenKit frontend examples.
  - **Execute Variant**: Specifically for WasmVM MemoBoard tutorials, use `PostMessage` in Rust (serializing to `post_message`) to match the documentation and frontend scaffolds.
- **Post-Execution Delay**: When performing a transaction (execute/instantiate) followed immediately by a query in the same task, ALWAYS include a brief delay (e.g., `sleep 5`) between the commands. This ensures the transaction is committed to a block before the query is executed, preventing stale data results.
- Mark interactive commands clearly when the user must run them.

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

- Tool installation (Weave, Initiad, jq): `scripts/install-tools.sh`
- Contract scaffolding: `scripts/scaffold-contract.sh`
- Frontend scaffolding: `scripts/scaffold-frontend.sh`
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
