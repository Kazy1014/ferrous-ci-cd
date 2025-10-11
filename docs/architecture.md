# Ferrous CI/CD Architecture

## Overview

Ferrous CI/CD is built following Domain-Driven Design (DDD) principles, ensuring a clean separation of concerns and maintainable codebase. The system is designed to be scalable, reliable, and extensible.

## Table of Contents

- [Architectural Principles](#architectural-principles)
- [Layer Architecture](#layer-architecture)
- [Domain Model](#domain-model)
- [System Components](#system-components)
- [Data Flow](#data-flow)
- [Deployment Architecture](#deployment-architecture)
- [Security Architecture](#security-architecture)
- [Scalability](#scalability)

## Architectural Principles

### Domain-Driven Design

The application follows DDD principles with clear boundaries between layers:

1. **Domain Layer**: Contains business logic independent of technical concerns
2. **Application Layer**: Orchestrates use cases and domain objects
3. **Infrastructure Layer**: Provides technical implementations
4. **Presentation Layer**: Exposes APIs and handles user interactions

### SOLID Principles

- **Single Responsibility**: Each module has one reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Interfaces can be substituted
- **Interface Segregation**: Clients depend on specific interfaces
- **Dependency Inversion**: Depend on abstractions, not concretions

### Key Architectural Decisions

1. **Async/Await**: All I/O operations are asynchronous using Tokio
2. **Event-Driven**: Domain events for loose coupling
3. **Repository Pattern**: Abstract data access
4. **Dependency Injection**: Through constructor injection
5. **Immutable Value Objects**: For data integrity

## Layer Architecture

```
┌─────────────────────────────────────────────────────┐
│                 Presentation Layer                   │
│         (REST API, GraphQL, CLI, Web UI)            │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│               Application Layer                      │
│     (Use Cases, DTOs, Application Services)         │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│                  Domain Layer                        │
│   (Entities, Value Objects, Domain Services,        │
│    Aggregates, Repository Interfaces, Events)       │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│              Infrastructure Layer                    │
│  (Database, File System, External APIs, Message     │
│   Queues, Repository Implementations)               │
└─────────────────────────────────────────────────────┘
```

### Dependency Rules

- **Domain Layer**: No dependencies on other layers
- **Application Layer**: Depends only on Domain layer
- **Infrastructure Layer**: Implements Domain interfaces
- **Presentation Layer**: Depends on Application layer

## Domain Model

### Core Aggregates

#### Pipeline Aggregate

```
Pipeline (Root)
├── PipelineConfig
│   ├── Stages
│   │   └── Jobs
│   └── Triggers
└── Events
```

**Responsibilities**:
- Manage pipeline configuration
- Validate pipeline structure
- Track pipeline lifecycle

#### Build Aggregate

```
Build (Root)
├── Stages
│   └── Jobs
│       ├── Logs
│       └── Artifacts
└── Events
```

**Responsibilities**:
- Execute pipeline instances
- Track build progress
- Manage job execution
- Store build artifacts

#### Agent Aggregate

```
Agent (Root)
├── Platform Info
├── Labels
└── Job Queue
```

**Responsibilities**:
- Manage agent lifecycle
- Track agent capacity
- Handle job assignment
- Monitor agent health

### Value Objects

- **BuildId, PipelineId, ProjectId, etc.**: Strongly-typed IDs
- **BuildStatus**: Enum for build states
- **PipelineConfig**: Immutable configuration
- **Platform**: Agent platform information

### Domain Events

Events are emitted for significant domain state changes:

- `BuildCreated`
- `BuildStarted`
- `BuildCompleted`
- `PipelineCreated`
- `PipelineEnabled/Disabled`
- `AgentRegistered`
- `AgentDisconnected`
- `UserCreated`

## System Components

### Core Services

#### Pipeline Service
```rust
pub struct PipelineService {
    repository: Arc<dyn PipelineRepository>,
    event_publisher: Arc<dyn EventPublisher>,
}
```

**Responsibilities**:
- Create and manage pipelines
- Validate pipeline configurations
- Enable/disable pipelines
- Publish pipeline events

#### Build Service
```rust
pub struct BuildService {
    repository: Arc<dyn BuildRepository>,
    event_publisher: Arc<dyn EventPublisher>,
}
```

**Responsibilities**:
- Create and execute builds
- Manage build lifecycle
- Track build status
- Coordinate job execution

#### Agent Service
```rust
pub struct AgentService {
    repository: Arc<dyn AgentRepository>,
    event_publisher: Arc<dyn EventPublisher>,
}
```

**Responsibilities**:
- Register and manage agents
- Monitor agent health
- Assign jobs to agents
- Clean up dead agents

### Infrastructure Components

#### Database Layer

**Supported Databases**:
- PostgreSQL (production)
- SQLite (development/testing)

**Features**:
- Connection pooling
- Automatic migrations
- Transaction support
- Query optimization

#### Storage Layer

**Artifact Storage**:
- Local file system
- S3-compatible storage
- Automatic cleanup
- Checksumming

#### Git Integration

**Features**:
- Repository cloning
- Commit fetching
- Authentication (SSH, HTTPS)
- Webhook support

#### Message Queue

**Purpose**:
- Asynchronous job processing
- Event distribution
- Worker coordination

**Supported**:
- Redis (built-in)
- RabbitMQ (via lapin)

## Data Flow

### Build Execution Flow

```
1. Trigger (Webhook/Manual/Schedule)
   │
   ▼
2. Create Build
   │
   ▼
3. Queue Build
   │
   ▼
4. Select Agent
   │
   ▼
5. Prepare Workspace
   │
   ▼
6. Execute Stages
   │ ├── Execute Jobs (parallel)
   │ ├── Collect Logs
   │ └── Store Artifacts
   │
   ▼
7. Cleanup
   │
   ▼
8. Publish Events/Notifications
```

### Event Flow

```
Domain Event
   │
   ▼
Event Publisher
   │
   ├──▶ Event Handler 1 (Notifications)
   ├──▶ Event Handler 2 (Metrics)
   ├──▶ Event Handler 3 (Webhooks)
   └──▶ Event Handler N (...)
```

### API Request Flow

```
HTTP Request
   │
   ▼
Router (Axum)
   │
   ├──▶ Authentication Middleware
   ├──▶ Authorization Middleware
   ├──▶ Rate Limiting Middleware
   ├──▶ Logging Middleware
   │
   ▼
Handler
   │
   ▼
Use Case (Application Layer)
   │
   ▼
Domain Service
   │
   ▼
Repository
   │
   ▼
Database
```

## Deployment Architecture

### Standalone Mode

```
┌─────────────────────────────┐
│    Ferrous CI/CD Server     │
│  ┌────────┐    ┌─────────┐  │
│  │  API   │    │ Agents  │  │
│  └────────┘    └─────────┘  │
│  ┌────────┐    ┌─────────┐  │
│  │   DB   │    │ Storage │  │
│  └────────┘    └─────────┘  │
└─────────────────────────────┘
```

### Distributed Mode

```
┌──────────────────────────┐
│   Load Balancer (Nginx)  │
└────────────┬─────────────┘
             │
     ┌───────┴───────┐
     │               │
┌────▼────┐    ┌────▼────┐
│ Server  │    │ Server  │
│   1     │    │   2     │
└────┬────┘    └────┬────┘
     │              │
     └──────┬───────┘
            │
   ┌────────▼────────┐
   │   PostgreSQL    │
   │   (Primary)     │
   └────────┬────────┘
            │
   ┌────────▼────────┐
   │   PostgreSQL    │
   │   (Replica)     │
   └─────────────────┘

┌─────────┐  ┌─────────┐  ┌─────────┐
│ Agent 1 │  │ Agent 2 │  │ Agent N │
└─────────┘  └─────────┘  └─────────┘
```

### Kubernetes Deployment

```
┌───────────────────────────────────┐
│         Kubernetes Cluster         │
│                                    │
│  ┌──────────────────────────────┐ │
│  │      Ferrous-Server          │ │
│  │      (Deployment)            │ │
│  │  ┌────┐ ┌────┐ ┌────┐       │ │
│  │  │Pod │ │Pod │ │Pod │       │ │
│  │  └────┘ └────┘ └────┘       │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────────────────────────┐ │
│  │      Ferrous-Agents          │ │
│  │      (DaemonSet/Jobs)        │ │
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────────────────────────┐ │
│  │      Services                │ │
│  │  - API Service               │ │
│  │  - PostgreSQL StatefulSet    │ │
│  │  - Redis                     │ │
│  └──────────────────────────────┘ │
└───────────────────────────────────┘
```

## Security Architecture

### Authentication

- **JWT Tokens**: For API authentication
- **API Keys**: For service accounts
- **OAuth2**: For third-party integrations

### Authorization

- **Role-Based Access Control (RBAC)**:
  - Admin: Full access
  - Developer: Build and deploy
  - Viewer: Read-only access
  - Service: API access

### Data Security

- **Encryption at Rest**: Database encryption
- **Encryption in Transit**: TLS 1.3
- **Secret Management**: Encrypted storage
- **Audit Logging**: All actions logged

### Network Security

- **Rate Limiting**: Per-user, per-IP
- **CORS**: Configured origins
- **Input Validation**: All inputs validated
- **SQL Injection Prevention**: Parameterized queries

## Scalability

### Horizontal Scaling

- **Stateless Servers**: Can run multiple instances
- **Distributed Agents**: Scale independently
- **Database Replication**: Read replicas
- **Caching**: Redis for performance

### Performance Optimizations

- **Async I/O**: Non-blocking operations
- **Connection Pooling**: Reuse connections
- **Query Optimization**: Indexed queries
- **Lazy Loading**: Load data as needed
- **Artifact Compression**: Reduce storage

### Monitoring

- **Metrics**: Prometheus
- **Tracing**: OpenTelemetry/Jaeger
- **Logging**: Structured JSON logs
- **Health Checks**: Kubernetes readiness/liveness

### Capacity Planning

**Recommended Resources**:

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| Server    | 2-4 cores | 4-8 GB | 20 GB |
| Agent     | 1-2 cores | 2-4 GB | 50 GB |
| Database  | 2-4 cores | 8-16 GB | 100 GB+ |

**Scaling Guidelines**:
- 1 server can handle ~100 concurrent builds
- 1 agent can run 1-5 parallel jobs
- Add agents for more concurrent builds
- Add servers for more API throughput

## Technology Stack

### Core Technologies

- **Language**: Rust 2021 Edition
- **Async Runtime**: Tokio
- **Web Framework**: Axum
- **Database**: PostgreSQL / SQLite
- **ORM**: SQLx / Diesel
- **Serialization**: Serde

### Infrastructure

- **Container**: Docker
- **Orchestration**: Kubernetes
- **Message Queue**: Redis / RabbitMQ
- **Storage**: S3-compatible
- **Git**: libgit2

### Observability

- **Metrics**: Prometheus
- **Tracing**: OpenTelemetry
- **Logging**: tracing-subscriber
- **Alerting**: Alertmanager

## Future Enhancements

### Planned Features

1. **Web UI Dashboard**: React/Vue frontend
2. **GraphQL API**: Alternative to REST
3. **ML-based Optimization**: Build time prediction
4. **Advanced Caching**: Dependency caching
5. **Multi-cloud Support**: AWS, Azure, GCP
6. **Plugin System**: Custom extensions
7. **GitOps Integration**: FluxCD, ArgoCD
8. **Matrix Builds**: Test across multiple platforms

### Performance Goals

- < 1s API response time (p95)
- < 5s build start time
- 99.9% uptime
- 10,000 builds/day per server
- Sub-second event propagation

## References

- [Domain-Driven Design](https://martinfowler.com/tags/domain%20driven%20design.html)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Rust Async Book](https://rust-lang.github.io/async-book/)
- [Tokio Documentation](https://tokio.rs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

*Last Updated: 2025-10-10*

