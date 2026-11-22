---
name: find-a-domain
description: "Find an available domain name with live pricing using the CustomDomain™ MCP tools, from keywords or a name the person has in mind. Use when someone asks for domain ideas, whether a domain name is taken, or what a name costs. This skill never buys a domain."
---

# Find a domain

Use the `customdomain` MCP server. This skill only looks names up. It never buys one.

## Steps

1. **Ideas.** When the person has only a theme, call `generate-domain-suggestions` with space separated `keywords` and an optional `limit` from 5 to 20. It returns only available names, cheapest first, with `price` and `renewalPrice`, and marks one `topPick`. The list is deterministic, so the same keywords give the same ideas; an empty list means nothing matched.
2. **A specific name.** Call `search-domain-availability` with the domain. It returns `available`, `price` and `renewalPrice`. Pricing is live; quote it as returned and say it can change. Mention the renewal price when it differs from the first year.
3. **Show a short list.** Lead with available names and their prices.

## Buying

Buying a domain is not offered here. If the person wants to buy one, call no tool for it and say plainly that it is not something this connector does. Once they own a domain, use the `connect-a-domain` skill to put it in front of their app.
