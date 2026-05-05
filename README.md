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

## Deploying on Coolify

The database is deployed separately. Only the collector app is deployed here.

### 1. Deploy PostgreSQL

Add a new PostgreSQL 17 resource in Coolify and note the internal hostname, port, database name, user, and password it provides.

### 2. Deploy the collector

- Add a new resource → **Docker image** or **Dockerfile** (point at this repo).
- Set the following environment variables in Coolify's UI:

| Variable      | Value                                  |
|---------------|----------------------------------------|
| `API_KEY`     | Your AirGradient API key               |
| `DB_HOST`     | Internal hostname of your Coolify DB   |
| `DB_PORT`     | `5432`                                 |
| `DB_NAME`     | Database name from Coolify             |
| `DB_USER`     | Database user from Coolify             |
| `DB_PASSWORD` | Database password from Coolify         |

- The collector has no exposed ports, so disable port binding.
- Deploy.

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
| `tvoc_index` | integer          | TVOC index             |
| `nox_index`  | integer          | NOx index              |
| `atmp`       | double precision | Temperature °C         |
| `rhum`       | double precision | Relative humidity %    |
| `wifi`       | integer          | RSSI dBm               |
| `created_at` | timestamptz      | Row insertion time     |