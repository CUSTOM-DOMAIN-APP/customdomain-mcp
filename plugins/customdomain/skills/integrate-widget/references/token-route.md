# The server route that mints a widget token

The browser never holds an API key or a client secret. Your server trades one for a widget token and returns only the token. Add your own sign in check to the route: only signed in users of your product may reach it.

## The call

`POST https://api.customdomain.ai/v1/tokens` with `Authorization: Bearer <CUSTOMDOMAIN_API_KEY>`.

| Body field | Use |
| --- | --- |
| `application_id` | Required. The public id from the console's Widget page. |
| `end_user_ref` | Your own id for the signed in customer. |
| `domain` | Optional. Binds the token to one hostname. |
| `domains` | Optional. Several hostnames for one multi domain flow. |
| `end_user_email` | Optional. |
| `client_secret` | Only for an application made over the API, and only instead of the bearer key. Never put an API key here. |

The key needs the `tokens:mint` permission. The answer holds `token` and `expires_in`. Leave `scope` at its default. Never request a wider scope, and never send a token with a wider scope to a browser.

## Environment

- `CUSTOMDOMAIN_API_KEY`: server only. Created with `npx @customdomain/cli init`, or on the console's API & SDK page (shown once).
- `CUSTOMDOMAIN_APP_ID`: public id of the application, from the console's Widget page.

## Node (any framework)

```ts
export async function mintWidgetToken(opts: { domain?: string; endUserRef: string }) {
  const res = await fetch("https://api.customdomain.ai/v1/tokens", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${process.env.CUSTOMDOMAIN_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      application_id: process.env.CUSTOMDOMAIN_APP_ID,
      domain: opts.domain,
      end_user_ref: opts.endUserRef,
    }),
  });
  if (!res.ok) throw new Error(`token mint failed: ${res.status}`);
  const body = (await res.json()) as { token: string };
  return body.token;
}
```

`domain` is only ever a name to bind to. Check it is a hostname first, for example with a pattern such as `/^(?=.{1,253}$)([a-z0-9-]+\.)+[a-z]{2,}$/i`, and drop it when it does not match. The widget can ask `getToken` for a token for the domain a customer typed: it passes a request with `domain` and a `reason` (`bind` or `expired`), so read the domain from that and mint again.

## Failures

- `401`: the key or secret is wrong, expired or for another workspace.
- `403`: the key may not mint, or the application is not yours.
- `429`: wait `Retry-After` seconds. Retry only `429` and `5xx` responses.

Log the status, not the response body or the key.
