---
name: go-live-checklist
description: "Checklist for taking a CustomDomain™ integration from the Sandbox (test mode) to real customers. Use when someone asks if the widget integration is ready for production, how to go live, what to check before launch, how to switch from test to live keys, or to review an integration before release."
---

# Go live checklist

Walk the integration through this list in order. For each item, look at the code or settings, say what you found, and fix or flag what is missing. Do not tick an item you did not check.

Docs: https://docs.customdomain.ai/docs/guides/test-mode#move-to-a-real-domain

## 1. The Sandbox run passed

- A `.test` name connected in a Sandbox application went live and `onSuccess` ran. A normal name such as `www.acme.test` goes live in about 15 seconds.
- The screens for the other two endings exist: `timeout.acme.test` fails after 60 seconds, and `conflict.acme.test` stays pending.
- Webhooks arrived at a test endpoint, with a good signature check (the `setup-webhooks` skill).

## 2. Live credentials

- The server uses the live application's ID and a live API key, set in the production host's secret store as `CUSTOMDOMAIN_APP_ID` and `CUSTOMDOMAIN_API_KEY`. The code does not change; only the values do.
- A key's prefix does not tell you the mode. Check the application: a Sandbox application carries `"sandbox": true`.
- Making a new key can need a card on file; the workspace's default key does not. See https://docs.customdomain.ai/docs/troubleshooting
- The old Sandbox values are removed from production settings. Nothing carries over from a Sandbox application, including its webhook endpoints.
- No key appears in the repository, the front end bundle, logs or error reports.

## 3. The token route

- It answers only signed-in users.
- It sends `end_user_ref` from the server's own session, and the front end passes the same id as `endUserRef`.
- It returns only `application_id` and `token`, and a plain error when minting fails.
- The front end passes `getToken`, so a customer who adds records slowly is not cut off after 15 minutes.
- It is not reachable from other sites in a way that lets anyone mint tokens for your application. Rate limit it.

## 4. Where domains point

Every connection's records point somewhere. Choose before the first customer connects: through the CustomDomain™ edge, or at your own infrastructure. With the edge, set the default origin; with neither set, the edge cannot serve the request. Serving through the edge needs a plan that includes it. Read https://docs.customdomain.ai/docs/connect-flow/routing and check the plan.

## 5. Webhooks on the live application

- A live endpoint is registered with the live key. It is a separate registration from the Sandbox one.
- The receiver verifies signatures, answers `2xx` within 15 seconds, and deduplicates on the event id.
- It skips events that carry `sandbox: true` and `user_id` values that start `console:`.
- A test delivery (`POST /v1/webhooks/{id}:test`) got a `2xx`.

## 6. Error handling in the product

- `onError` is handled. A `status` of 429 or any 5xx is retried after a moment; other errors show a plain message and are logged.
- A plan limit error (`PlanLimitError`) shows the customer something useful and tells your team.
- `onClose` with an unfinished `lastStatus` does not break the customer's page. They can come back to it.
- `onFallback` is handled or ignored on purpose.
- Your support page or message tells a customer what to do when a domain stays pending. Link https://docs.customdomain.ai/docs/troubleshooting for your team.

## 7. What your customers see

- Root domains: decide `wwwRedirect` (`true`, `false`, or unset to let the customer choose).
- Your own screen lists each customer's domains and their state, kept current from webhooks.
- Look and wording are set (`whiteLabel`, `applicationName`), and the widget was opened in the real product, not only in a test page.

## 8. Run one real connection

Connect one real domain you own through the live widget. Confirm it reaches live, the webhook arrived, and your screen updated. The console's go-live list on **Overview** marks a step done only when something proves it, so it is a second opinion on what is left. Guide: https://docs.customdomain.ai/docs/getting-started/console

## Report back

End with a short table: item, found, and what must change. Put anything you could not check under its own heading.
