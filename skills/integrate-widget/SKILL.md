---
name: integrate-widget
description: "Add the CustomDomain™ connect widget to a web app so the app's own customers can connect their own domains. Use when someone asks to embed or install the widget, let customers bring their own domain, add custom domains to a SaaS product, mint a widget token, or wire customdomain-js or @customdomain/react into Next.js, React, Vue or plain JavaScript. Covers the server route that mints the token, opening the widget, the end user reference, locale, and trying it in the Sandbox first."
---

# Integrate the widget

The widget is a modal your customers use to connect a domain they own to your product. Two parts make it work:

1. A route on **your server** that asks CustomDomain™ for a short-lived widget token. The server holds the API key.
2. **Your front end**, which asks that route for a token and opens the widget with it.

The browser never holds an API key. It holds only the token, which lasts 15 minutes.

Docs for this page: https://docs.customdomain.ai/docs/widget-sdk/installation-and-embed

## Before you write code

- Ask which framework the project uses, then read the matching reference: [Next.js](references/nextjs.md), [React](references/react.md), [Vue](references/vue.md) or [plain JavaScript](references/plain-js.md).
- Find how the project knows who is signed in. The token route must only answer signed-in users.
- The person needs two values from the console at https://app.customdomain.ai: the **application ID** (the console's Widget page, public) and an **API key** (the API & SDK page; it is shown once when created).
- The code reads them from environment variables named `CUSTOMDOMAIN_APP_ID` and `CUSTOMDOMAIN_API_KEY`. Add the names to the project's env example file with no values. Never ask the person to paste the key into the chat, never write it into a file the repository tracks, and never give it a public prefix such as `NEXT_PUBLIC_`. The person puts the value in their own secret store.

## Steps

### 1. Try it in the Sandbox first

Use a Sandbox application (the docs call it test mode) before any real customer. It connects made up `.test` names on a simulated DNS, needs no card, and is never billed. Create one in the console (**Try test mode** in the application switcher), then set `CUSTOMDOMAIN_APP_ID` and `CUSTOMDOMAIN_API_KEY` to that application's own values. Guide: https://docs.customdomain.ai/docs/guides/test-mode

### 2. Add the token route on the server

Send `POST https://api.customdomain.ai/v1/tokens` with the API key as the bearer:

```
Authorization: Bearer <CUSTOMDOMAIN_API_KEY>
Content-Type: application/json

{ "application_id": "<CUSTOMDOMAIN_APP_ID>", "end_user_ref": "<your customer id>", "domain": "<optional host>" }
```

- The answer holds `token` and `expires_in` (900 seconds).
- Return `{ application_id, token }` to your own front end. Never return the key.
- `end_user_ref` is your own id for the signed-in customer. See "End user reference" below.
- `domain` is optional. It binds the token to one host, so the token can only act on that host.
- If the mint call fails, answer your front end with a plain error. Do not forward the raw upstream body.
- Token docs and the full error table: https://docs.customdomain.ai/docs/authentication/widget-tokens

An application created over the API (not in the console) mints with its `client_secret` in the body instead of the bearer. Do not put an API key in `client_secret`. Details are on the widget tokens page above.

### 3. Open the widget in the browser

Install `customdomain-js` (or `@customdomain/react` for React hooks), or load the hosted script. Then:

```js
customdomain.open({
  applicationId,        // from your route
  token,                // from your route
  getToken: async () => (await fetchToken()).token, // a fresh token if setup runs long
  endUserRef: user.id,  // same id the server used
  domain: "app.customer.com", // optional prefill
  locale: "en",         // optional
  onSuccess: (r) => {}, // the domain is live
  onError: (err) => {}, // { code, message, details?, status? }
});
```

`open()` returns `{ close }`. Only one modal shows at a time.

### 4. Handle what comes back

- `onSuccess` gives `{ jobId, domain, setupType, provider }` when the domain is live. Update your own records and tell the customer.
- `onClose` tells you the `lastStatus` when the modal closes, including when the customer leaves early.
- `onError` receives a `CustomDomainError`. Its `status` is the HTTP status of the answer it came from. A `status` of 429 or any 5xx is safe to retry after a moment. Any other 4xx gives the same answer until the token, domain or records change.
- `onFallback` fires once per domain when the customer is sent to the records to add by hand.
- To learn about a connection when the browser is closed, use webhooks (the `setup-webhooks` skill).

### 5. Check it in the Sandbox

Open the widget and connect `www.acme.test`. In test mode it reaches live about 15 seconds later and `onSuccess` fires. `timeout.acme.test` fails after 60 seconds and `conflict.acme.test` stays pending, so you can build the screens for both. A name that does not end in `.test` is refused in the Sandbox.

When it works, use the `go-live-checklist` skill.

## End user reference

`endUserRef` (and `end_user_ref` on the server) is your own id for the customer, such as your user or account id. CustomDomain™ stores it on the connection, shows it in the console, and sends it with every webhook as `user_id`.

- Use one stable id per customer. Do not start it with `console:`; that prefix is reserved.
- Mint the token with the same `end_user_ref` that you pass as `endUserRef` to `open()`. A token for another customer, or one with no `end_user_ref`, is refused when it touches a connection that names a customer.
- Take the id from your signed-in session on the server. Never trust one the browser sends.

## Locale

`locale` is an optional string that sets the widget's language. The docs do not list the accepted values here, so link https://docs.customdomain.ai/docs/widget-sdk/reference instead of guessing one. Leave it out to use the default.

## Options worth knowing

- `wwwRedirect: true` connects a root domain and `www`, and redirects the root to `www`. Unset lets the customer choose.
- `container: "#panel"` shows the widget inside your own layout instead of a modal.
- `whiteLabel` changes colors, logo and screens. Reference: https://docs.customdomain.ai/docs/widget-sdk/reference
- `removeDomain()` and `mode: "reconnect"` exist for removing a domain and renewing access. See the reference.

## Rules

- The API key stays on the server. Check the built front end bundle does not contain it.
- Do not call `POST /v1/tokens` from the browser.
- Do not put a real customer domain into the Sandbox, or a `.test` name into a live application.
- Keep package versions as the project's package manager resolves them; do not copy a version number from this file.
