FROM node:24-alpine AS base

# pnpm via corepack
RUN corepack enable && corepack prepare pnpm@latest --activate

# Next.js on Alpine can need libc compatibility
RUN apk add --no-cache libc6-compat

#
# Server build
#
FROM base AS server_deps
WORKDIR /app/server
COPY server/package.json server/pnpm-lock.yaml ./
RUN pnpm install --no-frozen-lockfile

# Production-only server deps (for smaller runtime image)
FROM base AS server_prod_deps
WORKDIR /app/server
COPY server/package.json server/pnpm-lock.yaml ./
RUN pnpm install --prod --no-frozen-lockfile

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
COPY web/package.json web/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

FROM base AS web_builder
WORKDIR /app/web
COPY --from=web_deps /app/web/node_modules ./node_modules
COPY web/ ./

ENV NEXT_TELEMETRY_DISABLED=1
ENV SERVER_URL=http://127.0.0.1:3001
RUN pnpm build

#
# Runtime image (single container: postgres + api + web)
#
FROM postgres:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PGDATA=/data/postgres

# Bring Node runtime into the postgres image (same Alpine/musl family).
# Copy only the Node binary so we don't overwrite Postgres' own entrypoint scripts.
COPY --from=base /usr/local/bin/node /usr/local/bin/node

# curl for HEALTHCHECK, supervisor for process management
RUN apk add --no-cache curl supervisor libstdc++ libc6-compat

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
COPY docker/supervisord.conf /etc/supervisord.conf
RUN chmod +x /app/docker-entrypoint.sh

VOLUME ["/data"]

EXPOSE 3000

# Validates both web and API routing via Next rewrite (/api/*)
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=30s \
  CMD curl -f http://localhost:3000/api/health || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]