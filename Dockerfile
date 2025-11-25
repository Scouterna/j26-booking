# Multi-stage build for Gleam application
# Based on official Gleam deployment guide: https://gleam.run/deployment/linux-server/

ARG ERLANG_VERSION=28.0.2.0
ARG GLEAM_VERSION=v1.13.0

FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-scratch AS gleam

# Migrate stage - has gleam, deps, and source code (also used for migrations)
FROM erlang:${ERLANG_VERSION}-alpine AS migrate

COPY --from=gleam /bin/gleam /bin/gleam

WORKDIR /build

# Copy dependency manifests first (for better layer caching)
COPY gleam.toml manifest.toml ./

# Download dependencies (includes dev dependencies like cigogne for migrations)
RUN gleam deps download

COPY src ./src
COPY priv ./priv

# Entrypoint for migrations
ENTRYPOINT ["gleam", "run", "-m", "cigogne"]
CMD ["all"]

# Build stage
FROM migrate AS build

# Reset entrypoint from migrate stage for build
ENTRYPOINT []
CMD []

# Build the application and export an erlang-shipment
RUN gleam export erlang-shipment

# Runtime stage
FROM erlang:${ERLANG_VERSION}-alpine

# Build metadata for deployment tracking
ARG GIT_SHA
ARG BUILD_TIME
ENV GIT_SHA=${GIT_SHA}
ENV BUILD_TIME=${BUILD_TIME}

WORKDIR /app

COPY healthcheck.sh /app/healthcheck.sh

# Create non-root user for running the application
RUN chmod +x /app/healthcheck.sh && \
    addgroup -S gleam && \
    adduser -S gleam -G gleam

COPY --from=build --chown=gleam:gleam /build/build/erlang-shipment /app

USER gleam

ENV PORT=8000
EXPOSE $PORT
ENV DATABASE_URL="postgres://postgres@localhost:5432/j26booking"
ENV DB_POOL_SIZE=15

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD /app/healthcheck.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
