#!/bin/bash

if [ -d "/supabase/migrations" ]; then
  cd /
  supabase db push --db-url="postgres://postgres:$SUPABASE_POSTGRES_PASSWORD@127.0.0.1:5432/postgres"
fi

# Execute the command passed as arguments
exec "$@"