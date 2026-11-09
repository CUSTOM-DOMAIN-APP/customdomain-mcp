# CustomDomain™ plugin

CustomDomain™ puts a customer's own domain in front of your app. This plugin connects Claude to the hosted CustomDomain™ MCP server so it can search for a domain, check live pricing, connect a domain the customer already owns, set up email or a redirect, and explain or repair a connection that is not live yet. DNS records and HTTPS certificates are handled by the service; Claude never asks anyone to paste a DNS record into a tool.

## What it adds

- **MCP server** `customdomain` at `https://mcp.customdomain.ai/mcp` (remote, streamable HTTP, OAuth sign in). Twenty tools, listed in [TOOLS.md](https://github.com/CUSTOM-DOMAIN-APP/customdomain-mcp/blob/main/TOOLS.md).
- **Skills** that teach Claude the safe order of calls:
  - `connect-a-domain`: discover the DNS provider, start the connection, relay the records or the one-click link, and wait until it is live.
  - `find-a-domain`: name ideas, availability and price, and a purchase only after the person says yes.
  - `fix-a-domain`: read what public DNS shows, recheck, re-apply, and read certificate and nameserver state.
  - `email-and-redirects`: mail records for Google, Microsoft 365 or Zoho, and permanent redirects.

## Sign in

The first tool call opens a CustomDomain™ sign in in your browser. You choose the workspace and the scopes to grant (`domains:read`, `domains:connect`, `domains:disconnect`, `domains:purchase`). You can revoke the grant at any time in the console at [app.customdomain.ai](https://app.customdomain.ai). No API key is stored in this plugin.

## Data it sends

The plugin itself contains no code; everything goes through the MCP server above, and only to `mcp.customdomain.ai`. Tool calls carry what the tool needs: domain names, connection ids, keywords for name ideas, a redirect target, and mail settings. Nothing else from your conversation or files is sent. See the privacy policy at [customdomain.ai/privacy](https://customdomain.ai/privacy).

## Safety

Changes that are hard to undo need the person's explicit yes, and the server enforces it: a purchase repeats the domain in `confirm_domain`, a disconnect names the domain in `confirm`, and a nameserver move or rollback sends `confirm: true`. The skills tell Claude to ask first and never to fill those values on its own.

## Install in Claude Code

```
/plugin marketplace add CUSTOM-DOMAIN-APP/customdomain-mcp
/plugin install customdomain@customdomain
```

## Links

- Docs: [docs.customdomain.ai/docs/mcp/overview](https://docs.customdomain.ai/docs/mcp/overview)
- Product page: [customdomain.ai/mcp-server](https://customdomain.ai/mcp-server)
- Console: [app.customdomain.ai](https://app.customdomain.ai)

## License

MIT. See [LICENSE](LICENSE).
