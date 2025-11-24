# Multi-stage build for Gleam application
# Based on official Gleam deployment guide: https://gleam.run/deployment/linux-server/

ARG ERLANG_VERSION=28.0.2.0
ARG GLEAM_VERSION=v1.13.0

# Gleam stage - extract Gleam binary
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-scratch AS gleam

# Build stage
FROM erlang:${ERLANG_VERSION}-alpine AS build

# Copy Gleam binary from scratch image
COPY --from=gleam /bin/gleam /bin/gleam

# Set working directory
WORKDIR /build

# Copy dependency manifests first (for better layer caching)
COPY gleam.toml manifest.toml ./

# Copy source code
COPY src ./src
COPY priv ./priv

# Build the application
RUN gleam export erlang-shipment

# Runtime stage
FROM erlang:${ERLANG_VERSION}-alpine

# Build metadata for deployment tracking
ARG GIT_SHA
ARG BUILD_TIME
ENV GIT_SHA=${GIT_SHA}
ENV BUILD_TIME=${BUILD_TIME}

WORKDIR /app

# Copy health check script
COPY healthcheck.sh /app/healthcheck.sh

# Create non-root user for running the application
RUN chmod +x /app/healthcheck.sh && \
    addgroup -S gleam && \
    adduser -S gleam -G gleam

# Copy built application from builder (includes priv directory)
COPY --from=build --chown=gleam:gleam /build/build/erlang-shipment /app

# Switch to non-root user
USER gleam

# Expose port (configurable via PORT env var, defaults to 8000)
EXPOSE 8000

# Environment variables (with defaults)
ENV PORT=8000
ENV DB_HOST=localhost
ENV DB_PORT=5432
ENV DB_NAME=j26booking
ENV DB_USER=postgres
# TODO: Should be mounted as secret
ENV DB_PASSWORD=""
ENV DB_POOL_SIZE=15

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD /app/healthcheck.sh

# Run the application
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
