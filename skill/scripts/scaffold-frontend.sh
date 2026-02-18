#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scaffold-frontend.sh <target-dir>

Example:
  scaffold-frontend.sh ./my-react-app
USAGE
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

target="$1"
pkg_name=$(basename "$target")

mkdir -p "$target/src"

# Initialize npm non-interactively
cd "$target"
npm init -y > /dev/null

# Set type to module and add vite scripts
jq '. + {type: "module", scripts: {dev: "vite", build: "vite build", preview: "vite preview"}}' package.json > package.json.tmp && mv package.json.tmp package.json

# Install dependencies silently
echo "Installing React, Vite, and Initia dependencies..."
npm install vite @vitejs/plugin-react react react-dom --save-dev --quiet --no-progress > /dev/null
npm install @initia/interwovenkit-react wagmi viem @tanstack/react-query @initia/initia.js @initia/initia.proto --quiet --no-progress > /dev/null
npm install --save-dev vite-plugin-node-polyfills --quiet --no-progress > /dev/null
npm install buffer util --quiet --no-progress > /dev/null

# Create Vite config with polyfills
cat > vite.config.js <<EOF
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { nodePolyfills } from 'vite-plugin-node-polyfills'

export default defineConfig({
  plugins: [
    react(),
    nodePolyfills({
      globals: {
        Buffer: true,
        process: true,
      },
    }),
  ],
})
EOF

# Create index.css
cat > src/index.css <<EOF
body {
  margin: 0;
  padding: 0;
  background-color: #fafafa;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

* {
  box-sizing: border-box;
}
EOF

# Create index.html
cat > index.html <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$pkg_name</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

# Create main.jsx with Provider setup
cat > src/main.jsx <<EOF
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
import './index.css'

// Inject styles for the widget
injectStyles(InterwovenKitStyles);

const queryClient = new QueryClient();
const wagmiConfig = createConfig({
  chains: [mainnet],
  transports: { [mainnet.id]: http() },
});

/* 
// Example: Custom Appchain Configuration
// Replace placeholders with values from 'minitia.config.json' or 'scripts/verify-appchain.sh'
const customChain = {
  chain_id: 'your-appchain-id',
  chain_name: 'your-appchain',
  pretty_name: 'My Appchain',
  network_type: 'testnet',
  bech32_prefix: 'init',
  logo_URIs: {
    png: 'https://raw.githubusercontent.com/initia-labs/initia-registry/main/testnets/initia/images/initia.png',
    svg: 'https://raw.githubusercontent.com/initia-labs/initia-registry/main/testnets/initia/images/initia.svg',
  },
  apis: {
    rpc: [{ address: 'http://localhost:26657' }],
    rest: [{ address: 'http://localhost:1317' }],
    indexer: [{ address: 'http://localhost:8080' }],
  },
  fees: {
    fee_tokens: [{ denom: 'umin', fixed_min_gas_price: 0 }],
  },
  metadata: {
    minitia: { type: 'miniwasm' }, // Use 'minievm' or 'minimove' if applicable
  },
}
*/

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <InterwovenKitProvider 
          {...TESTNET}
          /* defaultChainId="your-appchain-id" */
          /* customChain={customChain} */
        >
          <App />
        </InterwovenKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  </React.StrictMode>,
)
EOF

# Create App.jsx
cat > src/App.jsx <<EOF
import React from 'react'
import { useInterwovenKit } from "@initia/interwovenkit-react";

function App() {
  const { initiaAddress, openConnect, openWallet } = useInterwovenKit();

  const shortenAddress = (addr) => {
    if (!addr) return "";
    return \`\${addr.slice(0, 8)}...\${addr.slice(-4)}\`;
  };

  const containerStyle = {
    fontFamily: '"Inter", system-ui, -apple-system, sans-serif',
    minHeight: '100vh',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#f8fafc',
    color: '#1e293b',
    padding: '20px'
  };

  const cardStyle = {
    backgroundColor: '#ffffff',
    borderRadius: '24px',
    boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1)',
    padding: '48px',
    width: '100%',
    maxWidth: '480px',
    textAlign: 'center',
    border: '1px solid #f1f5f9'
  };

  const buttonStyle = {
    backgroundColor: '#3b82f6',
    color: 'white',
    border: 'none',
    padding: '14px 28px',
    borderRadius: '12px',
    fontSize: '16px',
    fontWeight: '700',
    cursor: 'pointer',
    transition: 'all 0.2s ease',
    boxShadow: '0 4px 6px -1px rgba(59, 130, 246, 0.5)',
    width: '100%'
  };

  const secondaryButtonStyle = {
    ...buttonStyle,
    backgroundColor: '#f1f5f9',
    color: '#475569',
    boxShadow: 'none',
    marginTop: '12px'
  };

  const addressBadgeStyle = {
    backgroundColor: '#f8fafc',
    padding: '12px',
    borderRadius: '12px',
    fontSize: '14px',
    fontFamily: 'monospace',
    fontWeight: '600',
    color: '#64748b',
    marginBottom: '24px',
    border: '1px solid #e2e8f0'
  };

  return (
    <div style={containerStyle}>
      <div style={cardStyle}>
        <h1 style={{ 
          fontSize: '40px', 
          marginBottom: '12px', 
          fontWeight: '900', 
          color: '#0f172a',
          letterSpacing: '-1px',
          textTransform: 'uppercase'
        }}>
          $pkg_name
        </h1>
        <p style={{ color: '#64748b', marginBottom: '40px', fontSize: '16px', lineHeight: '1.5' }}>
          Welcome to your new Initia appchain frontend!
        </p>
        
        {!initiaAddress ? (
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <button 
              onClick={openConnect} 
              style={buttonStyle}
            >
              Connect Wallet
            </button>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <div style={addressBadgeStyle}>{shortenAddress(initiaAddress)}</div>
            <button 
              onClick={openWallet} 
              style={secondaryButtonStyle}
            >
              Open Wallet
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

export default App
EOF

echo "Scaffolded React + Vite project at $target"
