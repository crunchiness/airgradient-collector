# airgradient-collector

A self-hosted collector for [AirGradient](https://www.airgradient.com/) air quality sensors written in Haskell (why not?). It polls the AirGradient cloud API every minute and stores measurements in your own PostgreSQL database.

AirGradient's dashboard only provides granular historical data for the past 6 months without a paid subscription. Running this collector gives you full, permanent access to your own data — query it however you like, keep it as long as you want.

## Configuration

Your API key can be found in the [AirGradient dashboard](https://app.airgradient.com/settings/place?tab=2) under General Settings → Connectivity.

Copy `.env.example` to `.env` and fill in your values:

```
API_KEY=your-airgradient-api-key
DB_PASSWORD=your-database-password

# Optional — defaults shown
DB_HOST=postgres
DB_PORT=5432
DB_NAME=airgradient
DB_USER=postgres
```

## Running locally

The examples below use Podman, but Docker works identically — just replace `podman` with `docker`.

### With dev.sh (Podman only)

The included `dev.sh` script is the quickest way to get started:

```bash
./dev.sh          # build and start everything, logs → logs/dev.log
./dev.sh restart  # rebuild and restart the collector
./dev.sh logs     # tail logs/dev.log
./dev.sh stop     # stop everything
```

### With podman-compose / docker-compose

```bash
podman-compose up --build
```

### Without compose

Build the image:

```bash
podman build -t airgradient-collector .
```

Start PostgreSQL:

```bash
podman network create ag-net

podman run -d \
  --name postgres \
  --network ag-net \
  -e POSTGRES_DB=airgradient \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=changeme \
  -v ag-postgres-data:/var/lib/postgresql/data \
  docker.io/library/postgres:17
```

Start the collector:

```bash
podman run -d \
  --name airgradient-collector \
  --network ag-net \
  --env-file .env \
  -e DB_HOST=postgres \
  airgradient-collector
```

Follow logs:

```bash
podman logs -f airgradient-collector
```

## Self-hosting

The collector is a single Docker container with no exposed ports. It connects to any PostgreSQL instance you point it at via environment variables. You can run it on any Docker-capable host — a VPS, a home server, Coolify, Portainer, Dokku, or a plain `docker run`.

### Deploying the container

Build and push the image to a registry, or point your host at this repository to build from the Dockerfile directly. Then set the following environment variables:

| Variable      | Value                          |
|---------------|--------------------------------|
| `API_KEY`     | Your AirGradient API key       |
| `DB_HOST`     | PostgreSQL hostname            |
| `DB_PORT`     | `5432`                         |
| `DB_NAME`     | Database name                  |
| `DB_USER`     | Database user                  |
| `DB_PASSWORD` | Database password              |

The container has no exposed ports — disable port binding if your platform requires it.

## Schema

The collector creates the `measurements` table automatically on startup:

| Column       | Type             | Description            |
|--------------|------------------|------------------------|
| `location_id`| integer          | AirGradient location   |
| `serial_no`  | text             | Device serial number   |
| `timestamp`  | timestamptz      | Measurement time (UTC) |
| `pm01`       | double precision | PM1.0 µg/m³            |
| `pm02`       | double precision | PM2.5 µg/m³            |
| `pm10`       | double precision | PM10 µg/m³             |
| `rco2`       | integer          | CO₂ ppm                |
| `tvoc`       | double precision | TVOC raw value         |
| `tvoc_index` | integer          | TVOC index             |
| `nox_index`  | integer          | NOx index              |
| `atmp`       | double precision | Temperature °C         |
| `rhum`       | double precision | Relative humidity %    |
| `wifi`       | integer          | RSSI dBm               |
| `created_at` | timestamptz      | Row insertion time     |