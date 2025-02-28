# supabase-container

## Getting Started

```shell
# create a working directory
mkdir ~/supabase
cd ~/supabase

# copy environment variables
# TODO: make sure to update values as commented in the .env file
curl -OL https://raw.githubusercontent.com/train360-corp/supabase-container/refs/heads/main/.env

# start supabase

docker run \
  --add-host=realtime-dev.supabase-realtime:127.0.0.1 \
  --volume ./pg_data:/var/lib/postgresql/data \
  --env-file ./.env \
  --rm \
  --detach \
  --name supabase \
  -p 5432:5432 \
  -p 8000:8000 \
  -p 8443:8443 \
  ghcr.io/train360-corp/supabase:latest

# FOR REFERENCE ONLY (COPY AND PASTE ABOVE)
docker run \
  --add-host=realtime-dev.supabase-realtime:127.0.0.1 \ # realtime internal network bridge between Kong and Realtime (DO NOT CHANGE)
  --volume ./pg_data:/var/lib/postgresql/data \ # postgres data persisted locally
  --env-file ./.env \ # load env file
  --rm \ # remove container when stopped
  --detach \ # detach (run in background)
  --name supabase \
  -p 5432:5432 \ # postgres port
  -p 8000:8000 \ # kong http port
  -p 8443:8443 \ # kong https port
  ghcr.io/train360-corp/supabase:latest
```

## Automatic Migrations Support

Mounting a local directory at /supabase/migrations will automatically trigger running migration scripts.

The local directory should be at the root level for the migrations.

## Roadmap

* complete coverage
* one-click deploy options
    * Digital Ocean

## Coverage

The following Suapbase components have been successfully ported:

| Component | Supported | Version          |
|-----------|-----------|------------------|
| supavisor | ❌         |                  |
| vector    | ❌         |                  |
| db        | ✅         | 15.8.1.020       |
| analytics | ❌         |                  |
| functions | ❌         |                  |
| meta      | ✅         | 0.84.2           |
| imgproxy  | ❌         |                  |
| storage   | ❌         |                  |
| realtime  | ✅         | 2.34.31          |
| rest      | ✅         | 12.2.8           |
| auth      | ✅         | 2.169.0          |
| kong      | ✅         | 3.9.0            |
| studio    | ✅         | 20250113-83c9420 |

(*) indicates in-progress builds

### Editors Notes

#### realtime

This package uses supabase's own postgres image as the base runtime. This image runs on Ubuntu Focal. However, realtime
is built for Debian (a newer version). TLDR; a libc compatibility error occurs, requiring a custom build on an earlier
version.