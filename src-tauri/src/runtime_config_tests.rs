#[cfg(test)]
mod lite_profile_tests {
    use crate::runtime_config::*;
    use std::env;

    #[test]
    fn test_sanitize_lite_profile_valid_profiles() {
        assert_eq!(sanitize_lite_profile("ultra_lite"), "ultra_lite");
        assert_eq!(sanitize_lite_profile("lite"), "lite");
        assert_eq!(sanitize_lite_profile("balanced"), "balanced");
        assert_eq!(sanitize_lite_profile("full"), "full");
    }

    #[test]
    fn test_sanitize_lite_profile_invalid_defaults_to_balanced() {
        assert_eq!(sanitize_lite_profile("invalid"), "balanced");
        assert_eq!(sanitize_lite_profile(""), "balanced");
        assert_eq!(sanitize_lite_profile("ULTRA_LITE"), "balanced");
    }

    #[test]
    fn test_parse_bool_env_true_values() {
        env::set_var("TEST_BOOL_TRUE", "true");
        assert_eq!(parse_bool_env("TEST_BOOL_TRUE", false), true);

        env::set_var("TEST_BOOL_1", "1");
        assert_eq!(parse_bool_env("TEST_BOOL_1", false), true);

        env::set_var("TEST_BOOL_YES", "yes");
        assert_eq!(parse_bool_env("TEST_BOOL_YES", false), true);
    }

    #[test]
    fn test_parse_bool_env_false_values() {
        env::set_var("TEST_BOOL_FALSE", "false");
        assert_eq!(parse_bool_env("TEST_BOOL_FALSE", true), false);

        env::set_var("TEST_BOOL_0", "0");
        assert_eq!(parse_bool_env("TEST_BOOL_0", true), false);

        env::set_var("TEST_BOOL_NO", "no");
        assert_eq!(parse_bool_env("TEST_BOOL_NO", true), false);
    }

    #[test]
    fn test_parse_bool_env_missing_uses_default() {
        env::remove_var("TEST_BOOL_MISSING");
        assert_eq!(parse_bool_env("TEST_BOOL_MISSING", true), true);
        assert_eq!(parse_bool_env("TEST_BOOL_MISSING", false), false);
    }

    #[test]
    fn test_runtime_config_lite_profile_field() {
        env::set_var("TITANE_LITE_PROFILE", "lite");
        let config = RuntimeConfig {
            lite_profile: "lite".to_string(),
            ..Default::default()
        };
        assert_eq!(config.lite_profile, "lite");
    }

    #[test]
    fn test_runtime_config_lite_sync_enabled() {
        env::set_var("TITANE_LITE_SYNC_ENABLED", "true");
        let config = RuntimeConfig {
            lite_sync_enabled: true,
            ..Default::default()
        };
        assert_eq!(config.lite_sync_enabled, true);
    }

    #[test]
    fn test_runtime_config_lite_sync_interval() {
        env::set_var("TITANE_LITE_SYNC_INTERVAL_SEC", "600");
        let config = RuntimeConfig {
            lite_sync_interval_sec: 600,
            ..Default::default()
        };
        assert_eq!(config.lite_sync_interval_sec, 600);
    }

    #[test]
    fn test_runtime_config_lite_sync_outbox_dir() {
        env::set_var("TITANE_LITE_SYNC_OUTBOX_DIR", "/tmp/sync/outbox");
        let config = RuntimeConfig {
            lite_sync_outbox_dir: "/tmp/sync/outbox".to_string(),
            ..Default::default()
        };
        assert_eq!(config.lite_sync_outbox_dir, "/tmp/sync/outbox");
    }

    #[test]
    fn test_runtime_config_lite_sync_target() {
        env::set_var("TITANE_LITE_SYNC_TARGET", "FULL");
        let config = RuntimeConfig {
            lite_sync_target: "FULL".to_string(),
            ..Default::default()
        };
        assert_eq!(config.lite_sync_target, "FULL");
    }

    #[test]
    fn test_runtime_config_lite_import_enabled() {
        env::set_var("TITANE_LITE_SYNC_IMPORT_ENABLED", "true");
        let config = RuntimeConfig {
            lite_sync_import_enabled: true,
            ..Default::default()
        };
        assert_eq!(config.lite_sync_import_enabled, true);
    }

    #[test]
    fn test_runtime_config_lite_import_dir() {
        env::set_var("TITANE_LITE_SYNC_IMPORT_DIR", "/tmp/sync/import");
        let config = RuntimeConfig {
            lite_sync_import_dir: "/tmp/sync/import".to_string(),
            ..Default::default()
        };
        assert_eq!(config.lite_sync_import_dir, "/tmp/sync/import");
    }

    #[test]
    fn test_runtime_config_lite_import_mode() {
        env::set_var("TITANE_LITE_SYNC_IMPORT_MODE", "replace");
        let config = RuntimeConfig {
            lite_sync_import_mode: "replace".to_string(),
            ..Default::default()
        };
        assert_eq!(config.lite_sync_import_mode, "replace");
    }

    #[test]
    fn test_default_sync_outbox_dir() {
        let outbox = default_sync_outbox_dir();
        assert!(!outbox.is_empty());
        assert!(outbox.contains("titane") || outbox.contains("sync"));
    }
}
