# Multi-stage Dockerfile for Ferrous CI/CD

# Builder stage
FROM rust:1.75-slim as builder

WORKDIR /usr/src/ferrous-ci-cd

# Install dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Build dependencies (cached layer)
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    echo "fn main() {}" > src/lib.rs && \
    cargo build --release && \
    rm -rf src

# Copy source code
COPY src ./src

# Build application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy binary from builder
COPY --from=builder /usr/src/ferrous-ci-cd/target/release/ferrous-ci-cd /usr/local/bin/ferrous-ci-cd

# Create necessary directories
RUN mkdir -p /app/artifacts /app/workspace /app/cache

# Create non-root user
RUN useradd -m -u 1000 ferrous && \
    chown -R ferrous:ferrous /app

USER ferrous

# Expose ports
EXPOSE 8080
EXPOSE 9090

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Set environment variables
ENV RUST_LOG=info
ENV RUST_BACKTRACE=1

# Run the binary
ENTRYPOINT ["ferrous-ci-cd"]
CMD ["server"]

