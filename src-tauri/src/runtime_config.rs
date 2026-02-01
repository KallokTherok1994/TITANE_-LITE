// ═══════════════════════════════════════════════════════════════
//   TITANE∞ v∞ — RUNTIME CONFIGURATION BRIDGE
//   Fournit au frontend une configuration runtime sans secrets
// ═══════════════════════════════════════════════════════════════

use crate::security::secrets_engine::{SecretsMode, SecureSecretsEngine};
use serde::Serialize;
use std::time::{SystemTime, UNIX_EPOCH};
use tauri::State;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct RuntimeConfig {
    pub ollama_url: String,
    pub ollama_model: String,
    pub secrets_mode: String,
    pub gemini_configured: bool,
    pub lite_profile: String,
    pub lite_sync_enabled: bool,
    pub lite_sync_interval_sec: u64,
    pub lite_sync_outbox_dir: String,
    pub lite_sync_target: String,
    pub lite_sync_import_enabled: bool,
    pub lite_sync_import_dir: String,
    pub lite_sync_import_mode: String,
    pub timestamp: u64,
}

fn now_ts() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

fn sanitize_url(url: &str) -> String {
    // Ne pas retourner de chaîne vide (frontend attend un URL)
    let trimmed = url.trim();
    if trimmed.is_empty() {
        "http://127.0.0.1:11434".to_string()
    } else {
        trimmed.to_string()
    }
}

fn sanitize_model(model: &str) -> String {
    let trimmed = model.trim();
    if trimmed.is_empty() {
        "llama3.1".to_string()
    } else {
        trimmed.to_string()
    }
}

fn sanitize_lite_profile(profile: &str) -> String {
    let trimmed = profile.trim().to_lowercase();
    match trimmed.as_str() {
        "ultra_lite" | "ultra-lite" => "ultra_lite".to_string(),
        "lite" => "lite".to_string(),
        "balanced" => "balanced".to_string(),
        "full" => "full".to_string(),
        _ => "ultra_lite".to_string(),
    }
}

fn parse_bool_env(value: &str) -> bool {
    matches!(
        value.trim().to_lowercase().as_str(),
        "1" | "true" | "yes"
    )
}

fn default_sync_outbox_dir() -> String {
    let mut base = dirs::data_local_dir().unwrap_or_else(|| std::path::PathBuf::from("."));
    base.push("TITANE_LITE");
    base.push("sync");
    base.push("outbox");
    base.to_string_lossy().to_string()
}

fn collect_runtime_config(secrets: &SecureSecretsEngine) -> RuntimeConfig {
    // Prefer canonical names (OLLAMA_BASE_URL / OLLAMA_DEFAULT_MODEL), but keep
    // backward compatibility with legacy (OLLAMA_URL / OLLAMA_MODEL).
    let ollama_url = std::env::var("OLLAMA_BASE_URL")
        .or_else(|_| std::env::var("OLLAMA_URL"))
        .unwrap_or_else(|_| "http://127.0.0.1:11434".to_string());

    let ollama_model = std::env::var("OLLAMA_DEFAULT_MODEL")
        .or_else(|_| std::env::var("OLLAMA_MODEL"))
        .unwrap_or_else(|_| "llama3.1".to_string());

    let secrets_mode = match secrets.mode() {
        SecretsMode::Encrypted { .. } => "encrypted".to_string(),
        SecretsMode::Ephemeral => "ephemeral".to_string(),
    };

    let gemini_configured = match secrets.has_secret("gemini_api_key") {
        Ok(exists) => exists,
        Err(err) => {
            log::warn!("[RuntimeConfig] Failed to inspect secrets store: {}", err);
            false
        }
    };

    let lite_profile_raw = std::env::var("TITANE_LITE_PROFILE").unwrap_or_else(|_| "ultra_lite".to_string());
    let lite_profile = sanitize_lite_profile(&lite_profile_raw);

    let lite_sync_enabled = std::env::var("TITANE_LITE_SYNC_ENABLED")
        .map(|value| parse_bool_env(&value))
        .unwrap_or(true);

    let lite_sync_interval_sec = std::env::var("TITANE_LITE_SYNC_INTERVAL_SEC")
        .ok()
        .and_then(|value| value.parse::<u64>().ok())
        .unwrap_or(900);

    let lite_sync_outbox_dir = std::env::var("TITANE_LITE_SYNC_OUTBOX_DIR")
        .or_else(|_| std::env::var("TITANE_LITE_SYNC_OUTBOX"))
        .unwrap_or_else(|_| default_sync_outbox_dir());

    let lite_sync_target = std::env::var("TITANE_LITE_SYNC_TARGET").unwrap_or_else(|_| "".to_string());

    let lite_sync_import_dir = std::env::var("TITANE_LITE_SYNC_IMPORT_DIR").unwrap_or_else(|_| "".to_string());
    let lite_sync_import_enabled = std::env::var("TITANE_LITE_SYNC_IMPORT_ENABLED")
        .map(|value| parse_bool_env(&value))
        .unwrap_or_else(|_| !lite_sync_import_dir.trim().is_empty());
    let lite_sync_import_mode = std::env::var("TITANE_LITE_SYNC_IMPORT_MODE")
        .unwrap_or_else(|_| "merge".to_string());

    RuntimeConfig {
        ollama_url: sanitize_url(&ollama_url),
        ollama_model: sanitize_model(&ollama_model),
        secrets_mode,
        gemini_configured,
        lite_profile,
        lite_sync_enabled,
        lite_sync_interval_sec,
        lite_sync_outbox_dir,
        lite_sync_target,
        lite_sync_import_enabled,
        lite_sync_import_dir,
        lite_sync_import_mode,
        timestamp: now_ts(),
    }
}

#[tauri::command]
pub async fn get_runtime_config(
    secrets: State<'_, SecureSecretsEngine>,
) -> Result<RuntimeConfig, String> {
    Ok(collect_runtime_config(&secrets))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_collect_runtime_config_defaults() {
        let engine = SecureSecretsEngine::default();
        let config = collect_runtime_config(&engine);
        assert_eq!(config.ollama_url, "http://127.0.0.1:11434");
        assert_eq!(config.ollama_model, "llama3.1");
        assert_eq!(config.secrets_mode, "ephemeral");
        assert!(!config.gemini_configured);
        assert_eq!(config.lite_profile, "ultra_lite");
        assert!(config.lite_sync_enabled);
        assert!(config.lite_sync_interval_sec >= 900);
        assert!(!config.lite_sync_outbox_dir.is_empty());
        assert_eq!(config.lite_sync_import_mode, "merge");
    }
}
