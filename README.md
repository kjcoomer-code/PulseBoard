# PulseBoard

PulseBoard is a lightweight local web app for combining Apple Fitness workout history with Oura recovery metrics so you can track training progress in one dashboard.

## What it includes

- Local PulseBoard user login with first-user account creation
- Server-managed session cookies
- Local password hashing and user storage in `pulseboard-users.json`
- Oura OAuth with refresh-token rotation
- Live Oura daily metrics, workouts, and sessions
- Apple workout JSON import

## Files

- `index.html`: app shell, login screen, and dashboard UI
- `app.js`: login flow, dashboard logic, and backend API calls
- `styles.css`: UI styling
- `server.ps1`: local web server, auth system, and Oura OAuth backend
- `oura-config.example.json`: starter config for your Oura OAuth app
- `.gitignore`: ignores local secrets, tokens, and local user storage

## Run it

```powershell
powershell -ExecutionPolicy Bypass -File .\server.ps1
```

Then open [http://localhost:8787](http://localhost:8787).

## First-time setup

1. Start the server.
2. Open the app in your browser.
3. Create the first local PulseBoard account on the login screen.
4. Sign in.
5. Connect Oura.
6. Sync live data.

## Oura config

Example `oura-config.json`:

```json
{
  "clientId": "YOUR_OURA_CLIENT_ID",
  "clientSecret": "YOUR_OURA_CLIENT_SECRET",
  "redirectUri": "http://localhost:8787/auth/oura/callback",
  "scopes": ["daily", "personal", "workout", "session"],
  "port": 8787,
  "apiBase": "https://api.ouraring.com"
}
```

## Security notes

- `oura-config.json` is ignored by git so the client secret stays local.
- `token-store.json` stores Oura tokens locally using Windows secure-string protection.
- `pulseboard-users.json` stores local PulseBoard accounts and password hashes.
- Sessions are managed by the local server and stored in memory while the server is running.
- `disconnect` deletes the local Oura token cache.

## Important note

If you previously connected Oura before adding new scopes such as `workout` or `session`, disconnect and reconnect Oura so those scopes are granted to the new token.
