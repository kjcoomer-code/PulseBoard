# PulseBoard

PulseBoard is a lightweight local web app for combining Apple Fitness workout history with Oura recovery metrics so you can track training progress in one dashboard.

## What changed

This version now includes a real local Oura OAuth scaffold:

- A PowerShell backend in `server.ps1`
- Authorization code flow with refresh-token rotation
- Local encrypted token storage tied to the current Windows user profile
- Backend proxy routes so the browser never sees your Oura client secret or bearer token
- Frontend controls to connect, sync, and disconnect Oura

Apple workout import is still file-based because Apple Fitness workout history is not available through a simple public web API.

## Files

- `index.html`: app shell and Oura connection controls
- `app.js`: dashboard logic and calls to backend Oura routes
- `styles.css`: UI styling
- `server.ps1`: local web server and Oura OAuth backend
- `oura-config.example.json`: starter config for your Oura OAuth app
- `.gitignore`: ignores local secrets and token cache files

## Setup

1. Copy `oura-config.example.json` to `oura-config.json`.
2. Fill in your Oura OAuth `clientId` and `clientSecret`.
3. In your Oura developer app settings, set the redirect URI to `http://localhost:8787/auth/oura/callback`.
4. Run the server:

```powershell
powershell -ExecutionPolicy Bypass -File .\server.ps1
```

5. Open [http://localhost:8787](http://localhost:8787).
6. Click `Connect Oura` and complete the consent flow.
7. Click `Sync live data` to pull recent daily metrics.

## Config

Example `oura-config.json`:

```json
{
  "clientId": "YOUR_OURA_CLIENT_ID",
  "clientSecret": "YOUR_OURA_CLIENT_SECRET",
  "redirectUri": "http://localhost:8787/auth/oura/callback",
  "scopes": ["daily", "personal", "heartrate", "session", "workout", "tag"],
  "port": 8787,
  "apiBase": "https://api.ouraring.com"
}
```

## API notes

The backend currently syncs recent daily Oura data and normalizes it into the dashboard shape used by the original app:

- readiness score
- sleep score
- HRV
- resting heart rate
- activity score
- steps

The OAuth flow and token refresh behavior are implemented server-side. The daily sync route is scaffolded against Oura API v2 daily usercollection resources and can be adjusted in `server.ps1` if you want to expand to workouts, sessions, or tags.

## Security notes

- `oura-config.json` is ignored by git so the client secret stays local.
- `token-store.json` stores access and refresh tokens using Windows secure-string encryption for the current user account.
- `disconnect` deletes the local token cache.

## Important Oura caveat

Per Oura’s official API guidance, Gen3 and Ring 4 users without an active Oura Membership cannot access API data.

## Apple data import

Apple workouts are still imported from JSON. Accepted workout fields include:

- `date` or `workoutDate` or `startDate`
- `type` or `workoutType`
- `durationMinutes` or `duration`
- `activeCalories` or `calories` or `energyBurned`
- `distanceMiles` or `distance`
- `averageHeartRate` or `avgHeartRate` or `heartRate`

## Next possible upgrades

- Persist imported Apple workout files in local storage
- Pull Oura workouts, sessions, and tags in addition to daily summaries
- Add Apple Health ingestion helpers that transform export XML into the JSON import shape
- Replace the PowerShell server with a typed Node or .NET backend if you want multi-user deployment

## Sources

- [Oura API getting started and OAuth guide](https://support.ouraring.com/hc/en-us/articles/360025438734-How-do-I-use-the-Oura-API)
- [Oura API v2 docs](https://cloud.ouraring.com/v2/docs)
