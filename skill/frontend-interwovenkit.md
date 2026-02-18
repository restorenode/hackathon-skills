# Frontend (InterwovenKit)

## Table of Contents

1. Intake Questions
2. When To Use This Path
3. Opinionated Defaults
4. Quickstart
5. Dependency Tiers
6. Version Alignment
7. Implementation Checklist
8. Provider Setup (Current Baseline)
9. Custom Chain IDs Not In Initia Registry
10. Wallet Button Pattern
11. Transaction Patterns
12. Optional Advanced Path: Direct SDK Contract Calls
13. Gotchas
14. Install Recovery

## Intake Questions

Ask for missing context before writing code:

1. Framework and runtime (`next`, `react-vite`, other)?
2. Is provider wiring already present?
3. Which network is targeted (testnet/mainnet/custom appchain)?
4. Is user-confirmed tx UX required (`requestTxBlock`) or direct submit acceptable?
5. Are chain endpoints and contract addresses known?

If VM is `evm` and user only needs normal contract interaction over JSON-RPC, use `frontend-evm-rpc.md` as default instead of this file.

## When To Use This Path

Use this file when at least one is true:

- App requires InterwovenKit wallet/bridge/portfolio UI.
- App is Move/Wasm oriented with `requestTxBlock` message flow.
- User explicitly requests InterwovenKit.

For pure EVM dApp frontend work (wallet + contract calls), default to `frontend-evm-rpc.md`.

## Opinionated Defaults

| Area | Default | Notes |
|---|---|---|
| Frontend wallet stack | `@initia/interwovenkit-react` | Primary integration path |
| Tx UX | `requestTxBlock` | Prefer explicit user confirmation |
| Provider order | Wagmi -> Query -> InterwovenKit | Stable provider path |
| Connector | `initiaPrivyWalletConnector` | Default connector in kit docs |
| SDK path | InterwovenKit first | Use direct SDK only when required |

## Quickstart

### React + Vite (TypeScript)

```bash
# Use --template react or react-ts
npm create vite@latest initia-frontend -- --template react-ts
cd initia-frontend
npm install
npm install @initia/interwovenkit-react wagmi viem @tanstack/react-query @initia/initia.js @initia/initia.proto
npm install --save-dev vite-plugin-node-polyfills
npm install buffer util
```

## Dependency Tiers

### Required

- `@initia/interwovenkit-react`
- `@tanstack/react-query`
- `wagmi`
- `viem`
- `buffer` (Required polyfill for browser compatibility)
- `util` (Required polyfill for browser compatibility)

### Optional (common)

- `@initia/utils` for helpers like address truncation.

### Advanced

- `@initia/initia.js` and `@initia/initia.proto` for direct REST/protobuf workflows.
- `vite-plugin-node-polyfills` (Highly recommended for Vite users to avoid "Buffer is not defined" errors).

## Version Alignment

Avoid hard-coded version matrices in this skill.

- Install latest compatible package versions unless the user asks to pin.
- Keep `@initia/interwovenkit-react`, `wagmi`, and `viem` aligned to peer dependency expectations.
- **IMPORTANT**: If using Vite, you MUST install `vite-plugin-node-polyfills` and add it to `vite.config.js` to ensure `@initia/initia.js` works in the browser.

## Implementation Checklist

1. Install required dependencies + polyfills (`buffer`, `util`, `vite-plugin-node-polyfills`).
2. Configure Vite polyfills if applicable.
3. Set up `window.Buffer` and `window.process` in `main.jsx` before other imports.
4. Set up providers in order: `WagmiProvider` -> `QueryClientProvider` -> `InterwovenKitProvider`.
5. For custom appchains, provide a complete `customChain` object including `rpc`, `rest`, and a placeholder `indexer`.
6. Use `RESTClient` (from `@initia/initia.js`) for querying resources or view functions.
7. Prefer `rest.move.resource` for state queries as it is more robust than view functions.

## Provider Setup (Current Baseline)

```tsx
// main.jsx
import { Buffer } from 'buffer'
window.Buffer = Buffer
window.process = { env: { NODE_ENV: 'development' } }

import React from 'react'
import ReactDOM from 'react-dom/client'
import "@initia/interwovenkit-react/styles.css";
import { injectStyles, InterwovenKitProvider, TESTNET } from "@initia/interwovenkit-react";
import InterwovenKitStyles from "@initia/interwovenkit-react/styles.js";
import { WagmiProvider, createConfig, http } from "wagmi";
import { mainnet } from "wagmi/chains";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import App from './App.jsx'

// Inject styles for the widget
injectStyles(InterwovenKitStyles);

const queryClient = new QueryClient();
const wagmiConfig = createConfig({
  chains: [mainnet],
  transports: { [mainnet.id]: http() },
});

const customChain = {
  chain_id: "my-appchain-1",
  chain_name: "myapp",
  pretty_name: "My Appchain",
  network_type: "testnet",
  bech32_prefix: "init",
  logo_URIs: {
    png: "https://raw.githubusercontent.com/initia-labs/initia-registry/main/testnets/initia/images/initia.png",
    svg: "https://raw.githubusercontent.com/initia-labs/initia-registry/main/testnets/initia/images/initia.svg"
  },
  apis: {
    rpc: [{ address: "http://localhost:26657" }],
    rest: [{ address: "http://localhost:1317" }],
    indexer: [{ address: "http://localhost:8080" }],
    "json-rpc": [{ address: "http://localhost:8545" }] // REQUIRED for EVM appchains
  },
  fees: {
    fee_tokens: [{ 
      denom: "GAS", 
      fixed_min_gas_price: 0,
      low_gas_price: 0,
      average_gas_price: 0,
      high_gas_price: 0
    }]
  },
  staking: {
    staking_tokens: [{ denom: "GAS" }]
  },
  metadata: {
    minitia: { type: "minievm" },
    is_evm: true
  }
};

ReactDOM.createRoot(document.getElementById('root')).render(
  <WagmiProvider config={wagmiConfig}>
    <QueryClientProvider client={queryClient}>
      <InterwovenKitProvider 
        {...TESTNET} 
        defaultChainId="my-appchain-1" 
        customChain={customChain}
      >
        <App />
      </InterwovenKitProvider>
    </QueryClientProvider>
  </WagmiProvider>
);
```

## Custom Chain IDs Not In Initia Registry

InterwovenKit supports non-registry chains via `customChain` (singular) or `customChains` (array) on `InterwovenKitProvider`.

Important behavior:

- `customChain` is the preferred property for a single local appchain.
- `apis` MUST use the array-of-objects format: `rpc: [{ address: "..." }]`.
- For `minievm` chains, you MUST include `"json-rpc"` in the `apis` object for internal balance and state queries to resolve.
- `logo_URIs` and `staking` fields improve stability during chain discovery.
- `defaultChainId` must match the `chain_id` you want active.
- If omitted and chain is not in registry/profile sources, runtime can fail with `Chain not found: <CHAIN_ID>`.
- `apis` MUST include `rpc`, `rest`, and `indexer` (even if indexer is a placeholder).

## Wallet Button Pattern

```tsx
import { useInterwovenKit } from "@initia/interwovenkit-react";

function shortenAddress(value: string) {
  if (value.length < 14) return value;
  return `${value.slice(0, 8)}...${value.slice(-6)}`;
}

export function WalletButton() {
  const { initiaAddress, username, openWallet, openConnect } = useInterwovenKit();

  if (!initiaAddress) return <button onClick={openConnect} className="btn">Connect</button>;
  return <button onClick={openWallet} className="btn">{username ?? shortenAddress(initiaAddress)}</button>;
}
```

## Reference UI Patterns (Optional)

Use these patterns to satisfy the "beautiful and polished" mandate for centered appcard layouts.

### Centered Card & Balance Styles
```javascript
const styles = {
  container: {
    padding: '40px',
    width: '100%',
    maxWidth: '520px',
    margin: '40px auto',
    textAlign: 'center',
    borderRadius: '24px',
    boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
    backgroundColor: '#ffffff',
    fontFamily: 'system-ui, sans-serif'
  },
  balanceContainer: {
    backgroundColor: '#f1f5f9',
    padding: '30px',
    borderRadius: '16px',
    marginBottom: '30px',
    border: '1px solid #e2e8f0'
  },
  balanceValue: {
    fontSize: '42px',
    fontWeight: '800',
    color: '#2563eb',
    fontFamily: 'monospace'
  }
};
```

## Transaction Patterns

### Move Contract Execution (`requestTxBlock` flow)

```tsx
import { useInterwovenKit } from "@initia/interwovenkit-react";
import { bcs } from "@initia/initia.js";
import { MsgExecute } from "@initia/initia.proto/initia/move/v1/tx";

export function useGameActions() {
  const { initiaAddress, requestTxBlock } = useInterwovenKit();

  const mintShard = async (moduleAddress: string) => {
    if (!initiaAddress) return;

    const messages = [{
      typeUrl: "/initia.move.v1.MsgExecute",
      value: MsgExecute.fromPartial({
        sender: initiaAddress,
        moduleAddress,
        moduleName: "items",
        functionName: "mint_shards",
        args: [bcs.u64().serialize(1).toBytes()],
        typeArgs: [],
      }),
    }];

    return requestTxBlock({ messages });
  };

  return { mintShard };
}
```

### EVM Contract Execution (`requestTxBlock` flow)

```tsx
import { useInterwovenKit } from "@initia/interwovenkit-react";
import { encodeFunctionData } from "viem";
import { MsgCall } from "@initia/initia.proto/minievm/evm/v1/tx";

const ABI = [ /* ... */ ];

export function useBankActions(contractAddress: string) {
  const { initiaAddress, requestTxBlock } = useInterwovenKit();

  const deposit = async (amount: string) => {
    if (!initiaAddress) return;

    const data = encodeFunctionData({
      abi: ABI,
      functionName: "deposit",
    });

    const messages = [{
      typeUrl: "/minievm.evm.v1.MsgCall", 
      value: {
        sender: initiaAddress,
        contractAddr: contractAddress, // Must be hex (0x...)
        input: data.startsWith("0x") ? data : `0x${data}`, // Must have 0x prefix for simulation
        value: amount, // Amount in base units (string)
        accessList: [],
      },
    }];

    return requestTxBlock({ 
      chainId: "your-appchain-id", // Strongly recommended for appchains
      messages 
    });
  };

  return { deposit };
}
```

### Wasm Contract Execution (`requestTxBlock` flow)

```tsx
import { useInterwovenKit } from "@initia/interwovenkit-react";

export function useBoardActions(contractAddress: string) {
  const { initiaAddress, requestTxBlock } = useInterwovenKit();

  const postMessage = async (content: string) => {
    if (!initiaAddress) return;

    // MsgExecuteContract expects 'msg' as bytes (Uint8Array)
    const msg = new TextEncoder().encode(JSON.stringify({ post_message: { content } }));

    const messages = [{
      typeUrl: "/cosmwasm.wasm.v1.MsgExecuteContract",
      value: {
        sender: initiaAddress,
        contract: contractAddress,
        msg,
        funds: [],
      },
    }];

    return requestTxBlock({ 
      chainId: "your-appchain-id",
      messages 
    });
  };

  return { postMessage };
}
```

#### Pro Tip: EVM Dual-Address Requirements
When interacting with an EVM appchain:
1. **Querying (`eth_call`)**: Use the **hex address** (`0x...`) for the `from` parameter. You can convert a bech32 address using `AccAddress.toHex(address)`.
2. **Transacting (`MsgCall`)**: Use the **bech32 address** (`init1...`) for the `sender` field in the message payload. The `contractAddr` should still be **hex** (`0x...`).

- **Note**: When passing a raw object (not using `MsgCall.fromPartial`), you MUST use **camelCase** for the fields (e.g., `contractAddr`, `accessList`) and ensure **both** the address and input have the `0x` prefix to satisfy simulation requirements.

## Optional Advanced Path: Direct SDK Contract Calls

```tsx
import { RESTClient, bcs, AccAddress } from "@initia/initia.js";
import { MsgExecute } from "@initia/initia.proto/initia/move/v1/tx";

const rest = new RESTClient("http://localhost:1317", { chainId: "mygame-1" });

// Prefer querying resources directly for state
export async function queryInventory(moduleAddress: string, walletAddress: string) {
  const structTag = `${moduleAddress}::items::Inventory`;
  return rest.move.resource(walletAddress, structTag);
}

// CosmWasm query via REST
export async function queryWasm(contractAddress: string, queryMsg: any) {
  // Query must be base64 encoded because it's part of the REST URL path
  const queryData = Buffer.from(JSON.stringify(queryMsg)).toString("base64");
  return rest.wasm.smartContractState(contractAddress, queryData);
}

// Convert bech32 to hex for EVM calls
export function getHexAddress(address: string) {
  return address.startsWith("0x") ? address : AccAddress.toHex(address);
}
```

## Gotchas

- **EVM: Incorrect typeUrl**: For EVM contract calls via `requestTxBlock`, the `typeUrl` usually follows the pattern `/minievm.evm.v1.MsgCall` or `/initia.evm.v1.MsgCall`.
  - **Fix**: Check your appchain's module name (often `minievm` on rollups) or use `scripts/verify-appchain.sh` to see the module registry.

- **EVM: MsgCall Value Type**: The `value` field in `MsgCall` (for sending native tokens) MUST be a string representing the amount in base units (wei).
  - **Fix**: Use `parseEther(amount).toString()` to ensure it's a string.

- **Wasm: Query 400 Bad Request**: `smartContractState` expects the query to be a Base64-encoded string.
  - **Fix**: `const queryData = Buffer.from(JSON.stringify(query)).toString("base64"); rest.wasm.smartContractState(addr, queryData);`

- **Wasm: Transaction "invalid payload"**: `MsgExecuteContract` expects the `msg` field as bytes (`Uint8Array`).
  - **Fix**: Use `new TextEncoder().encode(JSON.stringify(msg))` for the `msg` field.

- **Buffer is not defined**: Initia.js uses Node.js globals. Use `vite-plugin-node-polyfills` or manual global assignment.
- **Chain not found**: Ensure `customChain` is passed to `InterwovenKitProvider` and `defaultChainId` matches.
- **URL not found**: Ensure `rpc`, `rest`, AND `indexer` are present in `customChain.apis`.
- **LCDClient is not an export**: Use `RESTClient` instead.
- **View function 400/500 errors**: Ensure arguments are correctly typed strings (e.g., `address:init1...`) and parameters match Move signature exactly. Prefer `resource()` queries for simple state.
- **Unstyled Modal**: Ensure `styles.css` is imported AND `injectStyles(InterwovenKitStyles)` is called in `main.jsx`.

- **Error: must contain at least one message**: This often occurs if `requestTxBlock` is called without a `chainId` or with a `chainId` that the node doesn't recognize (e.g., trying to send an L2-only message to L1).
  - **Fix**: Ensure `InterwovenKitProvider` is configured with your `customChain` and `defaultChainId`. Also, explicitly pass `chainId` in the `requestTxBlock` options.
  - **Note**: When passing a raw object (not using `MsgCall.fromPartial`), ALWAYS use **camelCase** for the fields (e.g., `contractAddr`, `accessList`) to ensure correct processing by the InterwovenKit provider.

## Install Recovery

If dependency install was interrupted and subsequent installs fail unexpectedly, use the recovery commands in `troubleshooting.md` ("NPM install interrupted / dependency state corrupted").
