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
echo "Installing React and Vite dependencies..."
npm install vite @vitejs/plugin-react react react-dom --save-dev --quiet --no-progress > /dev/null

# Create Vite config
cat > vite.config.js <<EOF
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
EOF

# Create index.html
cat > index.html <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>$pkg_name</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

# Create main.jsx
cat > src/main.jsx <<EOF
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

# Create App.jsx
cat > src/App.jsx <<EOF
import React from 'react'

function App() {
  return (
    <div className="App">
      <h1>$pkg_name</h1>
      <p>Welcome to your new Initia appchain frontend!</p>
    </div>
  )
}

export default App
EOF

echo "Scaffolded React + Vite project at $target"
