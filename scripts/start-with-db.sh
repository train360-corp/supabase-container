#!/bin/bash

MAX_ATTEMPTS=5
BASE_SLEEP=2
ATTEMPT=1

while ! pg_isready; do
  if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
    echo "Database is not ready after $MAX_ATTEMPTS attempts. Exiting."
    exit 1
  fi

  SLEEP_TIME=$((BASE_SLEEP ** ATTEMPT))
  echo "Attempt $ATTEMPT: Database not ready. Sleeping for $SLEEP_TIME seconds..."
  ((ATTEMPT++))
  sleep "$SLEEP_TIME"
done

echo "Database is ready!"

# Execute the command passed as arguments
exec "$@"