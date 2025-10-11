//! Build DTOs

use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BuildDto {
    pub id: String,
    pub pipeline_id: String,
    pub project_id: String,
    pub number: u64,
    pub status: String,
    pub commit_sha: String,
    pub branch: String,
    pub created_at: DateTime<Utc>,
}

