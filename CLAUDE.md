# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

- **Language:** Haskell (GHC 9.8.4, Haskell2010)
- **Build:** Cabal 3.0 — no Stack
- **Runtime:** Podman + podman-compose
- **Database:** PostgreSQL 17 (via `postgresql-simple`)

## Dev workflow

```bash
./dev.sh          # build image and start collector + postgres, tail logs → logs/dev.log
./dev.sh restart  # rebuild and restart collector only (leaves postgres running)
./dev.sh logs     # tail logs/dev.log
./dev.sh stop     # stop everything
```

To query the database directly:
```bash
podman exec airgradient_postgres_1 psql -U postgres -d airgradient -c "SELECT * FROM measurements ORDER BY created_at DESC LIMIT 5;"
```

There are no tests. The binary is the only build artifact.

## Architecture

Single executable with three modules and an entry point:

- **`src/Config.hs`** — reads all config from environment variables (`API_KEY`, `DB_*`). Returns a `Config` record used everywhere.
- **`src/AirGradient.hs`** — HTTP client for the AirGradient cloud API. Fetches `GET /public/api/v1/locations/measures/current?token=…` and decodes the JSON array into `[Measurement]`. Auth is a `?token=` query parameter (not a Bearer header).
- **`src/DB.hs`** — PostgreSQL connection and schema. `initDB` runs `CREATE TABLE IF NOT EXISTS` on startup. `insertMeasurement` uses parameterised `?` placeholders (safe from SQL injection).
- **`app/Main.hs`** — tail-recursive poll loop: fetch → insert → `threadDelay 60s` → repeat. Exceptions are caught and logged; the loop continues regardless.

## Key constraints

- **GHC pinned to 9.8.4** in the Dockerfile. `postgresql-libpq >= 0.11` requires libpq ≥ 14, but the `haskell:9.8` image (Debian Bullseye) only ships libpq 13. The Dockerfile works around this by adding the PGDG apt repo. If upgrading GHC, verify the haskell image's Debian base before bumping.
- **`postgresql-simple` bounds** cap at `base < 4.22` and `template-haskell < 2.24`, which rules out GHC 9.14 (base 4.22). GHC 9.10 or 9.12 images are not published to Docker Hub; 9.8.4 is the newest available image that works.
- The `Measurement` type maps directly to the API response. Field names in `FromJSON` must match the API exactly — notably `serialno` (all lowercase), not `serialNo`.