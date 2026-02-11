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
| Provider order | Query -> Wagmi -> InterwovenKit | Current connector-based path |
| Connector | `initiaPrivyWalletConnector` | Default connector in kit docs |
| SDK path | InterwovenKit first | Use direct SDK only when required |

## Quickstart

### React + Vite (TypeScript)

```bash
npm create vite@latest initia-frontend -- --template react-ts
cd initia-frontend
npm install
npm install @initia/interwovenkit-react wagmi viem @tanstack/react-query
```

### Next.js (TypeScript)

```bash
npx create-next-app@latest initia-frontend --ts
cd initia-frontend
npm install @initia/interwovenkit-react wagmi viem @tanstack/react-query
```

## Dependency Tiers

### Required

- `@initia/interwovenkit-react`
- `@tanstack/react-query`
- `wagmi`
- `viem`

### Optional (common)

- `@initia/utils` for helpers like address truncation.

### Advanced

- `@initia/initia.js` and `@initia/initia.proto` for direct LCD/protobuf workflows.
- `cosmjs-types` if explicit protobuf message constructors are needed.

## Version Alignment

Avoid hard-coded version matrices in this skill.

- Install latest compatible package versions unless the user asks to pin.
- Keep `@initia/interwovenkit-react`, `wagmi`, and `viem` aligned to peer dependency expectations.
- Verify local dependency tree after install:

```bash
npm ls @initia/interwovenkit-react wagmi viem @tanstack/react-query react react-dom
```

## Implementation Checklist

1. Install required dependencies only.
2. Set up providers in order: `QueryClientProvider` -> `WagmiProvider` -> `InterwovenKitProvider`.
3. Add wallet connect button with disconnected guard.
4. Add tx logic with null check for `initiaAddress`.
5. Keep network values aligned (config + chain id + wallet environment).
6. Verify provider structure with `scripts/check-provider-setup.sh`.

## Provider Setup (Current Baseline)

```tsx
import type { PropsWithChildren } from "react";
import { useEffect } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import {
  InterwovenKitProvider,
  TESTNET,
  initiaPrivyWalletConnector,
  injectStyles,
} from "@initia/interwovenkit-react";
import InterwovenKitStyles from "@initia/interwovenkit-react/styles.js";
import { createConfig, http, WagmiProvider } from "wagmi";
import { defineChain } from "viem";

const queryClient = new QueryClient();

const evmRollup = defineChain({
  id: 42069,
  name: "Local MiniEVM Rollup",
  network: "local-minievm",
  nativeCurrency: { name: "Gas", symbol: "GAS", decimals: 18 },
  rpcUrls: { default: { http: ["http://127.0.0.1:8545"] } },
});

const wagmiConfig = createConfig({
  connectors: [initiaPrivyWalletConnector],
  chains: [evmRollup],
  transports: { [evmRollup.id]: http("http://127.0.0.1:8545") },
});

export function Providers({ children }: PropsWithChildren) {
  useEffect(() => {
    injectStyles(InterwovenKitStyles);
  }, []);

  return (
    <QueryClientProvider client={queryClient}>
      <WagmiProvider config={wagmiConfig}>
        <InterwovenKitProvider
          {...TESTNET}
          defaultChainId={TESTNET.defaultChainId}
          theme="dark"
        >
          {children}
        </InterwovenKitProvider>
      </WagmiProvider>
    </QueryClientProvider>
  );
}
```

Replace the placeholder EVM chain id/RPC URL with values from your rollup runtime.

## Custom Chain IDs Not In Initia Registry

InterwovenKit supports non-registry chains via `customChain` on `InterwovenKitProvider`.

Important behavior:

- `customChain` is prepended to registry results and overrides same `chain_id`.
- `defaultChainId` must match the chain you want active.
- For EVM integrations, `defaultChainId` is the rollup chain ID string (for example `"minievm-2"`), not the numeric EVM chain ID.
- If omitted and chain is not in registry/profile sources, runtime can fail with `Chain not found: <CHAIN_ID>`.

Custom chain example:

```tsx
import type { Chain } from "@initia/initia-registry-types";
import { InterwovenKitProvider, TESTNET } from "@initia/interwovenkit-react";

const customChain: Chain = {
  chain_id: "my-rollup-1",
  chain_name: "my-rollup",
  pretty_name: "My Rollup",
  network_type: "testnet",
  bech32_prefix: "init",
  fees: {
    fee_tokens: [{ denom: "GAS", fixed_min_gas_price: 0.015 }],
  },
  apis: {
    rpc: [{ address: "http://127.0.0.1:26657" }],
    rest: [{ address: "http://127.0.0.1:1317" }],
    indexer: [{ address: "http://127.0.0.1:8050" }],
    "json-rpc": [{ address: "http://127.0.0.1:8545" }],
  },
  metadata: {
    minitia: { type: "minievm" },
  },
};

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <InterwovenKitProvider
      {...TESTNET}
      customChain={customChain}
      defaultChainId={customChain.chain_id}
    >
      {children}
    </InterwovenKitProvider>
  );
}
```

## Wallet Button Pattern

```tsx
import { useInterwovenKit } from "@initia/interwovenkit-react";

function shortenAddress(value: string) {
  if (value.length < 14) return value;
  return `${value.slice(0, 8)}...${value.slice(-6)}`;
}

export function WalletButton() {
  const { address, username, openWallet, openConnect } = useInterwovenKit();

  if (!address) return <button onClick={openConnect}>Connect</button>;
  return <button onClick={openWallet}>{username ?? shortenAddress(address)}</button>;
}
```

## Transaction Patterns

### Bank Send (Default `requestTxBlock` flow)

```tsx
import { useMutation } from "@tanstack/react-query";
import { useInterwovenKit } from "@initia/interwovenkit-react";

export function useSendTx() {
  const { initiaAddress, requestTxBlock } = useInterwovenKit();

  return useMutation({
    mutationFn: async ({ recipient, amount, denom, memo }: {
      recipient: string; amount: string; denom: string; memo?: string;
    }) => {
      if (!initiaAddress) throw new Error("Wallet not connected");

      const messages = [{
        typeUrl: "/cosmos.bank.v1beta1.MsgSend",
        value: {
          fromAddress: initiaAddress,
          toAddress: recipient,
          amount: [{ amount, denom }],
        },
      }];

      const { transactionHash } = await requestTxBlock({ messages, memo });
      return transactionHash;
    },
  });
}
```

### EVM Contract Call on `minievm` Chain

```tsx
import { useMutation } from "@tanstack/react-query";
import { encodeFunctionData, parseAbi } from "viem";
import { useInterwovenKit } from "@initia/interwovenkit-react";

export function useCallEvmContract() {
  const { initiaAddress, requestTxBlock } = useInterwovenKit();

  return useMutation({
    mutationFn: async () => {
      if (!initiaAddress) throw new Error("Wallet not connected");

      const input = encodeFunctionData({
        abi: parseAbi(["function mint(address to, uint256 amount)"]),
        functionName: "mint",
        args: ["0xRecipientAddress", 1n],
      });

      const messages = [{
        typeUrl: "/minievm.evm.v1.MsgCall",
        value: {
          sender: initiaAddress,
          contractAddr: "0xContractAddress",
          input,
          value: "0",
          accessList: [],
          authList: [],
        },
      }];

      return requestTxBlock({ chainId: "<MINIEVM_CHAIN_ID>", messages });
    },
  });
}
```

## Optional Advanced Path: Direct SDK Contract Calls

```tsx
import { LCDClient, bcs } from "@initia/initia.js";
import { MsgExecute } from "@initia/initia.proto/initia/move/v1/tx";

const lcd = new LCDClient({ URL: "<LCD_URL>", chainID: "<CHAIN_ID>" });

export async function queryInventory(walletAddress: string) {
  return lcd.move.viewFunction("<MODULE_ADDRESS>", "items", "view_inventory", { addr: walletAddress });
}

export function buildMintMsg(sender: string, moduleAddress: string, amount: number) {
  return {
    typeUrl: "/initia.move.v1.MsgExecute",
    value: MsgExecute.fromPartial({
      sender,
      moduleAddress,
      moduleName: "items",
      functionName: "mint_shard",
      typeArgs: [],
      args: [bcs.u64().serialize(amount).toBytes()],
    }),
  };
}
```

## Native Features & Advanced Hooks

The `useInterwovenKit()` hook provides several native Initia features:

### Auto-Sign (Session Keys)
```tsx
const { autoSign } = useInterwovenKit();

// Enable for a chain
await autoSign.enable(chainId);

// Check status
const isEnabled = autoSign.isEnabledByChain[chainId];
```

### Built-in Drawers
```tsx
const { openBridge, openDeposit, openWithdraw } = useInterwovenKit();

// Open the standard bridge UI
openBridge();

// Open deposit for a specific asset
openDeposit({ denom: "uinit" });
```

## Indexer Query Patterns (Rollytics)

Every appchain has a built-in indexer available at `chain.indexerUrl`.

### Get Account Transactions
`GET ${indexerUrl}/indexer/tx/v1/txs/by_account/${address}?limit=10`

### Get Account NFTs
`GET ${indexerUrl}/indexer/nft/v1/tokens/by_account/${address}`

### Get Collection Details
`GET ${indexerUrl}/indexer/nft/v1/collections/${collection_addr}`

## Gotchas

- Chain mismatch will fail at runtime:
  - Do not mix `TESTNET` config with mainnet `defaultChainId` like `interwoven-1`.
  - Prefer `defaultChainId={TESTNET.defaultChainId}` when using `TESTNET`.
- Provider order mismatch breaks wallet hooks:
  - Baseline order is `QueryClientProvider` -> `WagmiProvider` -> `InterwovenKitProvider`.
- `initiaAddress` can be undefined until connected; always guard before sending tx.
- `requestTxBlock` message type must match chain type:
  - `"/cosmos.bank.v1beta1.MsgSend"` for bank sends
  - `"/minievm.evm.v1.MsgCall"` for EVM contract calls

Sanity check provider setup:

```bash
scripts/check-provider-setup.sh --mode interwovenkit <providers-file.tsx>
```

## Install Recovery

If dependency install was interrupted and subsequent installs fail unexpectedly, use the recovery commands in `troubleshooting.md` ("NPM install interrupted / dependency state corrupted").
