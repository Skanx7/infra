FROM astral/uv:python3.12-bookworm-slim AS builder

WORKDIR /app
COPY pyproject.toml uv.lock* ./
RUN uv sync --frozen --no-install-project || uv sync --no-install-project
COPY scripts/ ./scripts/
RUN mkdir -p init

RUN uv run scripts/build_world.py

FROM postgres:18

# Install prerequisites and extensions
RUN apt-get update && \
    apt-get install -y \
    gnupg \
    postgresql-common \
    apt-transport-https \
    lsb-release \
    wget \
    postgresql-18-pgvector \
    postgresql-18-postgis-3

# Adding TimescaleDB repository and GPG key
RUN /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && \
    echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" > /etc/apt/sources.list.d/timescaledb.list && \
    wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg && \
    apt-get update && \
    apt-get install -y timescaledb-2-postgresql-18 && \
    rm -rf /var/lib/apt/lists/*

COPY ./init/ /docker-entrypoint-initdb.d/
COPY --from=builder /app/init/03-world.sql /docker-entrypoint-initdb.d/03-world.sql
# (timescaledb and pgvector need to be in shared_preload_libraries to work properly)
CMD ["postgres", "-c", "shared_preload_libraries=timescaledb,vector"]