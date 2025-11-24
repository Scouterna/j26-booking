# Dockerfile for running database migrations with Cigogne
# Based on official Gleam deployment guide: https://gleam.run/deployment/linux-server/

ARG ERLANG_VERSION=28.0.2.0
ARG GLEAM_VERSION=v1.13.0

# Gleam stage - extract Gleam binary
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-scratch AS gleam

# Migration stage
FROM erlang:${ERLANG_VERSION}-alpine

# Copy Gleam binary from scratch image
COPY --from=gleam /bin/gleam /bin/gleam

# Set working directory
WORKDIR /migrate

# Copy dependency manifests first (for better layer caching)
COPY gleam.toml manifest.toml ./

# Download dependencies (includes cigogne)
RUN gleam deps download

# Copy source code and migration files
COPY src ./src
COPY priv ./priv

# Run cigogne migrations
ENTRYPOINT ["gleam", "run", "-m", "cigogne"]
CMD ["all"]
