FROM postgres:18

# Install prerequisites and pgvector extension
RUN apt-get update && \
    apt-get install -y \
    gnupg \
    postgresql-common \
    apt-transport-https \
    lsb-release \
    wget \
    postgresql-18-pgvector
# Adding TimescaleDB repository and GPG key
RUN /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && \
    echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" > /etc/apt/sources.list.d/timescaledb.list && \
    wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg && \
    apt-get update && \
    apt-get install -y timescaledb-2-postgresql-18 && \
    rm -rf /var/lib/apt/lists/*

COPY ./init/ /docker-entrypoint-initdb.d/

# (timescaledb and pgvector need to be in shared_preload_libraries to work properly)
CMD ["postgres", "-c", "shared_preload_libraries=timescaledb,vector"]