# LNDRY Platform — Fastify Backend

## Prerequisites

- Node.js >= 18
- Docker & Docker Compose (for PostgreSQL + Redis)

## Quick Start

```bash
npm install
npm run infra:up
npm run db:migrate
npm run db:seed
npm run dev
```

Server starts at **http://localhost:3000**

If you have not created an env file yet:

```bash
cp .env.example .env
```

Use `npm run setup:local` to run infra + migrate + seed in one command.

- Health check: `GET /health`
- Swagger docs: `GET /documentation`

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start with nodemon (auto-reload) |
| `npm start` | Start production server |
| `npm run start:pm2` | Start with PM2 cluster mode |
| `npm run db:migrate` | Run SQL migrations |
| `npm run db:seed` | Seed sample data |
| `npm test` | Run tests (vitest) |
| `npm run lint` | ESLint check |
| `npm run format` | Prettier format |

## Architecture

```
Route → preHandler (auth/role) → JSON Schema Validation → Controller → Service → Repository → PostgreSQL
                                                                         ↕
                                                                     Redis Cache
```

See `Backend system design/ARCHITECTURE.md` for full details.

## Developer Workflow Protection (Port 4500)

LNDRY has built-in port guard protection on port `4500` (default env port) to prevent duplicate startup crashes or resource exhaustion:
1. **Auto-Reuse**: When starting the backend, it will automatically query `/health` on the configured port. If a healthy LNDRY server is already running, it logs a skipping message and exits gracefully (`0`) instead of crashing with `EADDRINUSE`. You can continue using your already-running backend instance safely!
2. **Diagnostics**: If the port is occupied by another application or an unhealthy/unresponsive process, LNDRY runs automated system diagnostics. It reports:
   - Occupying Process ID (PID)
   - Executable path
   - CommandLine command string
   - Health check error status
3. **Corrective Action**: If an unhealthy or foreign process is occupying the port, stop the occupying process before running the backend again:
   ```powershell
   # Kill the occupying process on Windows
   taskkill /F /PID <PID>
   ```

