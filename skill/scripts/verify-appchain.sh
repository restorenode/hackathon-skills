#!/usr/bin/env bash
set -euo pipefail

CHAIN_ID=""
RPC_URL="http://localhost:26657"
KEY_NAME=""
CHECK_GAS_STATION=false
ADDRESS=""

usage() {
  cat <<'USAGE'
Usage: verify-appchain.sh [--chain-id <chain-id>] [--rpc-url <url>] [--key-name <key-name>] [--gas-station] [--address <addr>]

Options:
  --chain-id     Chain ID (auto-detected from ~/.minitia/artifacts/config.json if omitted)
  --rpc-url      RPC URL (default: http://localhost:26657)
  --key-name     Check balance for a local key name
  --address      Check balance for a specific address
  --gas-station  Check Gas Station status and balances

Examples:
  verify-appchain.sh
  verify-appchain.sh --gas-station
  verify-appchain.sh --chain-id myrollup-1 --key-name mykey
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --chain-id)
      CHAIN_ID="$2"
      shift 2
      ;;
    --rpc-url)
      RPC_URL="$2"
      shift 2
      ;;
    --key-name)
      KEY_NAME="$2"
      shift 2
      ;;
    --address)
      ADDRESS="$2"
      shift 2
      ;;
    --gas-station)
      CHECK_GAS_STATION=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Auto-detect Chain ID if not provided
if [[ -z "$CHAIN_ID" && -f "$HOME/.minitia/artifacts/config.json" ]]; then
  CHAIN_ID=$(jq -r '.l2_config.chain_id' "$HOME/.minitia/artifacts/config.json")
  echo "Auto-detected Chain ID: $CHAIN_ID"
fi

for cmd in minitiad jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command not found: $cmd"
    exit 1
  fi
done

status_json="$(minitiad status --node "$RPC_URL" 2>/dev/null || echo "{}")"
if [[ "$status_json" == "{}" ]]; then
  echo "Error: Could not connect to RPC at $RPC_URL. Is the appchain running?"
  exit 1
fi

height="$(printf "%s\n" "$status_json" | jq -r '.SyncInfo.latest_block_height // .sync_info.latest_block_height')"
network="$(printf "%s\n" "$status_json" | jq -r '.NodeInfo.network // .node_info.network // empty')"

if [[ -z "$height" || "$height" == "null" ]]; then
  echo "Failed to read latest block height"
  exit 1
fi

if ! [[ "$height" =~ ^[0-9]+$ ]]; then
  echo "Unexpected latest block height: $height"
  exit 1
fi

if [[ "$height" -le 0 ]]; then
  echo "Appchain appears unhealthy (latest_block_height=$height)"
  exit 1
fi

if [[ -n "$CHAIN_ID" && -n "$network" && "$network" != "$CHAIN_ID" ]]; then
  echo "Chain ID mismatch: expected '$CHAIN_ID', got '$network'"
  exit 1
fi

echo "Appchain ($network) is producing blocks (latest_block_height=$height)"

if [[ -n "$KEY_NAME" ]]; then
  addr="$(minitiad keys show "$KEY_NAME" -a)"
  echo "Balance for key '$KEY_NAME' ($addr):"
  minitiad query bank balances "$addr" --node "$RPC_URL"
fi

if [[ -n "$ADDRESS" ]]; then
  echo "Balance for address $ADDRESS:"
  minitiad query bank balances "$ADDRESS" --node "$RPC_URL"
fi

if [ "$CHECK_GAS_STATION" = true ]; then
  if command -v weave >/dev/null 2>&1; then
    echo "--- Gas Station Status ---"
    weave gas-station show
    
    # Try to extract address and check L2 balance
    gs_addr=$(weave gas-station show | grep "Initia Address:" | awk '{print $4}')
    if [[ -n "$gs_addr" ]]; then
      echo "Gas Station L2 Balance ($gs_addr):"
      minitiad query bank balances "$gs_addr" --node "$RPC_URL"
    fi
  else
    echo "weave CLI not found, skipping gas station check."
  fi
fi