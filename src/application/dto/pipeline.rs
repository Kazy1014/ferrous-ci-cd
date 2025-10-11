//! Pipeline DTOs

use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PipelineDto {
    pub id: String,
    pub project_id: String,
    pub name: String,
    pub enabled: bool,
    pub created_at: DateTime<Utc>,
}

