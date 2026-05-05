FROM docker.io/library/haskell:9.8.4 AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends wget gnupg \
 && wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" \
      > /etc/apt/sources.list.d/pgdg.list \
 && apt-get update && apt-get install -y --no-install-recommends libpq-dev pkg-config \
 && rm -rf /var/lib/apt/lists/*

# Resolve and cache dependencies before copying source.
# Rebuild only when the cabal file changes.
COPY airgradient-collector.cabal cabal.project ./
RUN cabal update && cabal build --only-dependencies

COPY app/ app/
COPY src/ src/
RUN cabal build exe:airgradient-collector \
 && cp "$(cabal list-bin airgradient-collector)" /airgradient-collector

FROM docker.io/library/debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      libpq5 \
      libgmp10 \
      ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /airgradient-collector /usr/local/bin/airgradient-collector

ENTRYPOINT ["airgradient-collector"]
