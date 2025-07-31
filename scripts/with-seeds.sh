#!/bin/bash
set -euo pipefail

AUTO_SEEDING_MODE="${AUTO_SEEDING_MODE:-off}"

function _log() {
  local level="$1"
  shift
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  case "$level" in
    INFO)  color="\033[1;32m" ;;  # Green
    WARN)  color="\033[1;33m" ;;  # Yellow
    ERROR) color="\033[1;31m" ;;  # Red
    *)     color="\033[0m"    ;;  # Default
  esac

  echo -e "${color}[$timestamp] [$level] $*\033[0m" >&2
}

function info() {
  _log "INFO" "$@"
}

function warn() {
  _log "WARN" "$@"
}

function error() {
  _log "ERROR" "$@"
}

case "$AUTO_SEEDING_MODE" in
  "off")
    info "Auto-seeding is disabled."
    ;;
  "mounted")
    info "Running seeds in mounted mode."

    if [ -d "/supabase/seeds" ]; then
      seed_files=(/supabase/seeds/*.sql)
      if [ ${#seed_files[@]} -eq 0 ]; then
        warn "No .sql files found in /supabase/seeds."
      else
        for f in "${seed_files[@]}"; do
          info "Seeding: $f"
          if ! PGPASSWORD="${SUPABASE_POSTGRES_PASSWORD}" psql \
            -h 127.0.0.1 \
            -U postgres \
            -d postgres \
            -f "$f"; then
              error "Failed to apply seed file: $f"
              exit 1
          fi
        done
      fi
    else
      warn "Mounted directory /supabase/seeds not found!"
    fi
    ;;
  *)
    error "Invalid AUTO_SEEDING_MODE: $AUTO_SEEDING_MODE"
    exit 1
    ;;
esac

# Execute the command passed as arguments
exec "$@"