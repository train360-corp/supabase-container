#!/bin/bash

AUTO_MIGRATIONS_MODE="${AUTO_MIGRATIONS_MODE:-off}"

case "$AUTO_MIGRATIONS_MODE" in
  "off")
    echo "Auto-migrations are disabled."
    ;;
  "mounted")
    echo "Running migrations in mounted mode."
    if [ -d "/supabase/migrations" ]; then
      cd /
      supabase db push --db-url="postgres://postgres:$SUPABASE_POSTGRES_PASSWORD@127.0.0.1:5432/postgres"
    else
      echo "Mounted directory /supabase/migrations not found!"
    fi
    ;;
  *)
    echo "Invalid AUTO_MIGRATIONS_MODE: $AUTO_MIGRATIONS_MODE"
    exit 1
    ;;
esac



# Execute the command passed as arguments
exec "$@"