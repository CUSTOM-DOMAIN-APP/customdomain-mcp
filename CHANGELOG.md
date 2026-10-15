# Changelog

Versions of the hosted [CustomDomain™ MCP server](https://customdomain.ai/mcp-server). One version number
describes the server everywhere it is reported: `serverInfo` in the `initialize` response,
[`/.well-known/agent/mcp.json`](https://mcp.customdomain.ai/.well-known/agent/mcp.json), the official MCP
registry entry `ai.customdomain/mcp`, and `server.json` in this repository. Each version has a `vX.Y.Z` tag
here and a [GitHub release](https://github.com/CUSTOM-DOMAIN-APP/customdomain-mcp/releases) whose notes are
its entry below.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### The server

- `connect-domain` says where the records point: the CustomDomain™ edge by default, or the application's own
  infrastructure when it routes domains there (a connect target). It no longer says the records always point at the
  edge. A connected domain keeps that routing when the application changes its target, until it is moved through
  `POST /v1/connections/{id}:retarget`. For an application on its own infrastructure, the link is never the
  one-click Domain Connect authorization, and a root domain its DNS provider cannot point at a hostname is refused
  with `apex_not_supported` when the application has no root addresses.

## [0.5.0] (2026-10-03)

Five tools, a scope of its own for removal, and the first registry version that links this repository. The server
has reported 0.5.0 since 2026-10-02; the registry entry `ai.customdomain/mcp` moves from 0.4.0 to 0.5.0 today.

### The server

- Five tools after the first twelve, seventeen in all: `check-certificate-status`, `diagnose-connection`,
  `check-billing-status` and `list-domain-orders` (scope `domains:read`), and `recheck-connection` (scope
  `domains:connect`, because a recheck can move a failed connection back into verification).
- `domains:disconnect` is a scope of its own and no longer part of `domains:connect`, so an owner approves removal
  separately. `disconnect-domain` requires `confirm`, the domain being removed; the control plane removes nothing on a
  mismatch. Grants approved before the scope existed do not carry it.
- `connect-domain` takes an optional `applicationId`. An API key may name any application of its account; an agent
  token and a client credentials token act only in their own.
- Text a third party can write that the tools pass on (observed DNS values, certificate errors) is bounded: a DNS
  value is cut at 256 characters and an error text at 600, and the cut is marked `[truncated]`.

### This repository

- `server.json` is version 0.5.0 and now carries `repository` and `title`. GitHub's MCP Registry lists a server only
  when its registry entry links a GitHub repository, and the 0.4.0 entry did not.
- The registry limits `description` to 100 characters, so `server.json` here carries the short description the
  registry shows. The longer text that was here for 0.4.0 could not be published.
- `TOOLS.md` documents the five new tools, `applicationId`, `confirm` and the four scopes. The README counts, the
  version and the tool list follow.

[0.5.0]: https://github.com/CUSTOM-DOMAIN-APP/customdomain-mcp/releases/tag/v0.5.0

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
