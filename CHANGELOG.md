# Changelog

Versions of the hosted [CustomDomain™ MCP server](https://customdomain.ai/mcp-server). One version number
describes the server everywhere it is reported: `serverInfo` in the `initialize` response,
[`/.well-known/agent/mcp.json`](https://mcp.customdomain.ai/.well-known/agent/mcp.json), the official MCP
registry entry `ai.customdomain/mcp`, and `server.json` in this repository. Each version has a `vX.Y.Z` tag
here and a [GitHub release](https://github.com/CUSTOM-DOMAIN-APP/customdomain-mcp/releases) whose notes are
its entry below.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.4.0] (2026-09-26)

The first tagged release. It records the server that is live today; version 0.4.0 has been listed in the
official MCP registry since 2026-07-12. No earlier version was published to the registry or tagged here, so
there are no earlier entries.

### The server

- Endpoint `https://mcp.customdomain.ai/mcp`: JSON-RPC 2.0 over streamable HTTP, protocol revision
  `2025-06-18`. An unauthenticated call gets an RFC 9728 challenge naming
  `/.well-known/oauth-protected-resource`.
- Twelve tools: `search-domain-availability`, `generate-domain-suggestions`, `create-domain-order`,
  `connect-domain`, `check-connection-status`, `check-order-status`, `reapply-connection`,
  `disconnect-domain`, `discover-provider`, `forward-domain`, `add-email`, `list-connections`. No tool
  accepts a DNS record; record values come from server-side templates.
- Three bearer credentials: a console API key, a JWT from `POST /token` (client credentials, 15 minutes by
  default), or the `CLIENT_ID:CLIENT_SECRET` shortcut for `mcp-remote`.
- Paid registration is gated by a fail-closed purchase-authorization callback.

### This repository

- `server.json` (registry manifest, version 0.4.0), `glama.json` (Glama ownership claim), `TOOLS.md` (the
  tool contract) and the README.
- `TOOLS.md` and the README describe the current connection lifecycle: a manual connection never fails on
  its own (after 72 hours it stays `pending` with `setup_incomplete` and is re-checked every six hours), and
  `failed` means records a rail wrote never resolved within 24 hours, or a rail rejected the write.
- The `server.json` description here is newer than the one the registry shows for 0.4.0. A registry version
  is immutable, so the new description reaches the registry with the next version.

[0.4.0]: https://github.com/CUSTOM-DOMAIN-APP/customdomain-mcp/releases/tag/v0.4.0
