# React

Use this for a React app with its own backend (Vite, Create React App, Remix and similar). Next.js has its own file: `nextjs.md`.

The token route lives on your backend, not in the React code. Any backend works; the call it makes is the same as in `nextjs.md`: `POST https://api.customdomain.ai/v1/tokens` with `Authorization: Bearer` and the key from `CUSTOMDOMAIN_API_KEY`, a body of `application_id` (from `CUSTOMDOMAIN_APP_ID`) and `end_user_ref`, and an answer that holds `token`. Your route returns `{ application_id, token }` to the browser and checks the user is signed in first.

## Install

```bash
npm install @customdomain/react customdomain-js react react-dom
```

## Hook

```jsx
import { useCustomdomain } from "@customdomain/react";

async function fetchToken(domain) {
  const res = await fetch("/api/customdomain-token", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ domain }),
  });
  if (!res.ok) throw new Error("Could not get a widget token");
  return res.json(); // { application_id, token }
}

export function ConnectDomainButton({ userId }) {
  const { open, ready } = useCustomdomain({
    applicationId: "",
    token: "",
    endUserRef: userId,
    getToken: async (ctx) => (await fetchToken(ctx?.domain)).token,
    onSuccess: ({ domain }) => console.log(`${domain} is live`),
    onError: (err) => console.error(err.code, err.status),
  });

  return (
    <button
      disabled={!ready}
      onClick={async () => {
        const { application_id, token } = await fetchToken();
        open({ applicationId: application_id, token });
      }}
    >
      Connect your domain
    </button>
  );
}
```

- `useCustomdomain` returns `{ open, purchaseDomain, removeDomain, close, ready }`. The hook closes the modal and removes its listeners when the component unmounts, and is safe to render on the server.
- `<CustomdomainConnect>` is a component that opens the flow when it mounts. Pass it a token your server already minted.
- Callbacks: `onSuccess`, `onClose`, `onStep`, `onStepChange`, `onDocClick`, `onRequestClose`, `onShared`, `onPurchase`, `onRemoved`. `onError`, `onFallback` and the other `open()` options pass through to the SDK.
- The `ctx` argument of `getToken` can carry the `domain` the customer typed. When it does, mint the new token for that `domain` and the same `end_user_ref`.

## Check

1. Use the Sandbox application's values. Start the app and the backend, sign in, click the button.
2. Connect `www.acme.test`; it goes live in about 15 seconds and `onSuccess` fires.
3. Look in the built JavaScript for the key prefix; it must not be there.
