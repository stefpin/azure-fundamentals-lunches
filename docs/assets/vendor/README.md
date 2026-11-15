# Third-party files: MSAL Browser

The two JavaScript files in this folder come unchanged from the npm package
[`@azure/msal-browser`](https://www.npmjs.com/package/@azure/msal-browser) **5.29.1** — the Microsoft
Authentication Library for JavaScript, MIT licence (see `LICENSE-msal-browser.txt`).

| File | Copied from the package | Global |
|---|---|---|
| `msal-browser.min.js` | `lib/msal-browser.min.js` | `msal` |
| `msal-redirect-bridge.min.js` | `lib/redirect-bridge/msal-redirect-bridge.min.js` | `msalRedirectBridge` |

The Lunch Tutor panel (`docs/assets/tutor.js`) loads the first file only when a learner opens the panel; the sign-in
return page (`docs/auth/redirect.html`) loads the second. Microsoft recommends serving both from the site itself, not
from a third-party CDN.

To update: copy both files from the same newer release, change the version above, and test a sign-in with
`?tutor=preview` before announcing it. `tools/build_site.py` never changes this folder.
