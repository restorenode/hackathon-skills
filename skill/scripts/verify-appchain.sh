#!/usr/bin/env bash
set -euo pipefail

CHAIN_ID=""
RPC_URL="http://localhost:26657"
KEY_NAME=""

usage() {
  cat <<'USAGE'
Usage: verify-appchain.sh --chain-id <chain-id> [--rpc-url <url>] [--key-name <key-name>]

Examples:
  verify-appchain.sh --chain-id myrollup-1
  verify-appchain.sh --chain-id myrollup-1 --rpc-url http://localhost:26657 --key-name mykey
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

if [[ -z "$CHAIN_ID" ]]; then
  echo "Missing required --chain-id"
  usage
  exit 1
fi

for cmd in minitiad jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command not found: $cmd"
    exit 1
  fi
done

status_json="$(minitiad status --node "$RPC_URL")"
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

if [[ -n "$network" && "$network" != "$CHAIN_ID" ]]; then
  echo "Chain ID mismatch: expected '$CHAIN_ID', got '$network'"
  exit 1
fi

echo "Appchain is producing blocks (latest_block_height=$height)"

if [[ -n "$KEY_NAME" ]]; then
  addr="$(minitiad keys show "$KEY_NAME" -a)"
  echo "Genesis/account balance for $KEY_NAME ($addr):"
  minitiad query bank balances "$addr" --node "$RPC_URL"
fi
