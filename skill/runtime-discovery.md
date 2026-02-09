# Runtime Discovery

Use this flow whenever VM, `chain_id`, or endpoint values are unknown.

## Commands

```bash
weave rollup list
weave rollup log -n 20
test -f ~/.minitia/artifacts/config.json && cat ~/.minitia/artifacts/config.json
```

## How To Use Results

1. Identify VM (`evm`, `move`, `wasm`) from rollup metadata/config.
2. Extract `chain_id`, RPC/REST/JSON-RPC endpoints, and denom defaults.
3. Confirm with the user before wiring frontend or deployment config values.

Use a context-specific confirmation:
- Frontend task: "I found a local rollup config/runtime. Should I use this rollup for frontend integration?"
- Non-frontend task: "I found local runtime values (VM, chain ID, endpoints). Should I use these for this task?"
