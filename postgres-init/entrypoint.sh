#!/bin/bash
set -e

echo "Waiting for PostgreSQL to be ready..."
until pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_CONTAINER_PORT" -U "$POSTGRES_USER"; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done

echo "PostgreSQL is up! Starting initialization..."

# Execute all .sql and .sh files in order from numbered directories
for dir in /app/init-db/*/; do
  echo "Processing directory: $dir"
  
  # Process all files in the directory and subdirectories (both .sql and .sh, in alphabetical order)
  for file in $(find "$dir" -type f \( -name "*.sql" -o -name "*.sh" \) | sort); do
    echo "Executing: $file"
    
    if [[ "$file" == *.sql ]]; then
      PGPASSWORD="$POSTGRES_PASSWORD" psql \
        -h "$POSTGRES_HOST" \
        -p "$POSTGRES_CONTAINER_PORT" \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DB" \
        -f "$file"
    elif [[ "$file" == *.sh ]]; then
      # Execute shell script with postgres environment variables available
      export PGPASSWORD="$POSTGRES_PASSWORD"
      export PGHOST="$POSTGRES_HOST"
      export PGPORT="$POSTGRES_CONTAINER_PORT"
      export PGUSER="$POSTGRES_USER"
      export PGDATABASE="$POSTGRES_DB"
      bash "$file"
    fi
    
    if [ $? -ne 0 ]; then
      echo "Error executing $file"
      exit 1
    fi
  done
done

echo "Initialization complete!"
