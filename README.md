# Ferrous CI/CD 🦀🚀

[![Build Status](https://img.shields.io/github/actions/workflow/status/yourusername/ferrous-ci-cd/ci.yml?branch=main)](https://github.com/yourusername/ferrous-ci-cd/actions)
[![Crates.io](https://img.shields.io/crates/v/ferrous-ci-cd.svg)](https://crates.io/crates/ferrous-ci-cd)
[![Documentation](https://docs.rs/ferrous-ci-cd/badge.svg)](https://docs.rs/ferrous-ci-cd)
[![License](https://img.shields.io/badge/license-MIT%2FApache--2.0-blue.svg)](LICENSE)
[![codecov](https://codecov.io/gh/yourusername/ferrous-ci-cd/branch/main/graph/badge.svg)](https://codecov.io/gh/yourusername/ferrous-ci-cd)

A modern, high-performance CI/CD system built with Rust, inspired by Jenkins but designed for the cloud-native era.

## 🌟 Features

- **🚀 High Performance**: Built with Rust for maximum performance and reliability
- **📦 Container-Native**: First-class Docker and Kubernetes support
- **🔄 Pipeline as Code**: Define your CI/CD pipelines in YAML or TOML
- **🎯 Domain-Driven Design**: Clean architecture following DDD principles
- **🔌 Extensible**: Plugin system for custom integrations
- **🔐 Secure**: Built-in authentication and authorization
- **📊 Observability**: Comprehensive metrics and tracing
- **🌍 Distributed**: Support for distributed builds across multiple agents
- **💾 Multiple Storage Backends**: PostgreSQL, SQLite support
- **🔔 Notifications**: Webhook, email, and Slack notifications

## 📋 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Architecture](#-architecture)
- [Development](#-development)
- [Contributing](#-contributing)
- [License](#-license)

## 🚀 Quick Start

### Prerequisites

- Rust 1.75+ (install via [rustup](https://rustup.rs/))
- Docker (optional, for containerized builds)
- PostgreSQL or SQLite

### Installation from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/ferrous-ci-cd.git
cd ferrous-ci-cd

# Build the project
cargo build --release

# Run tests
cargo test

# Start the server
cargo run --release
```

### Docker Installation

```bash
# Using Docker
docker run -d \
  -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ferrous-data:/data \
  ferrous/ferrous-ci-cd:latest

# Using Docker Compose
docker-compose up -d
```

## ⚙️ Configuration

Create a `config.yaml` file:

```yaml
server:
  host: "0.0.0.0"
  port: 8080
  workers: 4

database:
  type: "postgres" # or "sqlite"
  url: "postgresql://user:password@localhost/ferrous_ci"
  max_connections: 10

storage:
  artifacts_path: "./artifacts"
  workspace_path: "./workspace"

security:
  jwt_secret: "your-secret-key"
  session_timeout: 3600

git:
  ssh_key_path: "~/.ssh/id_rsa"
  
agents:
  max_concurrent_builds: 5
  heartbeat_interval: 30
```

## 📖 Usage

### Define a Pipeline

Create a `.ferrous-ci.yaml` file in your repository:

```yaml
name: "My Application Pipeline"
version: "1.0"

triggers:
  - push:
      branches: ["main", "develop"]
  - pull_request:
      branches: ["main"]
  - schedule:
      cron: "0 0 * * *"

environment:
  RUST_VERSION: "1.75"
  NODE_VERSION: "20"

stages:
  - name: build
    parallel:
      - name: rust-build
        image: rust:1.75
        commands:
          - cargo build --release
          - cargo test
        artifacts:
          paths:
            - target/release/*
            
      - name: frontend-build
        image: node:20
        commands:
          - npm ci
          - npm run build
          - npm test
        artifacts:
          paths:
            - dist/*

  - name: test
    needs: [build]
    matrix:
      os: [ubuntu-latest, windows-latest, macos-latest]
    steps:
      - name: integration-tests
        image: rust:1.75
        commands:
          - cargo test --test integration

  - name: deploy
    needs: [test]
    when:
      branch: main
      event: push
    steps:
      - name: deploy-production
        commands:
          - ./scripts/deploy.sh production
```

### CLI Usage

```bash
# Login to the server
ferrous-ci login --server http://localhost:8080

# Create a new project
ferrous-ci project create --name my-app --repo https://github.com/user/repo

# Trigger a build
ferrous-ci build trigger --project my-app --branch main

# View build logs
ferrous-ci build logs --project my-app --build-id 123

# List running builds
ferrous-ci build list --status running

# Manage agents
ferrous-ci agent list
ferrous-ci agent register --name agent-01 --labels "os=linux,arch=x86_64"
```

### API Usage

```bash
# Trigger a build via API
curl -X POST http://localhost:8080/api/v1/projects/my-app/builds \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"branch": "main", "commit": "abc123"}'

# Get build status
curl http://localhost:8080/api/v1/builds/123 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🏗️ Architecture

Ferrous CI/CD follows Domain-Driven Design (DDD) principles:

```
┌─────────────────────────────────────────────────────┐
│                   Presentation Layer                 │
│         (REST API, GraphQL, CLI, Web UI)            │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│                 Application Layer                    │
│     (Use Cases, DTOs, Application Services)         │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│                    Domain Layer                      │
│   (Entities, Value Objects, Domain Services,        │
│    Aggregates, Repository Interfaces)               │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│                Infrastructure Layer                  │
│  (Database, File System, External APIs, Message     │
│   Queues, Repository Implementations)               │
└─────────────────────────────────────────────────────┘
```

### Core Domain Concepts

- **Pipeline**: The core aggregate representing a CI/CD pipeline
- **Build**: An execution instance of a pipeline
- **Stage**: A phase in the pipeline execution
- **Job**: A unit of work within a stage
- **Agent**: A worker that executes jobs
- **Artifact**: Build outputs stored for later use
- **Workspace**: The working directory for build execution

## 🧪 Development

### Running Tests

```bash
# Run all tests
cargo test

# Run with coverage
cargo tarpaulin --out Html --output-dir coverage

# Run specific test suite
cargo test --test integration

# Run benchmarks
cargo bench
```

### Code Quality

```bash
# Format code
cargo fmt

# Lint code
cargo clippy -- -D warnings

# Security audit
cargo audit

# Check dependencies
cargo outdated
```

### Building Documentation

```bash
# Generate documentation
cargo doc --no-deps --open

# Generate mdBook documentation
mdbook build docs/
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Install development dependencies
cargo install cargo-watch cargo-tarpaulin cargo-audit cargo-outdated

# Run in development mode with auto-reload
cargo watch -x run

# Run tests on file change
cargo watch -x test
```

## 📚 Documentation

- [Architecture Overview](docs/architecture.md)
- [API Documentation](docs/api.md)
- [Plugin Development](docs/plugins.md)
- [Configuration Guide](docs/configuration.md)
- [Migration Guide](docs/migration.md)

## 🗺️ Roadmap

- [ ] Web UI Dashboard
- [ ] GraphQL API
- [ ] Kubernetes Operator
- [ ] Multi-cloud support (AWS, Azure, GCP)
- [ ] Advanced caching strategies
- [ ] Machine learning-based build optimization
- [ ] GitOps integration
- [ ] Terraform provider

## 📄 License

This project is licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

## 🙏 Acknowledgments

- Inspired by [Jenkins](https://www.jenkins.io/), [GitLab CI](https://docs.gitlab.com/ee/ci/), and [GitHub Actions](https://github.com/features/actions)
- Built with amazing Rust ecosystem crates
- Thanks to all contributors!

## 📧 Contact

- **Issue Tracker**: [GitHub Issues](https://github.com/yourusername/ferrous-ci-cd/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/ferrous-ci-cd/discussions)
- **Discord**: [Join our community](https://discord.gg/ferrous-ci-cd)

---

<div align="center">
  Made with ❤️ and 🦀 by the Ferrous CI/CD Team
</div>
