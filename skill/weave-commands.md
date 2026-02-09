# Weave Command Reference

## Preflight

```bash
go version
weave version
which lz4 jq minitiad curl
```

## Gas Station

```bash
weave gas-station setup
weave gas-station show
```

## Rollup Lifecycle

```bash
weave rollup launch --with-config ~/.weave/launch_config.json --vm <evm|move|wasm>
weave rollup start -d
weave rollup stop
weave rollup restart
weave rollup list
weave rollup log -n 100
```

## OPinit

```bash
weave opinit init executor
weave opinit start executor -d
weave opinit init challenger
weave opinit start challenger -d
weave opinit log executor
weave opinit log challenger
```

## Relayer

```bash
weave relayer init
```

## Health Checks

```bash
weave rollup log -n 20
curl http://localhost:26657/status
scripts/verify-appchain.sh --chain-id <CHAIN_ID> --rpc-url <RPC_URL>
```

## Common Paths

- `~/.weave/launch_config.json`
- `~/.minitia/`
- `~/.opinit/`
