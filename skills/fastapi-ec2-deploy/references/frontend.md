# Wiring a separate frontend

Applies when the frontend is hosted elsewhere (Vercel, Netlify, a static bucket) and the API is on the EC2 box.

## Decide by how the client calls the API

- **Relative paths (`fetch("/api/...")`) with bearer tokens**: add a rewrite on the hosting platform from `/api/*` to `https://<api-hostname>/api/*`. The app stays same-origin, so no CORS, no client changes, and preview deployments work unchanged. The hostname is fixed in the platform config (Vercel cannot interpolate env vars in `vercel.json`), which some users dislike; say so up front.
- **Absolute base URL or the user refuses a fixed hostname**: read the API URL from a build-time variable (`VITE_API_URL` or the framework's equivalent), set it in the hosting platform, and set `CORS_ORIGINS` on the backend to the production domain. Preview deployments get random hostnames, so add an origin regex setting if previews must hit the API.

## Vercel specifics

- Root directory is the frontend folder in a monorepo; framework preset from the build tool.
- A single page app needs the fallback rewrite `{"source": "/:path*", "destination": "/index.html"}` after the API rewrite. Static files are served before rewrites apply.
- Vercel deploys on its own git integration, so the frontend and backend ship in parallel from the same push. Ship backward compatible API changes first.
- Custom domain: a CNAME to Vercel in the DNS zone, then add the domain in the project.

## Verifying

```sh
curl https://<frontend-host>/api/health         # 200 through the rewrite
curl -X POST https://<frontend-host>/api/auth/login -d '{}' -H 'Content-Type: application/json'  # 4xx from the app, not 502
```
