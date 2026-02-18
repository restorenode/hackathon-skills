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

// Inject styles for the widget
injectStyles(InterwovenKitStyles);

const queryClient = new QueryClient();
const wagmiConfig = createConfig({
  chains: [mainnet],
  transports: { [mainnet.id]: http() },
});

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <InterwovenKitProvider {...TESTNET}>
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
    borderRadius: '16px',
    boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1)',
    padding: '40px',
    width: '100%',
    maxWidth: '480px',
    textAlign: 'center'
  };

  const buttonStyle = {
    backgroundColor: '#3b82f6',
    color: 'white',
    border: 'none',
    padding: '12px 24px',
    borderRadius: '8px',
    fontSize: '16px',
    fontWeight: '600',
    cursor: 'pointer',
    transition: 'all 0.2s ease',
    boxShadow: '0 4px 6px -1px rgba(59, 130, 246, 0.5)'
  };

  const secondaryButtonStyle = {
    ...buttonStyle,
    backgroundColor: '#f1f5f9',
    color: '#475569',
    boxShadow: 'none',
    marginTop: '10px'
  };

  const addressBadgeStyle = {
    backgroundColor: '#f1f5f9',
    padding: '8px 12px',
    borderRadius: '6px',
    fontSize: '14px',
    fontFamily: 'monospace',
    color: '#64748b',
    marginBottom: '20px',
    wordBreak: 'break-all'
  };

  return (
    <div style={containerStyle}>
      <div style={cardStyle}>
        <h1 style={{ fontSize: '32px', marginBottom: '8px', fontWeight: '800', color: '#0f172a' }}>
          $pkg_name
        </h1>
        <p style={{ color: '#64748b', marginBottom: '32px' }}>
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
            <div style={addressBadgeStyle}>{initiaAddress}</div>
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
