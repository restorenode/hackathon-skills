---
name: initia-frontend-kit
description: 'Provides context to build frontends that integrate with Initia, identifying correct React hooks and provider patterns.'
---

# Initia Frontend Kit Skill

This skill provides the necessary context to build frontends that integrate with Initia. It identifies the correct React hooks and provider patterns used in the `@initia/interwovenkit-react` library.

## Provider Setup

To use the Initia Frontend Kit, you need to set up several providers in your React application. The main provider is `InterwovenKitProvider`.

### Provider Structure

```tsx
import { PrivyProvider } from "@privy-io/react-auth";
import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { InterwovenKitProvider, PRIVY_APP_ID, TESTNET } from "@initia/interwovenkit-react";

const Providers = ({ children }) => {
  return (
    <PrivyProvider appId={PRIVY_APP_ID}>
      <QueryClientProvider client={queryClient}>
        <WagmiProvider config={wagmiConfig}>
          <InterwovenKitProvider
            {...(isTestnet ? TESTNET : {})}
            theme="dark"
          >
            {children}
          </InterwovenKitProvider>
        </WagmiProvider>
      </QueryClientProvider>
    </PrivyProvider>
  );
};
```

### Key Providers and Libraries

-   **`InterwovenKitProvider`**: The core provider from `@initia/interwovenkit-react`. It manages the connection to the Initia network and provides the context for the hooks.
-   **`PrivyProvider`**: From `@privy-io/react-auth`, used for authentication and wallet management.
-   **`WagmiProvider`**: A provider for interacting with Ethereum.
-   **`QueryClientProvider`**: From `@tanstack/react-query`, used for data fetching, caching, and mutations.

## Core Hooks

The primary hook for interacting with the Initia Frontend Kit is `useInterwovenKit`.

### `useInterwovenKit`

This hook provides access to the user's wallet, connection status, and functions for interacting with the Initia network.

**Properties:**

-   `address: string`: The user's wallet address.
-   `initiaAddress: string`: The user's Initia address.
-   `username: string`: The user's username.
-   `openWallet: () => void`: A function to open the wallet UI.
-   `openConnect: () => void`: A function to open the connection UI.
-   `requestTxBlock: (tx) => Promise<result>`: A function to request a transaction, which opens a modal for user confirmation.
-   `submitTxBlock: (tx) => Promise<result>`: A function to sign and submit a transaction directly, without a modal.
-   `estimateGas: (tx) => Promise<number>`: A function to estimate the gas required for a transaction.

## Usage Examples

### Wallet Connection

```tsx
import { useInterwovenKit } from "@initia/interwovenkit-react";
import { truncate } from "@initia/utils";

const Connection = () => {
  const { address, username, openWallet, openConnect } = useInterwovenKit();

  if (!address) {
    return <button onClick={openConnect}>Connect</button>;
  }

  return <button onClick={openWallet}>{truncate(username ?? address)}</button>;
};
```

### Sending a Transaction

```tsx
import { useMutation } from "@tanstack/react-query";
import { useInterwovenKit } from "@initia/interwovenkit-react";
import { MsgSend } from "cosmjs-types/cosmos/bank/v1beta1/tx";

const Send = () => {
  const { initiaAddress, requestTxBlock } = useInterwovenKit();

  const { mutate } = useMutation({
    mutationFn: async ({ recipient, amount, denom, memo }) => {
      const messages = [
        {
          typeUrl: "/cosmos.bank.v1beta1.MsgSend",
          value: MsgSend.fromPartial({
            fromAddress: initiaAddress,
            toAddress: recipient,
            amount: [{ amount, denom }],
          }),
        },
      ];
      
      const { transactionHash } = await requestTxBlock({ messages, memo });
      return transactionHash;
    },
  });

  // ... form handling ...
};
```
