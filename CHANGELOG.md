# Changelog

Versions of the hosted [CustomDomain™ MCP server](https://customdomain.ai/mcp-server). One version number
describes the server everywhere it is reported: `serverInfo` in the `initialize` response,
[`/.well-known/agent/mcp.json`](https://mcp.customdomain.ai/.well-known/agent/mcp.json), the official MCP
registry entry `ai.customdomain/mcp`, and `server.json` in this repository. Each version has a `vX.Y.Z` tag
here and a [GitHub release](https://github.com/CUSTOM-DOMAIN-APP/customdomain-mcp/releases) whose notes are
its entry below.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.6.0] (2026-10-20)

Three nameserver tools, twenty in all, and a purchase that names its domain twice. The server reports 0.6.0
since the product release merged on 2026-10-20. The details below were checked against the product source at that
release and against `/.well-known/agent/mcp.json` on 2026-10-21, which lists version 0.6.0 and twenty tools.

### The server

- Three tools after the first seventeen, twenty in all, for moving a connected domain's nameservers to the
  application's DNS host so its records are hosted and kept correct from then on:
  - `check-nameserver-status` (scope `domains:read`) reads the move: its `state` (`pending`, `copying`,
    `needs_review`, `needs_dnssec_off`, `waiting_ds`, `setting`, `propagating`, `active`, `failed`,
    `rolled_back`), the registrar, the old, new and observed nameservers, what it waits on, the `nextStep` for a
    person, how the records were copied (`copySource`, `copyWarnings`) and the ways back. `done` is `true` once
    it is active, failed or rolled back.
  - `migrate-nameservers` (scope `domains:connect`) starts or resumes the move. The domain's records are copied
    first, mail included, and DNSSEC is turned off first when it is on. The nameservers change through a
    connected registrar account (`providerAccountId`), the person's own sign-in in the cloud browser, or the
    person at the registrar (`path`: `api`, `agent` or `manual`). A copy read from public DNS waits in
    `needs_review` until the call comes back with `copyReviewed: true`.
  - `rollback-nameservers` (scope `domains:connect`) moves them back, to the old nameservers (`target:
    "previous"`) or to the registrar's own DNS (`target: "registrar_default"`); without a target it goes where
    `rollbackDefault` says.
  - Both changes require `confirm: true`; without it the call fails with `-32602` and changes nothing.
  - A delegated agent token cannot choose where the nameservers go: `target` and `nameservers` from one are
    refused with `-32602` (and with `target_not_allowed` at the control plane), and the application's setting
    decides. Only an API key or the application's client credentials may name `managed`, or `custom` with 2 to
    13 nameservers.
  - The fallback error code for all three is `nameservers_failed`.
- `create-domain-order` requires `confirm_domain`, the same domain repeated as the person confirmed the
  purchase. A missing or different one fails with `-32602` ("Purchase not confirmed") and orders nothing. Its
  annotations are now destructive and not idempotent (they were state changing and idempotent), because a
  purchase cannot be undone from here and every call is another purchase.
- `connect-domain` says where the records point: the CustomDomain™ edge by default, or the application's own
  infrastructure when it routes domains there (a connect target). It no longer says the records always point at the
  edge. A connected domain keeps that routing when the application changes its target, until it is moved through
  `POST /v1/connections/{id}:retarget`. For an application on its own infrastructure, the link is never the
  one-click Domain Connect authorization, and a root domain its DNS provider cannot point at a hostname is refused
  with `apex_not_supported` when the application has no root addresses. This was live before the version number
  changed, and was listed under Unreleased here until now.
- `/mcp` checks the `Origin` header, as the Streamable HTTP transport requires. A browser request from an origin
  that is neither the server's own nor one in the new `MCP_ALLOWED_ORIGINS` gets HTTP `403` before
  authentication, with a JSON-RPC error `-32000` and no `id`. A listed origin gets CORS headers, and its preflight
  is answered before authentication. A request with no `Origin`, which is every MCP client that is not a browser,
  is not affected.
- `-insecure` (`MCP_INSECURE=1`) now refuses to start unless the server listens on a loopback address. It was
  already refused on a production host.
- The server's instructions tell an agent the nameserver rules: ask first, send `confirm: true`, never a registrar
  key, never a target with an agent token, and poll until `done`.
- Built with Go 1.26.

### On the hosted service

- `create-domain-order` is still refused: no purchase authorization callback is configured, so a confirmed call
  answers `status: "rejected"`. Buy in the console.
- `MCP_ALLOWED_ORIGINS` is unset, so a browser-based client is refused with `403`.

### This repository

- `server.json` is version 0.6.0. Its description is now the product's own ("search, register, connect DNS, and
  issue HTTPS over MCP"), which drops the "verify ownership" the 0.5.0 entry could not correct, and it carries
  the product's `_meta` list of the twenty tools and their scopes. It keeps `title`, `repository` and the
  `icons` added after 0.5.0 was published, so 0.6.0 is the first registry version with icons.
- `TOOLS.md` covers all twenty tools: the three nameserver tools, `confirm_domain`, the new annotations, the
  `Origin` refusal and `nameservers_failed`.
- The README describes 0.6.0: the tool count and list, the scopes, the confirmations, the service modules
  (`nameservers.go`, `origin.go`), `MCP_ALLOWED_ORIGINS` and the loopback rule for `MCP_INSECURE`, Go 1.26, the
  test count (196 tests in 26 files) and two more known limitations.

## [0.5.0] (2026-10-03)

Five tools, a scope of its own for removal, and the first registry version that links this repository. The server
has reported 0.5.0 since 2026-10-02; the registry entry `ai.customdomain/mcp` moved from 0.4.0 to 0.5.0 on
2026-10-03. The details below were checked against the production source and `/.well-known/agent/mcp.json` on
2026-10-14.

### The server

- Five tools after the first twelve, seventeen in all: `check-certificate-status` (issuer, expiry, days left,
  failing renewals), `diagnose-connection` (record by record: found, missing or mismatch, and why),
  `check-billing-status` (whether the workspace may connect new domains, the plan and this month's usage) and
  `list-domain-orders` (purchases, newest first), all scope `domains:read`, and `recheck-connection` (scope
  `domains:connect`, because a recheck can move a failed connection back into verification).
- Scopes. Every tool needs exactly one: `domains:read` for the ten read tools; `domains:connect` for
  `connect-domain`, `reapply-connection`, `forward-domain`, `add-email` and `recheck-connection`;
  `domains:disconnect` for `disconnect-domain`; `domains:purchase` for `create-domain-order`. A delegated agent
  token without the tool's scope gets JSON-RPC error `-32003` (`insufficient_scope`), naming the scope it
  needed. `domains:disconnect` is a scope of its own and no longer part of `domains:connect`, so an owner
  approves removal separately; grants approved before the scope existed do not carry it.
- `disconnect-domain` requires `confirm`: the domain being removed, as the person confirmed it. Without it the
  call fails with `-32602` and removes nothing. The control plane compares it with the connection's domain for
  delegated agent tokens (`confirmation_mismatch` otherwise, and nothing is removed); for other credentials it
  is not compared yet.
- Delegated agent access over OAuth. The protected resource metadata names `https://api.customdomain.ai` first
  as the authorization server: an agent registers itself (dynamic client registration), a person approves it,
  and it exchanges the code with PKCE (S256) for an ES256 token whose audience is
  `https://mcp.customdomain.ai/mcp`. The MCP server verifies that token locally against the control plane's
  JWKS and checks its scope on every call. A token for another audience is refused with `401 invalid_token`.
- Rate limiting: 5 tool calls a second with bursts of 20 per caller. The caller is the workspace for an agent
  token, the credential itself for an API key or a `/token` JWT, and the application for the
  `CLIENT_ID:CLIENT_SECRET` form. Over the limit a call answers `error: "rate_limited"` with
  `retryAfterSeconds` and never reaches the control plane.
- `connect-domain` takes an optional `applicationId` and returns `connectionId` (the same id as `jobId`) next
  to `already_connected`. An API key may name any application of its account; an agent token and a client
  credentials token act only in their own.
- One failure shape for every tool: `{ success: false, error, message, details? }` with `isError: true`. `error`
  is the control plane's code when it sent one (`billing_required`, `conflict`, `not_found` and so on), else the
  tool's fallback code. New fallback codes: `search_failed`, `suggest_failed`, `status_failed`, `list_failed`,
  `discover_failed`, `certificate_failed`, `recheck_failed`, `diagnose_failed`, `billing_failed`,
  `orders_failed` and `tool_failed`.
- `create-domain-order` answers `success: false` with status `buyer_required` when the purchase was authorized
  without a registrant email. A failed order also carries `error`.
- `discover-provider` returns the rail truth: `rails` (per rail `oauth`, `domainConnect`, `apiKey`, `manual`),
  `recommendedRail`, `endUserAutomatic`, `blockedReason` and `detectionError`. `setupType` and
  `supportsAutomatic` are removed; they only meant that an adapter exists.
- `check-connection-status` takes `connectionId` or `jobId`. A failed connection's reason is `errorCode` and
  `errorMessage` (camelCase), not `error_code` and `error_message` as `TOOLS.md` said.
- `list-connections` pages: it takes `cursor`, `limit` (up to 1000) and `status`, and a page that was cut says
  `truncated: true` and gives `nextCursor`. Rows carry `errorCode` for a failed connection.
- Text a third party can write that the tools pass on (observed DNS values, certificate errors) is bounded: a DNS
  value is cut at 256 characters and an error text at 600, and the cut is marked `[truncated]`.
- Server settings `MCP_AUTH_SERVER` (default `https://api.customdomain.ai`), `MCP_TENANT_RPS` (5) and
  `MCP_TENANT_BURST` (20). The usage recorder's key is now `JUSTEASY_MCP_USAGE_KEY` (the
  `CUSTOMDOMAIN_MCP_USAGE_KEY` form is read first); `MCP_USAGE_INGEST_KEY` still works as a fallback.

### On the hosted service

- `create-domain-order` is refused: no purchase authorization callback is configured, so every call answers
  `status: "rejected"`. Purchases are authorization-gated and off there; buy in the console.

### This repository

- `server.json` is version 0.5.0 and now carries `repository` and `title`. GitHub's MCP Registry lists a server only
  when its registry entry links a GitHub repository, and the 0.4.0 entry did not.
- The registry limits `description` to 100 characters, so `server.json` here carries the short description the
  registry shows, exactly as published for 0.5.0. The longer text that was here for 0.4.0 could not be published.
  That description still says "verify ownership", although there is no ownership challenge; a published registry
  version is immutable, so a corrected description ships with the next version.
- `TOOLS.md` covers all seventeen tools, their scopes and annotations, the error layers and the rate limit.
- The README describes 0.5.0: four credential types including agent tokens, client setup for Claude Code,
  Claude Desktop and Cursor, `cd_live_` / `cd_test_` keys (`sk_` keys are legacy), the provider census (178
  catalogued, 62 automatic: 55 by API token, 6 by OAuth, 1 by Domain Connect; 116 manual), the test count (182
  tests in 22 files), and no longer presents buying a domain through MCP as something that works today.

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

[0.6.0]: https://github.com/CUSTOM-DOMAIN-APP/customdomain-mcp/releases/tag/v0.6.0
[0.5.0]: https://github.com/CUSTOM-DOMAIN-APP/customdomain-mcp/releases/tag/v0.5.0
[0.4.0]: https://github.com/CUSTOM-DOMAIN-APP/customdomain-mcp/releases/tag/v0.4.0
