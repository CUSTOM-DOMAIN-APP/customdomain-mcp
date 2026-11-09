---
name: find-a-domain
description: Find an available domain name with live pricing using the CustomDomain™ MCP tools, from keywords or a name the person has in mind, and handle a purchase request safely. Use when someone asks for domain ideas, whether a domain is taken, what a domain costs, or to buy or register one.
---

# Find a domain

Use the `customdomain` MCP server.

## Steps

1. **Ideas.** When the person has only a theme, call `generate-domain-suggestions` with space separated `keywords` and an optional `limit` from 5 to 20. It returns only available names, cheapest first, with `price` and `renewalPrice`, and marks one `topPick`. The list is deterministic, so the same keywords give the same ideas; an empty list means nothing matched.
2. **A specific name.** Call `search-domain-availability` with the domain. It returns `available`, `price` and `renewalPrice`. Pricing is live; quote it as returned and say it can change at checkout. Mention the renewal price when it differs from the first year.
3. **Show a short list.** Lead with available names and their prices.

## Buying

Buying spends money and cannot be undone here.

- Ask the person to confirm the exact domain and price first. Only after they say yes, call `create-domain-order` with `domain` and `confirm_domain` set to the same name they confirmed. Never fill `confirm_domain` on your own initiative, and never call it twice for one purchase.
- Never supply a buyer or contact details yourself. The domain is registered to the account of the person who signed in.
- The purchase counts against the monthly spend cap the person set when they granted `domains:purchase`. If they did not grant that scope, the call fails with `insufficient_scope`; tell them they can sign in again and grant it, or buy in the console.
- A successful call returns an `orderId`, or a checkout `link` with a `jobId`. Relay a `link` for the person to open; never open or complete it yourself.
- When `success` is `false` (for example `status: "rejected"` or `"buyer_required"`, or a spend cap reached), say what `error` and `message` report and do not retry. Offer the console at https://app.customdomain.ai instead (guide: https://docs.customdomain.ai/docs/sell/buying-a-domain).
- Follow an order with `check-order-status` using its `orderId` or `jobId`, and list past orders with `list-domain-orders`.

After a purchase completes, use the `connect-a-domain` skill to put it in front of the app.
