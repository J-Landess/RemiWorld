# Remi's World — Web App

React + Vite site for [wisemenresearch.org](https://wisemenresearch.org).

## Local dev

```bash
npm install
npm run dev
```

Open **http://localhost:5180** (avoids clashing with other Vite apps on 5173). If that port is taken, check the terminal for the actual URL.

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Dev server with HMR |
| `npm run build` | Production build → `dist/` |
| `npm run preview` | Serve the production build locally |
| `npm test` | Run Vitest smoke tests |

## Pages

- `/` — Home
- `/play` — Game embed (Phase 2)
- `/about` — Research / about stub

## Deploy

Production deploys via root [`vercel.json`](../vercel.json) — Vercel builds this folder automatically.
