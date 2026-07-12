# Vector local MCP

Offline MCP for **July / April / Vector Scripts** work.

| Server | Role |
|--------|------|
| `vector-lua-engine` (GitBook) | Live official docs search |
| **`vector-local`** (this) | `API.md` + Havoc/Fallen dumps |

## Tools

- `search_vector_api` / `get_api_section`
- `search_game_dump` / `list_dump_scripts` / `read_dump_file`
- `havoc_reference` / `vector_mcp_info`

## Cursor config

Add to `%USERPROFILE%\.cursor\mcp.json`:

```json
"vector-local": {
  "command": "node",
  "args": [
    "C:/Users/Cunza/Desktop/Projects/Vector Scripts/July/tools/vector-mcp/server.mjs"
  ]
}
```

Restart Cursor MCP / reload window after editing.

## Limits

Cannot control a live Vector process — Vector has no agent IPC. Use GitBook MCP + this for docs/dump context only.
