//! Integration tests for Ferrous CI/CD

use ferrous_ci_cd::{init, Config};

#[tokio::test]
async fn test_initialization() {
    let result = init().await;
    assert!(result.is_ok(), "Initialization should succeed");
}

#[tokio::test]
async fn test_default_config() {
    let config = Config::default();
    assert!(config.validate().is_ok(), "Default config should be valid");
}

// Additional integration tests would go here
// These would test the complete system with real database connections
// and end-to-end workflows

