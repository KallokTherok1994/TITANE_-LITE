/**
 * Tests for Lite Profile System
 * Validates profile detection, configuration, and environment variable handling
 */

import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import {
  getLiteProfile,
  isLiteMode,
  getLiteSyncConfig,
  getLiteSyncImportConfig,
} from "../utils/liteProfile";

describe("Lite Profile System", () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
    // Clear any cached values
    delete (global as any).__TITANE_RUNTIME_CONFIG__;
  });

  afterEach(() => {
    process.env = originalEnv;
    delete (global as any).__TITANE_RUNTIME_CONFIG__;
  });

  describe("Profile Detection", () => {
    it("should detect ultra_lite profile", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "ultra_lite",
      };
      const profile = getLiteProfile();
      expect(profile).toBe("ultra_lite");
    });

    it("should detect lite profile", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "lite",
      };
      const profile = getLiteProfile();
      expect(profile).toBe("lite");
    });

    it("should detect balanced profile", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "balanced",
      };
      const profile = getLiteProfile();
      expect(profile).toBe("balanced");
    });

    it("should detect full profile", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "full",
      };
      const profile = getLiteProfile();
      expect(profile).toBe("full");
    });

    it("should default to balanced when not specified", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {};
      const profile = getLiteProfile();
      expect(profile).toBe("balanced");
    });

    it("should handle missing runtime config gracefully", () => {
      delete (global as any).__TITANE_RUNTIME_CONFIG__;
      const profile = getLiteProfile();
      expect(profile).toBe("balanced");
    });
  });

  describe("Mode Detection", () => {
    it("should identify ultra_lite as lite mode", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "ultra_lite",
      };
      expect(isLiteMode()).toBe(true);
    });

    it("should identify lite as lite mode", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "lite",
      };
      expect(isLiteMode()).toBe(true);
    });

    it("should identify balanced as not lite mode", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "balanced",
      };
      expect(isLiteMode()).toBe(false);
    });

    it("should identify full as not lite mode", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "full",
      };
      expect(isLiteMode()).toBe(false);
    });
  });

  describe("Sync Configuration", () => {
    it("should provide sync export config when enabled", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "lite",
        lite_sync_enabled: true,
        lite_sync_interval_sec: 900,
        lite_sync_outbox_dir: "/tmp/titane-sync/outbox",
        lite_sync_target: "FULL",
      };
      const config = getLiteSyncConfig();
      expect(config.enabled).toBe(true);
      expect(config.intervalSec).toBe(900);
      expect(config.outboxDir).toContain("outbox");
      expect(config.target).toBe("FULL");
    });

    it("should respect custom sync interval", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_sync_enabled: true,
        lite_sync_interval_sec: 600,
        lite_sync_outbox_dir: "/tmp/sync",
        lite_sync_target: "FULL",
      };
      const config = getLiteSyncConfig();
      expect(config.intervalSec).toBe(600);
    });

    it("should disable sync when flag is false", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_sync_enabled: false,
      };
      const config = getLiteSyncConfig();
      expect(config.enabled).toBe(false);
    });

    it("should provide default sync config", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_sync_enabled: true,
      };
      const config = getLiteSyncConfig();
      expect(config.enabled).toBe(true);
      expect(config.intervalSec).toBeGreaterThan(0);
    });
  });

  describe("Import Configuration", () => {
    it("should provide import config when enabled", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_sync_import_enabled: true,
        lite_sync_import_dir: "/tmp/titane-sync/import",
        lite_sync_import_mode: "merge",
      };
      const config = getLiteSyncImportConfig();
      expect(config.enabled).toBe(true);
      expect(config.dir).toContain("import");
      expect(config.mode).toBe("merge");
    });

    it("should support replace mode", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_sync_import_enabled: true,
        lite_sync_import_dir: "/tmp/import",
        lite_sync_import_mode: "replace",
      };
      const config = getLiteSyncImportConfig();
      expect(config.mode).toBe("replace");
    });

    it("should default merge mode when not specified", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_sync_import_enabled: true,
        lite_sync_import_dir: "/tmp/import",
      };
      const config = getLiteSyncImportConfig();
      expect(config.mode).toBe("merge");
    });

    it("should disable import when flag is false", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_sync_import_enabled: false,
      };
      const config = getLiteSyncImportConfig();
      expect(config.enabled).toBe(false);
    });
  });

  describe("Profile-based Behavior", () => {
    it("ultra_lite should have sync enabled by default", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "ultra_lite",
        lite_sync_enabled: true,
      };
      expect(isLiteMode()).toBe(true);
      const config = getLiteSyncConfig();
      expect(config.enabled).toBe(true);
    });

    it("full profile should have sync disabled by default", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "full",
        lite_sync_enabled: false,
      };
      expect(isLiteMode()).toBe(false);
      const config = getLiteSyncConfig();
      expect(config.enabled).toBe(false);
    });

    it("should allow per-instance configuration override", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "balanced",
        lite_sync_enabled: true, // Override default
        lite_sync_target: "CUSTOM_INSTANCE",
      };
      const config = getLiteSyncConfig();
      expect(config.enabled).toBe(true);
      expect(config.target).toBe("CUSTOM_INSTANCE");
    });
  });

  describe("Edge Cases", () => {
    it("should handle null runtime config", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = null;
      const profile = getLiteProfile();
      expect(profile).toBe("balanced");
    });

    it("should handle undefined fields gracefully", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_profile: "lite",
      };
      const syncConfig = getLiteSyncConfig();
      expect(syncConfig).toBeDefined();
      expect(syncConfig.enabled).toBeDefined();
    });

    it("should preserve trailing slashes in paths", () => {
      (global as any).__TITANE_RUNTIME_CONFIG__ = {
        lite_sync_enabled: true,
        lite_sync_outbox_dir: "/tmp/sync/outbox/",
        lite_sync_target: "FULL",
      };
      const config = getLiteSyncConfig();
      expect(config.outboxDir).toBe("/tmp/sync/outbox/");
    });
  });
});
