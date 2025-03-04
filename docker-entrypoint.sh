#!/bin/bash
set -e

# add the custom host entry if it doesn't already exist
if ! grep -q "realtime-dev.supabase-realtime" /etc/hosts; then
    echo "127.0.0.1 realtime-dev.supabase-realtime" >> /etc/hosts
    echo "Added realtime-dev.supabase-realtime to /etc/hosts"
fi

# start supervisor
/usr/bin/supervisord