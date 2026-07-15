# Custom Domains MCP Server

A hosted Model Context Protocol (MCP) server for domains, maintained by [CustomDomain.ai](https://customdomain.ai). It gives AI agents in Claude, Cursor, ChatGPT and any other MCP client eleven tools to search domain availability, register domains, connect a customer's existing domain, configure email DNS, set up forwarding, and track verification and TLS status. DNS configuration, domain ownership verification and certificate issuance are handled by the CustomDomain.ai control plane, so agents call tools that express intent and never touch raw DNS records.

**Endpoint:** `https://mcp.customdomain.ai/mcp` (streamable HTTP, JSON-RPC 2.0)

If you are looking for a custom domains MCP server, a DNS MCP server, or a domain MCP for your agent stack, the hosted endpoint above is the supported path. Nothing to install, nothing to keep running.

## What it does

* Checks availability and real-time pricing for domains an agent wants to register
* Registers domains through the resolved registrar, with fail-closed purchase authorization
* Connects domains a customer already owns: provider detection, DNS records, ownership verification and TLS certificates, all applied server side
* Configures email DNS (MX, SPF, DKIM, DMARC) and permanent forwarding in single tool calls
* Reports live status for connection jobs and registration orders so agents can poll to completion

## Quickstart

Get an API key from the console: [https://app.customdomain.ai/signup](https://app.customdomain.ai/signup). Keys look like `sk_live_...` and are shown once. The free tier is enough to try everything below.

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

| Tool | Purpose |
| --- | --- |
| `search-domain-availability` | Check whether a domain can be registered, with live purchase and renewal pricing |
| `generate-domain-suggestions` | Return name ideas for a set of keywords that are actually available to register |
| `create-domain-order` | Start a registration through the resolved registrar |
| `check-order-status` | Read the live status of a registration order |
| `connect-domain` | Start a guided DNS configuration flow for a domain the customer already owns |
| `check-connection-status` | Read the live status of a connection job, from records written to certificate issued |
| `discover-provider` | Detect where a domain's DNS is hosted (read only) |
| `reapply-connection` | Re-apply a managed connection |
| `disconnect-domain` | Cleanly disconnect a managed connection |
| `forward-domain` | Set up a permanent redirect from a domain to a destination |
| `add-email` | Configure a domain for a mail provider in one step via server-side templates |

None of the tools accepts DNS records as input. Record values are computed by the control plane from vetted templates, which closes off prompt injection paths that end in arbitrary DNS writes. `create-domain-order` is fail closed: a paid order is placed only after the integrator's purchase authorization callback approves it.

## Authentication

`POST /mcp` accepts three bearer credentials:

* A console API key (`sk_live_...` or `sk_test_...`)
* A short-lived JWT from `POST /token` (OAuth client_credentials)
* The `mcp-remote` shortcut format `CLIENT_ID:CLIENT_SECRET`

Token exchange:

```bash
curl -X POST https://mcp.customdomain.ai/token \
  -u "APPLICATION_ID:CLIENT_SECRET" \
  -d "grant_type=client_credentials"
```

The MCP server never validates credentials itself; it forwards them to the control plane, which enforces the same application-scoped permissions as the REST API. Revoke the key in the console and the agent loses access immediately.

## Docs and links

* MCP reference: [https://app.customdomain.ai/docs](https://app.customdomain.ai/docs) (MCP section)
* Product site: [https://customdomain.ai](https://customdomain.ai)
* AI agent use cases: [https://customdomain.ai/for/ai-agents](https://customdomain.ai/for/ai-agents)
* Guide: [https://customdomain.ai/guides/connect-domains-with-ai-agents](https://customdomain.ai/guides/connect-domains-with-ai-agents)
* Pricing (free tier available): [https://customdomain.ai/pricing](https://customdomain.ai/pricing)

## License

MIT. See [LICENSE](LICENSE).

Maintained by [CustomDomain.ai](https://customdomain.ai).