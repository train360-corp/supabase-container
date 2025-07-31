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
  --volume ./pg_data:/var/lib/postgresql/data \
  --volume ./storage_data:/supabase/storage/data \
  --env-file ./.env \
  --rm \
  --detach \
  --name supabase \
  -p 5432:5432 \
  -p 8000:8000 \
  ghcr.io/train360-corp/supabase:latest

# FOR REFERENCE ONLY (COPY AND PASTE ABOVE)
docker run \
  --volume ./pg_data:/var/lib/postgresql/data \ # postgres data persisted locally
  --volume ./storage_data:/supabase/storage/data \ # storage data persisted locally
  --env-file ./.env \ # load env file
  --rm \ # remove container when stopped
  --detach \ # detach (run in background)
  --name supabase \
  -p 5432:5432 \ # postgres port
  -p 8000:8000 \ # kong http port
  ghcr.io/train360-corp/supabase:latest
```

## Automatic Migrations Support

Set the environment variable `AUTO_MIGRATIONS_MODE`.

- `AUTO_MIGRATIONS_MODE=off` (default)

    - No migrations will be applied.

- `AUTO_MIGRATIONS_MODE=mounted`

    - Mount (or custom-build) a local directory at /supabase/migrations.
    - The local directory should be at the root level for the migrations.

## Coverage

The following Suapbase components have been successfully ported:

| Component | Port                                                                                        | Supported | Version          |
|-----------|---------------------------------------------------------------------------------------------|-----------|------------------|
| supavisor |                                                                                             | ❌         |                  |
| vector    |                                                                                             | ❌         |                  |
| db        | 5432                                                                                        | ✅         | 15.8.1.020       |
| analytics |                                                                                             | ❌         |                  |
| functions | 9000                                                                                        | ❌         |                  |
| meta      | 8080                                                                                        | ✅         | 0.86.3           |
| imgproxy  |                                                                                             | ❌         |                  |
| storage   | 5000                                                                                        | ❌         |                  |
| realtime  | 4000                                                                                        | ✅         | 2.34.31          |
| rest      | 3000                                                                                        | ✅         | 12.2.8           |
| auth      | 9999                                                                                        | ✅         | 2.169.0          |
| kong      | 8000[[1]](https://docs.konghq.com/gateway/latest/production/networking/default-ports/#main) | ✅         | 3.9.0            |
| studio    | 3333                                                                                        | ✅         | 20250113-83c9420 |

(*) indicates in-progress builds

[1] Kong uses multiple ports (with 8000 being the default gateway); see the full list here: https://docs.konghq.com/gateway/latest/production/networking/default-ports/#main

### Editors Notes

#### realtime

This package uses supabase's own postgres image as the base runtime. This image runs on Ubuntu Focal. However, realtime
is built for Debian (a newer version). TLDR; a libc compatibility error occurs, requiring a custom build on an earlier
version.