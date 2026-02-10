#!/usr/bin/env bash

# Initia Hackathon Tool Installer
# Installs: jq, weave, initiad, minitiad (minimove)

set -e

# Versions
INITIAD_VERSION="v0.2.15"
WEAVE_VERSION="v0.3.3"
MINIMOVE_VERSION="v0.2.13"

# Paths
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[Initia Installer]${NC} $1"
}

error() {
    echo -e "${RED}[Error]${NC} $1"
}

# OS/Arch Detection
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux)
        OS_TYPE="linux"
        ;;
    Darwin)
        OS_TYPE="darwin"
        ;;
    *)
        error "Unsupported OS: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64)
        ARCH_TYPE="amd64"
        ;;
    arm64|aarch64)
        ARCH_TYPE="arm64"
        ;;
    *)
        error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

log "Detected system: $OS_TYPE/$ARCH_TYPE"
log "Installing tools to: $INSTALL_DIR"

# 1. Check Docker
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker Desktop (macOS) or Docker Engine (Linux) manually."
    error "  - macOS: https://docs.docker.com/desktop/install/mac-install/"
    error "  - Linux: https://docs.docker.com/engine/install/"
else
    log "Docker is installed."
fi

# 2. Install jq
if ! command -v jq &> /dev/null; then
    log "Installing jq..."
    if [[ "$OS_TYPE" == "darwin" ]]; then
        if command -v brew &> /dev/null; then
            brew install jq
        else
            error "Homebrew not found. Please install jq manually or install Homebrew."
        fi
    else
        # Try apt/yum/apk if possible, otherwise warn
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        else
            error "Please install 'jq' using your package manager (apt, yum, etc)."
        fi
    fi
else
    log "jq is already installed."
fi

# 3. Install Weave
log "Installing Weave ($WEAVE_VERSION)..."
WEAVE_URL="https://github.com/initia-labs/weave/releases/download/${WEAVE_VERSION}/weave-${WEAVE_VERSION}-${OS_TYPE}-${ARCH_TYPE}"
curl -L -o "$INSTALL_DIR/weave" "$WEAVE_URL"
chmod +x "$INSTALL_DIR/weave"

# 4. Install initiad
log "Installing initiad ($INITIAD_VERSION)..."
# Check if archived or binary
# Usually: https://github.com/initia-labs/initia/releases/download/v0.2.15/initia_v0.2.15_Darwin_arm64.tar.gz
# Need to verify naming convention.
# Naming is often: initia_v0.2.15_Darwin_arm64.tar.gz
# Let's assume tar.gz for initiad based on common Go releaser patterns.
# Correction: Search results implied binaries on release page.
# I will use a robust guess or fall back to error.
# Common: initia_v0.2.15_Linux_x86_64.tar.gz
# Capitalization of OS might matter (Darwin vs darwin). GoReleaser usually uses "Darwin".
OS_TITLE="$(tr '[:lower:]' '[:upper:]' <<< ${OS_TYPE:0:1})${OS_TYPE:1}"
INITIAD_ASSET="initia_${INITIAD_VERSION}_${OS_TITLE}_${ARCH_TYPE}.tar.gz"
INITIAD_URL="https://github.com/initia-labs/initia/releases/download/${INITIAD_VERSION}/${INITIAD_ASSET}"

log "Downloading $INITIAD_URL ..."
curl -L -o /tmp/initiad.tar.gz "$INITIAD_URL"
if tar -tzf /tmp/initiad.tar.gz &>/dev/null; then
    tar -xzf /tmp/initiad.tar.gz -C "$INSTALL_DIR" initiad
    rm /tmp/initiad.tar.gz
    chmod +x "$INSTALL_DIR/initiad"
else
    error "Failed to download/extract initiad. Please install manually."
fi

# 5. Install minitiad (minimove)
log "Installing minitiad (minimove $MINIMOVE_VERSION)..."
# Similar naming? https://github.com/initia-labs/minimove/releases/download/v0.2.13/minimove_v0.2.13_Darwin_arm64.tar.gz
MINIMOVE_ASSET="minimove_${MINIMOVE_VERSION}_${OS_TITLE}_${ARCH_TYPE}.tar.gz"
MINIMOVE_URL="https://github.com/initia-labs/minimove/releases/download/${MINIMOVE_VERSION}/${MINIMOVE_ASSET}"

log "Downloading $MINIMOVE_URL ..."
curl -L -o /tmp/minimove.tar.gz "$MINIMOVE_URL"
if tar -tzf /tmp/minimove.tar.gz &>/dev/null; then
    tar -xzf /tmp/minimove.tar.gz -C "$INSTALL_DIR" minimove
    mv "$INSTALL_DIR/minimove" "$INSTALL_DIR/minitiad"
    rm /tmp/minimove.tar.gz
    chmod +x "$INSTALL_DIR/minitiad"
else
    error "Failed to download/extract minimove. Please install manually."
fi

# Final PATH check
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    log "WARNING: $INSTALL_DIR is not in your PATH."
    log "Add it by running: export PATH=\$PATH:$INSTALL_DIR"
fi

log "Installation complete! Verifying..."
"$INSTALL_DIR/weave" version
"$INSTALL_DIR/initiad" version --long | head -n 1
"$INSTALL_DIR/minitiad" version --long | head -n 1

