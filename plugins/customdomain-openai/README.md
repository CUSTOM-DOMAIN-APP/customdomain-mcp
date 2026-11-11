# CustomDomain™ for Codex and ChatGPT

The OpenAI packaging of the CustomDomain™ connector. It adds the hosted server and four skills that teach the
agent the safe order of calls.

## What it does

- Connect a domain or subdomain a person owns to their app, with the DNS records, HTTPS certificate and serving
  handled for them.
- Check whether a domain is live and diagnose one that is not.
- Set up email records and permanent redirects on a domain.

It does not buy domains and it does not manage the workspace (keys, webhooks, members). Use the console at
https://app.customdomain.ai or the full server (`https://mcp.customdomain.ai/mcp`) for those.

## Install in Codex

```
codex plugin marketplace add CUSTOM-DOMAIN-APP/customdomain-mcp
```

Then install `customdomain` from the marketplace and sign in when asked.

## Layout

| Path | Purpose |
|---|---|
| `.codex-plugin/plugin.json` | The manifest and the listing fields (`interface`) |
| `.mcp.json` | The remote server; sign in is OAuth with no secrets and no headers |
| `skills/` | `get-started`, `connect-a-domain`, `fix-a-domain`, `email-and-redirects` |
| `assets/` | Logo and composer icon |

Support: https://customdomain.ai/contact · Privacy: https://customdomain.ai/privacy · Terms: https://customdomain.ai/terms
