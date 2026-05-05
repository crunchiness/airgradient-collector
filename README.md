# airgradient-collector

Polls the AirGradient cloud API every minute and stores measurements in PostgreSQL.

## Configuration

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

## Running locally with Podman

### With podman-compose

```bash
podman-compose up --build
```

### Without podman-compose

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