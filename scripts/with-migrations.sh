#!/bin/bash

AUTO_MIGRATIONS_MODE="${AUTO_MIGRATIONS_MODE:-off}"

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

  echo -e "${color}[$timestamp] [$level] $*\033[0m"
}

function info() {
    _log "INFO" "$*"
}

function warn() {
    _log "WARN" "$*"
}

function error() {
  _log "ERROR" "$*"
}

case "$AUTO_MIGRATIONS_MODE" in
  "off")
    info "Auto-migrations are disabled."
    ;;
  "mounted")
    info "Running migrations in mounted mode."
    if [ -d "/supabase/migrations" ]; then
      cd /
      supabase db push --db-url="postgres://postgres:$SUPABASE_POSTGRES_PASSWORD@127.0.0.1:5432/postgres"
    else
      warn "Mounted directory /supabase/migrations not found!"
    fi
    ;;
  *)
    error "Invalid AUTO_MIGRATIONS_MODE: $AUTO_MIGRATIONS_MODE"
    exit 1
    ;;
esac



# Execute the command passed as arguments
exec "$@"