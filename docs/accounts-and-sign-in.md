# Accounts and sign-in

## With the API (normal)

- **Create account / sign in:** email and password (8 or more characters). Passwords are
  hashed with scrypt on the server; sessions are signed tokens valid for 7 days. A password
  change or reset signs out every device.
- **Forgot password:** the app asks for your email; if an account exists the API emails a
  6-digit code (valid 15 minutes, 5 attempts). The answer is the same whether or not the
  email has an account, so it can't be used to find accounts. Production needs
  `MAIL_WEBHOOK_URL` to send the email.
- **Profile:** name and phone are editable. Addresses and carts are per account.
- **Where the session is kept:** `shared_preferences` (browser storage on web). Sign out on a
  shared device.

## Without the API

If `DESIGNWEAR_API_URL` is empty the app still runs: accounts, carts and orders are stored
on this device only, with salted and hashed passwords. Password reset then sets a new
password for an account on the same device. This mode is for trying the app, not for users.

## Google sign-in

The button "Continue with Google" appears on the sign-in and create-account screens once it
is configured. Firebase is used **only** for this step.

How it works: the app signs in with Firebase Auth (Google provider), sends the Firebase ID
token to `POST /v1/auth/google`, and the API verifies it itself (signature against Google's
published keys, issuer, audience = your project, expiry, Google provider, verified email),
then issues its own session. The Firebase session is discarded.

Account matching:
- the same Google account always signs into the same DesignWear account;
- an existing password account with the same **verified** email is linked;
- a different Google account can't take over an email that is already linked.

A Google-only account has no password; it can set one with *Forgot password*.

### Setup

1. Firebase console: create a project and enable **Authentication → Google**. Add your web
   domain under *Authorized domains*.
2. Register the apps, with these ids: Android `com.vishwamai.designwear` (internal flavour
   `com.vishwamai.designwear.internal`), iOS and macOS `com.vishwamai.designwear`, and a web app.
3. Android: add the debug and release **SHA-1 and SHA-256** fingerprints. iOS: add the
   app's URL scheme (the `app-1-…-ios-…` value Firebase shows) to `Info.plist`.
4. Put the app values in `designwear/.env` (`FIREBASE_*`, see [configuration.md](configuration.md)).
   Set `FIREBASE_PROJECT_ID` on the API to the same project.
5. Until all that is filled in the button stays hidden. Linux and Windows don't support
   Firebase Auth, so it never appears there.

Firebase web configuration is public by design; the API checks every token, so a forged or
other-project token is rejected.
