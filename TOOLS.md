# Tool reference

Every tool the CustomDomain MCP server advertises, with its arguments and the
shape of what comes back. The server is at `https://mcp.customdomain.ai/mcp`
(streamable HTTP, JSON-RPC 2.0). See the [README](README.md) for client setup and
authentication.

Ids and hostnames in the examples are placeholders. Field names, types and status
values are the real contract.

A tool call looks like this:

```bash
curl -X POST https://mcp.customdomain.ai/mcp \
  -H "Authorization: Bearer sk_live_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call",
       "params":{"name":"search-domain-availability",
                 "arguments":{"domain":"example.com"}}}'
```

Two conventions run through everything below.

**No tool accepts a DNS record.** Records are computed server-side from stored
templates and returned to you. `add-email` takes mail settings such as an MX host
and a DKIM selector; the template turns those into records. `forward-domain`
takes a redirect target. Neither takes a record.

**`connected: true` is the completion signal.** Status strings are informative;
the boolean is what you branch on.

---

## search-domain-availability

Check whether a domain can be registered, with live pricing.

| Argument | Type | Required |
| --- | --- | --- |
| `domain` | string | yes |

Returns `{ domain, available, price?, renewalPrice?, message? }`. Prices are in
the registrar's quote currency and are live, not cached.

```json
{ "domain": "example.com", "available": false, "message": "already registered" }
```

## generate-domain-suggestions

Available-to-register name ideas for a set of keywords.

| Argument | Type | Required | Notes |
| --- | --- | --- | --- |
| `keywords` | string | yes | Free-form, space separated |
| `limit` | integer | no | Default 5, floor 5, ceiling 20. A value below 5 is raised to 5. |

Returns `{ keywords, suggestions[], count, message }` where each suggestion is
`{ domain, price, renewalPrice, topPick? }`. Results are sorted cheapest first
and the first row is marked `topPick`. Only available domains are returned, so an
empty list means nothing matched, not that everything is taken.

This is deterministic, not a model. Candidates are keyword joins plus a small
fixed set of affixes (`get`, `try`, `use`, `my`, `...app`, `...hq`), expanded
across TLDs by the registrar search and filtered to what is actually available.
The same keywords always produce the same candidates. The call makes at most
eight upstream registrar searches, which bounds both latency and cost.

## create-domain-order

Start a registration through the resolved registrar. **This spends money.**

| Argument | Type | Required |
| --- | --- | --- |
| `domain` | string | yes |

Returns `{ success, domain, status, orderId?, jobId?, link?, message? }`. Which
optional fields you get depends on the rail: an enterprise or direct registrar
returns an `orderId`, a sharing registrar returns a checkout `link` plus a
`jobId` to poll. `success` is `false` when the status is one of `failed`,
`cancelled`, `rejected`, `error`, `expired` or `unavailable`.

The tool is fail closed in two places. The MCP server places an order only after
the integrator's purchase-authorization callback approves it, and if that
callback is not configured every purchase is denied. The control plane gates
registrar purchasing separately. Neither gate defaults to open. See
[Buying a domain](https://docs.customdomain.ai/docs/sell/buying-a-domain).

## check-order-status

Read an order's live status.

| Argument | Type | Required |
| --- | --- | --- |
| `orderId` | string | one of the two |
| `jobId` | string | one of the two |

Supply exactly one. The call reads the persisted sell-order ledger first, whose
statuses are `quoted`, `purchased`, `transferred` and `failed`. Sharing-registrar
orders ride the connection job store instead, so a `jobId` there returns a
connection status. An id that matches neither returns `{ orderId, status:
"error", message }` rather than a guess.

## connect-domain

Attach a domain the customer already owns and set it up to serve with automatic
HTTPS.

| Argument | Type | Required |
| --- | --- | --- |
| `domain` | string | yes |

Returns:

```json
{
  "success": true,
  "domain": "app.customer.com",
  "jobId": "con_...",
  "link": "https://app.customdomain.ai/app/domains/con_...",
  "already_connected": false,
  "managed": false,
  "records": [
    { "type": "CNAME", "host": "app.customer.com",
      "value": "edge.customdomain.ai", "ttl": 3600, "applied": false }
  ],
  "message": "..."
}
```

`records` is the authoritative desired record set: exactly what must exist at the
customer's DNS provider for the domain to go live. Relay it to the user rather
than sending them to a web panel. The control plane synthesizes the default edge
record before anything is applied, so the array is populated even on the first
call.

`link` is not always the same thing, which is the part integrators get wrong. It
is a one-click provider authorization only when the domain's DNS provider
supports that rail. Otherwise it opens the same records in the console for the
user to copy. The `message` field says which one you got. Call
`discover-provider` first if you want to know before you ask.

`already_connected: true` means the call resumed an existing connection instead
of creating one. `POST /v1/connections` is idempotent per application and domain,
so a repeat call is safe and returns the original connection. Tell the user
"already connected" rather than re-issuing setup instructions.

`managed: true` means the control plane holds a durable grant and can re-apply
the connection later without the user. It is always `false` on a fresh create,
because the grant is only stored once the user consents on the automatic rail.

## check-connection-status

Read a connection's live status and its records.

| Argument | Type | Required |
| --- | --- | --- |
| `jobId` | string | yes |

Returns `{ jobId, domain, status, connected, managed, records?, link?, message? }`.

`status` is `pending`, `propagating`, `live` or `failed`. Poll until `connected`
is `true`. The background poller runs about once a minute, so poll every 30 to 60
seconds; faster gains nothing. A `failed` connection carries `error_code` and
`error_message`: `propagation_timeout` when records never resolved, or
`setup_incomplete` when they were never added at all. Both clear automatically if
the connection later re-verifies, so `failed` does not mean start over.

The give-up windows differ: 24 hours in `propagating` on an automatic rail, 72
hours from `pending` on the manual path, because a human has to get to their DNS
provider. Full lifecycle at
[Connections](https://docs.customdomain.ai/docs/concepts/connections).

## discover-provider

Detect where a domain's DNS is hosted, which rails are available, and what would
go wrong. Read only; writes nothing.

| Argument | Type | Required |
| --- | --- | --- |
| `domain` | string | yes |

Returns:

| Field | Meaning |
| --- | --- |
| `subdomain`, `registrableDomain`, `publicSuffix` | The server's Public Suffix List split of the name. Adopt this boundary instead of deriving your own. `subdomain` is empty when the domain is the registrable apex. |
| `provider` | Detected authoritative DNS operator, which may differ from the registrar. Empty when undetectable. |
| `setupType` | `automatic`, `domainconnect`, `oauth` or `manual` |
| `supportsAutomatic`, `oauthAvailable`, `domainConnect`, `registered` | Booleans behind `setupType` |
| `recordConflicts[]` | `{ kind, host, type, existing, desired }` where `kind` is `value-mismatch`, `cname-collision`, `spf-merge` or `caa-blocks-letsencrypt` |
| `conflictTolerance`, `willFallbackToManual` | The provider's modeled automated-write threshold, and the server's prediction that current conflicts exceed it |
| `apexSupported`, `apexMessage` | Whether the provider can host a CNAME-like record at the zone root, and a verdict for this specific domain |

Three of these are pre-flight warnings you should surface before asking a user to
authorize anything.

A `caa-blocks-letsencrypt` conflict is a certificate problem, not a DNS-write
clash: the domain's CAA record would block issuance until Let's Encrypt is
authorized. It rides the same array but the control plane keeps it out of the
fallback count, and so should you.

`willFallbackToManual: true` means the one-click rail will quietly turn into
"here are some records, add them by hand" because there are more conflicts than
the provider will overwrite. Offer to clear the conflicts first.

`apexMessage` is non-empty exactly when the apply would refuse this record set,
usually because the provider cannot host what a root domain needs. Gate your
warning on the message, not on `apexSupported`: connecting a subdomain on an
apex-incapable provider is fine.

## reapply-connection

Recompute a managed connection's records from stored config and re-push them
through its stored grant. Use it to heal a domain that has drifted out of `live`.

| Argument | Type | Required |
| --- | --- | --- |
| `connectionId` | string | yes |

Returns `{ success, connectionId, domain?, status?, message? }`.

Only a connection with `managed: true` can be re-applied. Check that field on
`list-connections` or `check-connection-status` first, rather than firing a
state-changing call at every domain to find out which ones answer. A connection
without a stored grant is refused with `success: false` and
`error: "reapply_failed"`.

## disconnect-domain

Revert a managed connection's DNS through its stored grant, then delete the grant
and the connection.

| Argument | Type | Required |
| --- | --- | --- |
| `connectionId` | string | yes |

Returns `{ success, connectionId, status: "disconnected", domain?, message? }`.

This takes the domain offline. Confirm with the user before calling it.

## forward-domain

Set up a permanent 301 redirect from a domain to a destination.

| Argument | Type | Required | Notes |
| --- | --- | --- | --- |
| `target` | string | yes | Destination URL or host |
| `domain` | string | one of the two | Creates a new connection |
| `connectionId` | string | one of the two | Acts on an existing one |

Returns `{ success, serviceId: "redirect", connectionId, domain?, records?, link?, status?, already_connected, message? }`.
Poll `connectionId` with `check-connection-status`.

`target` becomes a template variable server-side. The redirect's record shapes
belong to the template, not to the caller.

## add-email

Configure a domain for a mail provider in one step: MX, SPF, DKIM and DMARC from
a server-side template.

| Argument | Type | Required | Notes |
| --- | --- | --- | --- |
| `domain` | string | one of the two | Creates a new connection |
| `connectionId` | string | one of the two | Acts on an existing one |
| `provider` | string | no | `google`, `microsoft365` or `zoho`. Fills the standard MX and SPF. |
| `mxHost` | string | see below | Mail host receiving inbound mail |
| `spfInclude` | string | see below | SPF include target |
| `dkimSelector` | string | see below | Your platform's DKIM selector |
| `dkimTarget` | string | see below | What the selector points at |
| `dmarcRua` | string | see below | DMARC aggregate report address |

At least one of the five settings must be present. Explicit values always beat
the `provider` preset, and DKIM is always per-domain, so it comes from you.
Passing `provider` alone works for `google` and `zoho`; `microsoft365` needs a
tenant-specific `mxHost` that no preset can supply. An unrecognized `provider`
value is rejected at the JSON-RPC layer.

Returns the same envelope as `forward-domain`, with `serviceId: "email-full"`.

## list-connections

Inventory the connections on the account.

| Argument | Type | Required |
| --- | --- | --- |
| `status` | string | no |

Returns `{ connections[], count }` where each row is
`{ connectionId, domain, status, connected, setupType?, managed }`.

`status` filters to one lifecycle state (`pending`, `propagating`, `live`,
`failed`). With a console API key this returns connections across the tenant's
applications, which is the portfolio view. It reads a single page at the control
plane's default limit, so filter by status rather than trying to page through a
large account.

The reconciliation loop this exists for: list with `status=failed` or
`status=propagating`, keep the rows with `managed: true`, call
`reapply-connection` on those, and hand the rest to a human, because a
non-managed connection can only be repaired at the customer's DNS provider.

---

## Errors

Bad input fails at the JSON-RPC layer with `-32602` and a message naming the
missing argument. An unknown tool name is `-32601`.

A call the control plane refused comes back as a normal tool result:

```json
{ "success": false, "error": "connect_failed", "message": "..." }
```

`error` is the control plane's code when it sent one, otherwise the tool's
fallback: `connect_failed`, `order_failed`, `reapply_failed`,
`disconnect_failed`, `forward_failed`, `add_email_failed`. Branch on `error`,
show `message`.
