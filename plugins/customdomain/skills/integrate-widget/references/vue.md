# Vue 3

Vue code runs in the browser, so the token route lives on your backend (Node, Python, Go, PHP, Ruby, or a Nuxt server route). The call it makes is the same one `nextjs.md` shows: `POST https://api.customdomain.ai/v1/tokens` with `Authorization: Bearer` and the key from `CUSTOMDOMAIN_API_KEY`, a body of `application_id` (from `CUSTOMDOMAIN_APP_ID`) and `end_user_ref`, and an answer that holds `token`. Your route checks the user is signed in, then returns `{ application_id, token }`.

In Nuxt, put that code in a server route (`server/api/`) and read the two variables from the server runtime config, never from `public` config.

## Install

```bash
npm install customdomain-js
```

## Component

`ConnectDomain.vue`

```vue
<script setup>
import { customdomain } from "customdomain-js";

const props = defineProps({ userId: { type: String, required: true } });

async function fetchToken(domain) {
  const res = await fetch("/api/customdomain-token", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ domain }),
  });
  if (!res.ok) throw new Error("Could not get a widget token");
  return res.json(); // { application_id, token }
}

async function connect() {
  const { application_id, token } = await fetchToken();
  customdomain.open({
    applicationId: application_id,
    token,
    getToken: async (ctx) => (await fetchToken(ctx?.domain)).token,
    endUserRef: props.userId,
    onSuccess: ({ domain }) => console.log(`${domain} is live`),
    onError: (err) => console.error(err.code, err.status),
  });
}
</script>

<template>
  <button @click="connect">Connect your domain</button>
</template>
```

Import `customdomain-js` in code that runs in the browser. If the framework renders on the server, keep the `open()` call inside the click handler, as above.

## Check

1. Use the Sandbox application's values. Start the app and the backend, sign in, click the button.
2. Connect `www.acme.test`; it goes live in about 15 seconds and `onSuccess` fires.
3. Look in the built JavaScript for the key prefix; it must not be there.
