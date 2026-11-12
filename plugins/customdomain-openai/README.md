# CustomDomain™ for Codex and ChatGPT

The OpenAI packaging of the CustomDomain™ connector. It adds the hosted server and four skills that teach the
agent the safe order of calls.

## What it does

For one person connecting a domain they own to their app:

- Connect a domain or subdomain to your app, with the DNS records, HTTPS certificate and serving handled for you.
- Check whether the domain is live and its certificate is valid, and diagnose one that is not.
- Set up email records and a permanent redirect on a domain.
- Move a domain's nameservers, and roll the move back.
- Use access you already saved for a DNS provider.

Buying domains, plans and workspace administration (keys, members, webhooks) happen in the CustomDomain™ console
at https://app.customdomain.ai, not here.

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

Support: https://customdomain.ai/contactus · Privacy: https://app.customdomain.ai/privacy · Terms: https://app.customdomain.ai/terms
