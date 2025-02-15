FROM node:20-slim AS studio-builder
# moved earlier for efficiency and caching

RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends git python3 ca-certificates build-essential && \
  rm -rf /var/lib/apt/lists/* && \
  update-ca-certificates

# install Node (shared dep) [NOT NEEDED HERE]
#RUN curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
#RUN bash nodesource_setup.sh
#RUN rm -rf nodesource_setup.sh
#RUN apt-get install nodejs -y

WORKDIR /supabase/studio

RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends git python3 ca-certificates build-essential \
  && rm -rf /var/lib/apt/lists/* \
  && update-ca-certificates

RUN npm install -g pnpm@9.15.5

COPY bin/supabase .

RUN pnpm dlx turbo@2.3.3 prune studio --docker
RUN pnpm install --frozen-lockfile

# bug fix
RUN sed -i 's|next build && ./../../scripts/upload-static-assets.sh|next build|' package.json

RUN pnpm dlx turbo@2.3.3 run build --filter studio -- --no-lint

FROM supabase/postgres:15.8.1.020 AS base

RUN mkdir "/supabase"
RUN apt-get update && apt-get install -y curl

###############################################
# DATABASE
# See: https://github.com/supabase/supabase/blob/master/docker/docker-compose.yml#L387
###############################################

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
# SUPERVISOR
# See: https://docs.docker.com/engine/containers/multi-service_container/#use-a-process-manager
###############################################
FROM base AS supervisor

RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor
COPY ./supervisor/ /etc/supervisor/conf.d/

###############################################
# KONG
# See: https://docs.konghq.com/gateway/latest/install/docker/build-custom-images/
###############################################
FROM supervisor AS kong

WORKDIR /supabase/kong

RUN curl -O https://raw.githubusercontent.com/Kong/docker-kong/master/docker-entrypoint.sh
RUN chmod +x docker-entrypoint.sh
RUN curl -O https://packages.konghq.com/public/gateway-39/deb/ubuntu/pool/focal/main/k/ko/kong_3.9.0/kong_3.9.0_amd64.deb

COPY supabase/kong.yml /tmp/kong.yml
RUN mv kong_3.9.0_amd64.deb /tmp/kong.deb

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
FROM postgrest AS studio

WORKDIR /supabase/studio

RUN mkdir /supabase/studio/bin
COPY --from=studio-builder /supabase/studio/public ./bin/public
COPY --from=studio-builder /supabase/studio/.next/standalone ./
COPY --from=studio-builder /supabase/studio/.next/static ./bin/.next/static

###############################################
# (start)
###############################################

FROM studio AS runner

WORKDIR /

CMD ["/usr/bin/supervisord"]
