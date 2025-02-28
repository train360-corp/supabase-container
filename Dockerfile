###############################################
# DATABASE (base image)
# See: https://github.com/supabase/supabase/blob/master/docker/docker-compose.yml#L387
###############################################
FROM supabase/postgres:15.8.1.020 AS base

RUN mkdir "/supabase"
RUN apt-get update && apt-get install -y curl gettext

# install Node (shared dep)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh
RUN rm -rf nodesource_setup.sh
RUN apt-get install nodejs -y

# Create necessary directories
RUN mkdir -p /docker-entrypoint-initdb.d/migrations \
    && mkdir -p /docker-entrypoint-initdb.d/init-scripts

# Copy database migration and initialization scripts
COPY ./supabase/db/realtime.sql /docker-entrypoint-initdb.d/migrations/99-realtime.sql
COPY ./supabase/db/webhooks.sql /docker-entrypoint-initdb.d/init-scripts/98-webhooks.sql
COPY ./supabase/db/roles.sql /docker-entrypoint-initdb.d/init-scripts/99-roles.sql
COPY ./supabase/db/jwt.sql /docker-entrypoint-initdb.d/init-scripts/99-jwt.sql
COPY ./supabase/db/_supabase.sql /docker-entrypoint-initdb.d/migrations/97-_supabase.sql
COPY ./supabase/db/logs.sql /docker-entrypoint-initdb.d/migrations/99-logs.sql
COPY ./supabase/db/pooler.sql /docker-entrypoint-initdb.d/migrations/99-pooler.sql

# Set permissions (PostgreSQL runs as user "postgres")
RUN chown -R postgres:postgres /docker-entrypoint-initdb.d/

###############################################
# KONG
# See: https://docs.konghq.com/gateway/latest/install/docker/build-custom-images/
###############################################
FROM base AS kong

WORKDIR /supabase/kong

RUN curl -O https://raw.githubusercontent.com/Kong/docker-kong/master/docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh

ARG TARGETARCH
RUN curl -O https://packages.konghq.com/public/gateway-39/deb/debian/pool/bullseye/main/k/ko/kong-enterprise-edition_3.9.0.1/kong-enterprise-edition_3.9.0.1_"$TARGETARCH".deb

COPY supabase/kong.yml /tmp/kong.yml
RUN mv kong-enterprise-edition_3.9.0.1_"$TARGETARCH".deb /tmp/kong.deb

RUN set -ex; \
   apt-get update \
   && apt-get install --yes /tmp/kong.deb \
   && rm -rf /var/lib/apt/lists/* \
   && mv /tmp/kong.yml /etc/kong/kong.yml \
   && chown kong:0 /etc/kong/kong.yml \
   && rm -rf /tmp/kong.deb \
   && rm -rf /tmp/kong.yml \
   && chown kong:0 /usr/local/bin/kong \
   && chown -R kong:0 /usr/local/kong \
   && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/luajit \
   && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/lua \
   && ln -s /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx \
   && kong version

EXPOSE 8000 8443

###############################################
# POSTGREST
# See: https://github.com/PostgREST/postgrest/blob/main/Dockerfile
###############################################
FROM kong AS postgrest

WORKDIR /supabase/postgrest

RUN apt-get update -y \
       && apt install -y --no-install-recommends libpq-dev zlib1g-dev jq gcc libnuma-dev xz-utils \
       && apt-get clean \
       && rm -rf /var/lib/apt/lists/*

RUN curl -LO https://github.com/PostgREST/postgrest/releases/download/v12.2.8/postgrest-v12.2.8-linux-static-x86-64.tar.xz
RUN tar -xvf postgrest-v12.2.8-linux-static-x86-64.tar.xz
RUN rm -rf postgrest-v12.2.8-linux-static-x86-64.tar.xz

###############################################
# STUDIO
# See: https://github.com/supabase/supabase/blob/master/apps/studio/Dockerfile
###############################################
FROM ghcr.io/supabase/studio:20250113-83c9420 AS studio-base
FROM postgrest AS studio

WORKDIR /supabase/studio

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=studio-base --chown=nextjs:nodejs /app .

###############################################
# META
# See: https://github.com/supabase/postgres-meta/blob/master/Dockerfile
###############################################
FROM studio AS meta
WORKDIR /supabase/meta

WORKDIR /supabase/meta/bin
RUN apt-get update && apt-get install -y \
    ca-certificates git build-essential python3 \
    && rm -rf /var/lib/apt/lists/*
COPY bin/postgres-meta/package.json ./
COPY bin/postgres-meta/package-lock.json ./
RUN npm clean-install
COPY bin/postgres-meta/ .
RUN npm run build && npm prune --omit=dev

WORKDIR /supabase/meta
RUN mv /supabase/meta/bin/node_modules node_modules
RUN mv /supabase/meta/bin/dist dist
COPY bin/postgres-meta/package.json ./

###############################################
# AUTH
# See: https://github.com/supabase/auth/blob/master/Dockerfile
###############################################
FROM ghcr.io/supabase/auth:v2.169.0 AS auth-base
FROM meta AS auth

WORKDIR /supabase/auth

RUN mkdir migrations

COPY --from=auth-base /usr/local/bin/auth /supabase/auth
COPY --from=auth-base /usr/local/etc/auth/migrations /supabase/auth/migrations/

ENV GOTRUE_DB_MIGRATIONS_PATH=/supabase/auth/migrations

###############################################
# REALTIME
# See: https://github.com/supabase/realtime/blob/main/Dockerfile
###############################################
FROM ghcr.io/train360-corp/realtime:v2.34.31 AS realtime-base
FROM auth AS realtime

WORKDIR /supabase/realtime

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales iptables sudo tini curl build-essential manpages-dev gawk bison && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

COPY --from=realtime-base /app /supabase/realtime

# bug fix
RUN sed -i 's|/app|/supabase/realtime|g' /supabase/realtime/run.sh

###############################################
# SUPERVISOR
# See: https://docs.docker.com/engine/containers/multi-service_container/#use-a-process-manager
###############################################
FROM realtime AS supervisor

RUN apt-get update -y && \
    apt-get install -y supervisor && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*
RUN mkdir -p /var/log/supervisor
COPY ./supervisor/ /etc/supervisor/conf.d/

###############################################
# (start)
###############################################
FROM supervisor AS runner

WORKDIR /

CMD ["/usr/bin/supervisord"]
