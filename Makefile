# Ferrous CI/CD Makefile

.PHONY: help build test test-unit test-integration test-e2e test-all lint fmt check clean run docker-up docker-down

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the project
	cargo build --release

test: ## Run all tests (unit + integration, excluding E2E)
	cargo test

test-unit: ## Run only unit tests
	cargo test --lib

test-integration: ## Run only integration tests
	cargo test --tests --exclude e2e_tests

test-e2e: docker-up ## Run E2E tests (requires infrastructure)
	@echo "Waiting for services to be ready..."
	@sleep 3
	cargo test --test e2e_tests -- --ignored --test-threads=1 --nocapture
	@make docker-down

test-all: ## Run all tests including E2E
	@make test
	@make test-e2e

test-stress: ## Run stress tests
	cargo test --tests -- --ignored

lint: ## Run clippy
	cargo clippy -- -D warnings

fmt: ## Format code
	cargo fmt

fmt-check: ## Check code formatting
	cargo fmt -- --check

check: fmt-check lint test ## Run all checks (format, lint, test)

clean: ## Clean build artifacts
	cargo clean
	rm -rf target/

run: ## Run the application
	cargo run -- server

run-dev: ## Run in development mode with auto-reload
	cargo watch -x 'run -- server'

docker-up: ## Start Docker services (postgres, redis)
	docker-compose up -d postgres redis
	@echo "Waiting for services to start..."
	@sleep 2

docker-down: ## Stop Docker services
	docker-compose down

docker-clean: ## Remove Docker volumes
	docker-compose down -v

docker-logs: ## Show Docker logs
	docker-compose logs -f

coverage: ## Generate test coverage report
	cargo tarpaulin --out Html --output-dir coverage

bench: ## Run benchmarks
	cargo bench

install: ## Install the binary
	cargo install --path .

# Development shortcuts
dev-setup: docker-up ## Setup development environment
	@echo "Development environment ready!"

dev-teardown: docker-down ## Teardown development environment
	@echo "Development environment stopped"

# CI targets
ci-test: ## Run CI tests
	cargo test --all-features

ci-check: fmt-check lint ## Run CI checks
	cargo build --release

# Statistics
stats: ## Show project statistics
	@echo "=== Code Statistics ==="
	@find src -name "*.rs" | xargs wc -l | tail -1
	@echo ""
	@echo "=== Test Statistics ==="
	@find tests -name "*.rs" | xargs wc -l | tail -1
	@echo ""
	@echo "=== Test Count ==="
	@cargo test --tests -- --list 2>/dev/null | grep -E "test " | wc -l | xargs echo "Total tests:"

