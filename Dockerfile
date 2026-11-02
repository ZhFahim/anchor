FROM node:26-alpine@sha256:c6ad9e9c1d80f6eb607c26b4b0a132ff7a2344fad1c78ea3baa2a7d4c8de6d94 AS base

# pnpm from its official image
COPY --from=ghcr.io/pnpm/pnpm:12.16.1-alpine /opt/pnpm /opt/pnpm
RUN for bin in pnpm pn pnpx pnx; do ln -s "/opt/pnpm/$bin" "/usr/local/bin/$bin"; done

# Next.js on Alpine can need libc compatibility
RUN apk add --no-cache libc6-compat

#
# Server build
#
FROM base AS server_deps
WORKDIR /app/server
COPY server/package.json server/pnpm-lock.yaml server/pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

# Production-only server deps (for smaller runtime image)
FROM server_deps AS server_prod_deps
RUN pnpm prune --prod
# Drop what those packages ship but the server never loads (browser builds,
# other databases' engines): about 200 MB unpacked.
COPY server/scripts/prune-runtime.sh ./scripts/prune-runtime.sh
RUN sh scripts/prune-runtime.sh

FROM base AS server_builder
WORKDIR /app/server
COPY --from=server_deps /app/server/node_modules ./node_modules
COPY server/ ./

# Generate Prisma client and build Nest
RUN pnpm prisma generate
RUN pnpm build

# Ensure Prisma client artifacts are available alongside compiled JS output.
# (Nest build may not copy generated JS assets by default.)
RUN if [ -d src/generated ]; then mkdir -p dist/src && cp -R src/generated dist/src/; fi

#
# Web build
#
FROM base AS web_deps
WORKDIR /app/web
COPY web/package.json web/pnpm-lock.yaml web/pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

FROM base AS web_builder
WORKDIR /app/web
COPY --from=web_deps /app/web/node_modules ./node_modules
COPY web/ ./

ENV NEXT_TELEMETRY_DISABLED=1
ENV SERVER_URL=http://127.0.0.1:3001
# The Anchor+ release the web app shows in Settings › About.
ARG ANCHOR_VERSION=
ENV ANCHOR_VERSION=$ANCHOR_VERSION
RUN pnpm build

#
# Runtime image (single container: postgres + api + web)
#
FROM postgres:18-alpine@sha256:10a5c69a83035ab5239f5620d708520e8b28f5aa1f2b20143e6024532edadfb5 AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PGDATA=/data/postgres

# Bring Node runtime into the postgres image (same Alpine/musl family).
# Copy only the Node binary so we don't overwrite Postgres' own entrypoint scripts.
COPY --from=base /usr/local/bin/node /usr/local/bin/node

# curl for HEALTHCHECK, supervisor for process management. Upgrading first
# takes Alpine's fixes ahead of the base image's next rebuild.
RUN apk upgrade --no-cache   && apk add --no-cache curl supervisor libstdc++ libatomic libc6-compat

# Server runtime files
COPY --from=server_builder /app/server/dist ./server/dist
COPY --from=server_prod_deps /app/server/node_modules ./server/node_modules
COPY --from=server_builder /app/server/prisma ./server/prisma
COPY --from=server_builder /app/server/package.json ./server/package.json
COPY --from=server_builder /app/server/prisma.config.ts ./server/prisma.config.ts

# Web runtime files (Next standalone output)
COPY --from=web_builder /app/web/.next/standalone ./web
COPY --from=web_builder /app/web/.next/static ./web/.next/static
COPY --from=web_builder /app/web/public ./web/public

COPY docker/docker-entrypoint.sh /app/docker-entrypoint.sh
COPY docker/anchor-env.sh /app/anchor-env.sh
COPY docker/supervisord.conf /etc/supervisord.conf
# `docker exec -it anchor-plus reset-password <email>` for a locked-out account
COPY docker/reset-password /usr/local/bin/reset-password
# `docker compose exec -T anchor-plus backup > anchor-backup.tar`, and `restore <`
COPY docker/backup /usr/local/bin/backup
COPY docker/restore /usr/local/bin/restore
RUN chmod +x /app/docker-entrypoint.sh /usr/local/bin/reset-password \
  /usr/local/bin/backup /usr/local/bin/restore

# The image's own name, for /api/health: the apps offer release candidates
# only to servers running ghcr.io/<owner>/anchor:fork-preview. Last, so a
# preview image shares every other layer with the release's.
ARG ANCHOR_IMAGE=
ENV ANCHOR_IMAGE=$ANCHOR_IMAGE

VOLUME ["/data"]

EXPOSE 3000

# Validates web and API routing via Next rewrite (/api/*), and the database
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:3000/api/health/ready || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]