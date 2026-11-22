# Plain JavaScript

For a page with no build step. You still need a route on your own server that mints the token; the page never calls CustomDomain™'s mint endpoint.

## Server route (Node, Express)

```js
// Runs on your server only.
app.post("/api/customdomain-token", async (req, res) => {
  const user = req.user; // replace with your own session check
  if (!user) return res.status(401).json({ error: "unauthorized" });

  const r = await fetch("https://api.customdomain.ai/v1/tokens", {
    method: "POST",
    headers: {
      Authorization: "Bearer " + process.env.CUSTOMDOMAIN_API_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      application_id: process.env.CUSTOMDOMAIN_APP_ID,
      end_user_ref: user.id,
    }),
  });
  if (!r.ok) return res.status(502).json({ error: "token_mint_failed" });

  const { token } = await r.json();
  res.json({ application_id: process.env.CUSTOMDOMAIN_APP_ID, token });
});
```

Any language works: the call is one HTTPS request with a bearer header and a JSON body. Keep both values in environment variables.

## Page

```html
<button id="connect">Connect your domain</button>
<script src="https://app.customdomain.ai/widget-assets/customdomain-sdk.js"></script>
<script>
  async function fetchToken() {
    const res = await fetch("/api/customdomain-token", { method: "POST" });
    if (!res.ok) throw new Error("Could not get a widget token");
    return res.json(); // { application_id, token }
  }

  document.getElementById("connect").addEventListener("click", async () => {
    const { application_id, token } = await fetchToken();
    customdomain.open({
      applicationId: application_id,
      token,
      getToken: async () => (await fetchToken()).token,
      endUserRef: "your-customer-id", // render the signed-in customer's id into the page from your server
      onSuccess: ({ domain }) => console.log(domain + " is live"),
      onError: (err) => console.error(err.code, err.status),
    });
  });
</script>
```

The hosted script attaches `window.customdomain`. With a bundler, install `customdomain-js` and `import { customdomain } from "customdomain-js"` instead.

## Check

1. Use the Sandbox application's values and serve the page from your server.
2. Connect `www.acme.test`; it goes live in about 15 seconds and `onSuccess` fires.
3. View the page source and network calls; the key must not appear anywhere.
