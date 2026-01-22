# Multi-stage build for Gleam fullstack application
# Based on official Gleam deployment guide + Lustre fullstack docs

ARG ERLANG_VERSION=28.3.1
ARG GLEAM_VERSION=v1.14.0

FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-scratch AS gleam

# ============================================================
# Server base stage - shared foundation for migrate and build
# ============================================================
FROM erlang:${ERLANG_VERSION}-alpine AS server-base

COPY --from=gleam /bin/gleam /bin/gleam

WORKDIR /build

# Copy shared library
COPY shared/gleam.toml shared/manifest.toml ./shared/
COPY shared/src ./shared/src

# Copy server dependency manifests (for layer caching)
COPY server/gleam.toml server/manifest.toml ./server/

# Download server dependencies (includes cigogne for migrations)
RUN cd server && gleam deps download

COPY server/src ./server/src
COPY server/priv ./server/priv

# ============================================================
# Migrate stage - runs database migrations (no client needed)
# ============================================================
FROM server-base AS migrate

WORKDIR /build/server
ENTRYPOINT ["gleam", "run", "-m", "cigogne"]
CMD ["all"]

# ============================================================
# Build stage - adds client build on top of server-base
# ============================================================
FROM server-base AS build

# Copy client manifests and download deps
COPY client/gleam.toml client/manifest.toml client/package.json client/bun.lock ./client/
RUN cd client && gleam deps download

COPY client/src ./client/src

RUN cd client && gleam run -m lustre/dev add bun tailwind
RUN cd client && .lustre/bin/*/bun install

# Build client bundle directly to server static directory
RUN cd client && gleam run -m lustre/dev build --minify --outdir=../server/priv/static

# Build the server
RUN cd server && gleam build

# ============================================================
# Export stage - create erlang-shipment
# ============================================================
FROM build AS export

WORKDIR /build/server
RUN gleam export erlang-shipment

# ============================================================
# Runtime stage - minimal production image
# ============================================================
FROM erlang:${ERLANG_VERSION}-alpine

ARG GIT_SHA
ARG BUILD_TIME
ENV GIT_SHA=${GIT_SHA}
ENV BUILD_TIME=${BUILD_TIME}

WORKDIR /app

COPY healthcheck.sh /app/healthcheck.sh

RUN chmod +x /app/healthcheck.sh && \
    addgroup -S gleam && \
    adduser -S gleam -G gleam

COPY --from=export --chown=gleam:gleam /build/server/build/erlang-shipment /app

USER gleam

ENV PORT=8000
EXPOSE $PORT
ENV DATABASE_URL="postgres://postgres@localhost:5432/j26booking"
ENV DB_POOL_SIZE=15

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD /app/healthcheck.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
