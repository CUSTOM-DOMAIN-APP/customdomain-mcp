# CustomDomain MCP Server

A hosted Model Context Protocol (MCP) server for domains, maintained by [CustomDomain.ai](https://customdomain.ai). It gives AI agents in Claude, Cursor, ChatGPT and any other MCP client twelve tools to search domain availability, register domains, connect a customer's existing domain, configure email DNS, set up forwarding, inventory the whole portfolio, and track connection and TLS status. DNS configuration and certificate issuance are handled by the CustomDomain.ai control plane, so agents call tools that express intent and never touch raw DNS records.

**Endpoint:** `https://mcp.customdomain.ai/mcp` (streamable HTTP, JSON-RPC 2.0)

There is nothing to install and nothing to keep running: point your MCP client at the hosted endpoint above.

The server is listed in the official MCP registry as [`ai.customdomain/mcp`](https://registry.modelcontextprotocol.io/v0/servers?search=ai.customdomain%2Fmcp). It identifies itself as `customdomain-mcp`, speaks protocol revision `2025-06-18`, and advertises only the `tools` capability.

## What it does

* Checks availability and real-time pricing for domains an agent wants to register
* Registers domains through the resolved registrar, with fail-closed purchase authorization
* Connects domains a customer already owns: provider detection, the authoritative record set, a one-click apply where the provider supports it, and TLS issued at the edge
* Configures email DNS (MX, SPF, DKIM, DMARC) and permanent forwarding in single tool calls
* Reports live status for connection jobs and registration orders so agents can poll to completion

There is no separate ownership-challenge step, and no tool asks for or checks a TXT verification record. Control of the domain is proven by the rail that writes the records: an OAuth authorization at the provider, a one-click setup apply, or a scoped API token. On the manual path the control plane simply waits for the records to appear in public DNS. See [Connections](https://docs.customdomain.ai/docs/concepts/connections) for the full lifecycle.

## Quickstart

Get an API key from the console: [https://app.customdomain.ai/signup](https://app.customdomain.ai/signup). Keys look like `sk_live_...` and are shown once, at creation. The free Starter plan (10 domain connections per year, metered as 1 per calendar month) covers every tool here except `create-domain-order`, which places a real paid registration with the registrar.

### Claude Code

```bash
claude mcp add --transport http customdomain https://mcp.customdomain.ai/mcp \
  --header "Authorization: Bearer sk_live_YOUR_KEY"
```

### Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "customdomain": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://mcp.customdomain.ai/mcp",
        "--header",
        "Authorization: Bearer sk_live_YOUR_KEY"
      ]
    }
  }
}
```

### Cursor

Add to `.cursor/mcp.json` (project or global):

```json
{
  "mcpServers": {
    "customdomain": {
      "url": "https://mcp.customdomain.ai/mcp",
      "headers": {
        "Authorization": "Bearer sk_live_YOUR_KEY"
      }
    }
  }
}
```

### ChatGPT (desktop)

ChatGPT supports remote MCP servers as connectors in developer mode. Enable developer mode in Settings, add a connector pointing at `https://mcp.customdomain.ai/mcp`, and supply your API key as the bearer credential. Connector availability varies by plan; check OpenAI's current documentation for the exact flow.

## Tools

Twelve tools, registered in a fixed order. Arguments and full response shapes are in [TOOLS.md](TOOLS.md).

| Tool | Arguments | Purpose |
| --- | --- | --- |
| `search-domain-availability` | `domain` | Check whether a domain can be registered, with live purchase and renewal pricing |
| `generate-domain-suggestions` | `keywords`, `limit?` | Return name ideas for a set of keywords that are actually available to register |
| `create-domain-order` | `domain` | Start a registration through the resolved registrar |
| `check-order-status` | `orderId` or `jobId` | Read the live status of a registration order |
| `connect-domain` | `domain` | Start a guided DNS configuration flow for a domain the customer already owns |
| `check-connection-status` | `jobId` | Read the live status of a connection job, from records written to certificate issued |
| `discover-provider` | `domain` | Detect where a domain's DNS is hosted, which rails are available, and what would conflict (read only) |
| `reapply-connection` | `connectionId` | Re-apply a managed connection from its stored grant |
| `disconnect-domain` | `connectionId` | Cleanly disconnect a managed connection |
| `forward-domain` | `target`, `domain?`, `connectionId?` | Set up a permanent redirect from a domain to a destination |
| `add-email` | `domain?`, `connectionId?`, `provider?`, `mxHost?`, `spfInclude?`, `dkimSelector?`, `dkimTarget?`, `dmarcRua?` | Configure a domain for a mail provider in one step via server-side templates |
| `list-connections` | `status?` | Inventory every connection on the account, optionally filtered by status, so an agent can reconcile a whole portfolio rather than only the job it started (read only) |

None of the tools accepts DNS records as input. Record values are computed by the control plane from vetted templates, which closes off prompt injection paths that end in arbitrary DNS writes. `create-domain-order` is fail closed: a paid order is placed only after the integrator's purchase authorization callback approves it.

## Authentication

`POST /mcp` accepts three bearer credentials:

* A console API key (`sk_live_...` or `sk_test_...`)
* A short-lived JWT from `POST /token` (OAuth client_credentials)
* The `mcp-remote` shortcut format `CLIENT_ID:CLIENT_SECRET`

Where each one comes from:

| Credential | Issued by | Scope |
| --- | --- | --- |
| API key `sk_live_` / `sk_test_` | The console, under an application (`POST /v1/applications/{id}/keys`). Shown once, stored only as a hash. | The whole tenant: every application, connection, webhook and billing record it owns. |
| `client_secret` | Returned once when the application is created. It is not an API key; its only job is minting JWTs. | One application. |
| JWT from `POST /token` | The token exchange below, from `application_id` + `client_secret`. Expires in an hour. | One application. |

`APPLICATION_ID` and `CLIENT_ID` are the same value under two names. The token route accepts either field name, so `mcp-remote`'s `CLIENT_ID:CLIENT_SECRET` shortcut and the Basic-auth exchange below take identical inputs.

```bash
curl -X POST https://mcp.customdomain.ai/token \
  -u "<APPLICATION_ID>:<CLIENT_SECRET>" \
  -d "grant_type=client_credentials"
# -> { "access_token": "eyJ...", "token_type": "Bearer", "expires_in": 3600 }
```

The console's MCP server page (Integrate, at `/app/mcp`, sign-in required) shows the endpoint, the token URL and copy-paste client configs.

The MCP server never validates credentials itself; it forwards them to the control plane, which enforces the same application-scoped permissions as the REST API. Revoke the key in the console and the agent loses access immediately. Prefer the JWT over an API key when an agent only needs to work on one application: a leaked `sk_live_` key carries the whole tenant.

See [Authentication](https://docs.customdomain.ai/docs/authentication/overview) for the credential model, and [Widget tokens](https://docs.customdomain.ai/docs/authentication/widget-tokens) for the same exchange against the REST API.

## Polling and terminal states

Connections move `pending` to `propagating` to `live`, with `failed` as the one terminal error. Key completion off the boolean `connected: true` rather than the status string; it is the signal that stays stable if the enum ever grows.

| Status | Meaning |
| --- | --- |
| `pending` | Created. Records are not yet written, or not yet observed in public DNS. |
| `propagating` | A rail wrote the records. The poller is checking them against public DNS by value. |
| `live` | Every desired record resolves to its intended value and the edge serves TLS for the host. |
| `failed` | The records never appeared inside the window. Carries `error_code` of `propagation_timeout` or `setup_incomplete`. |

A background poller re-checks `pending` and `propagating` connections about once a minute, so polling faster than that gains you nothing. Thirty to sixty seconds is a sensible interval. Typical time to `live` once the records are actually in place is a few minutes.

The give-up windows differ by path, and the difference matters when you write agent copy. A connection on an automatic rail is marked `failed` after 24 hours in `propagating`. A manual connection gets 72 hours from `pending`, because a human has to get to their DNS provider. Both `error_code` values clear automatically if the connection later re-verifies, so `failed` is recoverable and not a reason to tell a user to start over.

Order polling is a different surface. `check-order-status` reads the persisted sell-order ledger first, whose statuses are `quoted`, `purchased`, `transferred` and `failed`. Orders placed through a sharing registrar ride the connection job store instead, so the same call returns a connection status for those. An id that matches neither comes back as `status: "error"` with a message saying so, rather than a guess.

## Errors

Two shapes, and they mean different things.

A malformed or incomplete call fails at the JSON-RPC layer: `-32602` for invalid parameters (`"domain is required"`, `"orderId or jobId is required"`, `"unknown provider; use google, microsoft365, or zoho, or set mxHost/spfInclude manually"`), `-32601` for an unknown tool name, `-32700` for unparseable JSON. These are bugs in the caller.

A call that reached the control plane and was refused returns a normal tool result with `success: false`:

```json
{ "success": false, "error": "connect_failed", "message": "Domain already connected to another application" }
```

`error` carries the control plane's own code when it sent one, otherwise the tool's fallback: `connect_failed`, `order_failed`, `reapply_failed`, `disconnect_failed`, `forward_failed`, `add_email_failed`. `message` is the control plane's title and details joined, meant to be read by a person. Branch on `error`; show `message`.

Authentication is not decided here. The server forwards your bearer to the control plane and returns its verdict, so a bad or revoked credential fails on the first wrapped call. `GET /mcp` and unauthenticated `POST /mcp` both return `401`.

## Limits

There is no published per-request rate limit on the MCP endpoint today. Three limits are real and worth designing around:

* `generate-domain-suggestions` caps upstream registrar searches at eight per call, and returns at most 20 suggestions. The default and the floor are both 5, so a `limit` below 5 is raised to 5.
* `list-connections` reads a single page at the control plane's default limit. Filter by `status` rather than trying to page through a large portfolio.
* Domain connections are metered per UTC calendar month against the plan allowance. See [Pricing](https://customdomain.ai/pricing) and [Plans and quotas](https://docs.customdomain.ai/docs/billing/plans-and-quotas).

## Versioning

`server.json` declares `0.4.0`, which is the version published in the MCP registry. The hosted endpoint itself is unversioned: your client always reaches the deployed build, so a tool added upstream appears without any change on your side, and the twelve tools documented here are what the live server advertises today. Pin your integration to tool names and to the `connected` boolean, not to a version string. Changes that affect the tools are recorded in the [docs changelog](https://docs.customdomain.ai/docs/changelog).

## What this server does not do

Worth knowing before you build on it.

* **Automatic setup covers 25 of the 63 DNS providers catalogued** (17 by API token, 6 by OAuth, 2 provider-hosted one-click). For the other 38 the tools still work, but they return the records plus a console link and a human has to add them at their provider. Call `discover-provider` first: it tells you which case you are in, and it also returns the pre-flight advisories (existing record conflicts, a CAA record that would block certificate issuance, a provider that cannot host the record an apex domain needs) before you ask a user to authorize anything. The breakdown is published at [Providers](https://docs.customdomain.ai/docs/providers).
* **No tool writes DNS records you supply.** That is the security model, not a gap to be filled later. If you need arbitrary record writes, this is the wrong server.
* **An agent cannot finish a connection alone on the manual path.** The design is link-mediated on purpose: the agent returns a link and polls, and a human does the money step and, where there is no automatic rail, the DNS step.
* **Delegated agent tokens are not enabled yet.** The scope-enforced, short-lived token path for a human delegating access to an agent is built and tested but not live on the hosted service. Until it is, an agent acts with whatever credential you hand it. See [Agent access](https://docs.customdomain.ai/docs/agents/overview).
* **The server source is not in this repository.** This repo holds the registry manifest, this README and the tool reference. The server runs as a hosted service.

## Docs and links

* MCP reference: [https://docs.customdomain.ai/docs/mcp/overview](https://docs.customdomain.ai/docs/mcp/overview)
* Connection lifecycle: [https://docs.customdomain.ai/docs/concepts/connections](https://docs.customdomain.ai/docs/concepts/connections)
* Provider coverage: [https://docs.customdomain.ai/docs/providers](https://docs.customdomain.ai/docs/providers)
* Buying a domain: [https://docs.customdomain.ai/docs/sell/buying-a-domain](https://docs.customdomain.ai/docs/sell/buying-a-domain)
* Product site: [https://customdomain.ai](https://customdomain.ai)
* AI agent use cases: [https://customdomain.ai/for/ai-agents](https://customdomain.ai/for/ai-agents)
* Guide: [https://customdomain.ai/guides/connect-domains-with-ai-agents](https://customdomain.ai/guides/connect-domains-with-ai-agents)
* Pricing (free tier available): [https://customdomain.ai/pricing](https://customdomain.ai/pricing)

Related repositories in this org:

* [connect-domain-for-ai-agents](https://github.com/CUSTOM-DOMAIN-APP/connect-domain-for-ai-agents), the field guide for agent stacks
* [awesome-custom-domains](https://github.com/CUSTOM-DOMAIN-APP/awesome-custom-domains), a list of the alternatives, including the ones that are not us
* [docs](https://github.com/CUSTOM-DOMAIN-APP/docs), the source of [docs.customdomain.ai](https://docs.customdomain.ai/docs)

## License

MIT. See [LICENSE](LICENSE).

Maintained by [CustomDomain.ai](https://customdomain.ai). Questions: connect@customdomain.ai.
