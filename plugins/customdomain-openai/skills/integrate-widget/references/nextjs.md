# Next.js

App Router. Two files: a route handler that mints the token (server only) and a client component that opens the widget.

Set `CUSTOMDOMAIN_APP_ID` and `CUSTOMDOMAIN_API_KEY` in the host's environment settings (and in `.env.local`, which stays out of git). Neither name starts with `NEXT_PUBLIC_`, so Next.js never sends them to the browser.

## Install

```bash
npm install customdomain-js @customdomain/react
```

## Token route

`app/api/customdomain-token/route.ts`

```ts
// Runs on the server only. It holds the API key and returns a 15 minute token.
export async function POST(req: Request) {
  const user = await getSignedInUser(req); // replace with your own session lookup
  if (!user) return Response.json({ error: "unauthorized" }, { status: 401 });

  const { domain } = await req.json().catch(() => ({}));

  const res = await fetch("https://api.customdomain.ai/v1/tokens", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${process.env.CUSTOMDOMAIN_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      application_id: process.env.CUSTOMDOMAIN_APP_ID,
      end_user_ref: user.id,
      ...(typeof domain === "string" && domain ? { domain } : {}),
    }),
  });
  if (!res.ok) return Response.json({ error: "token_mint_failed" }, { status: 502 });

  const { token } = await res.json();
  return Response.json({ application_id: process.env.CUSTOMDOMAIN_APP_ID, token });
}
```

`getSignedInUser` stands for whatever your project already uses (its auth library or session cookie). Do not skip it.

## Button

`components/ConnectDomainButton.tsx`

```tsx
"use client";
import { useCustomdomain } from "@customdomain/react";

async function fetchToken(domain?: string) {
  const res = await fetch("/api/customdomain-token", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ domain }),
  });
  if (!res.ok) throw new Error("Could not get a widget token");
  return res.json() as Promise<{ application_id: string; token: string }>;
}

export function ConnectDomainButton({ userId }: { userId: string }) {
  const { open, ready } = useCustomdomain({
    applicationId: "", // filled in by open() below
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

Pass `userId` from a server component that already knows the signed-in user. It must be the same id the route sends as `end_user_ref`.

## Check

1. Sandbox application values in the env, `npm run dev`, sign in, click the button.
2. Connect `www.acme.test`. It goes live in about 15 seconds.
3. Search the build output (`.next/static`) for the key prefix; it must not appear.
