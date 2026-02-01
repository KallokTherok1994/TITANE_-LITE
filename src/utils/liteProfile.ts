/**
 * TITANE_LITE v27 — Lite Profile Helper
 * Utilitaires pour profil lite et sync mémoire
 */

type RuntimeConfigLike = Record<string, unknown> & {
  liteProfile?: string;
  liteSyncEnabled?: boolean;
  liteSyncIntervalSec?: number;
  liteSyncOutboxDir?: string;
  liteSyncTarget?: string;
  liteSyncImportEnabled?: boolean;
  liteSyncImportDir?: string;
  liteSyncImportMode?: string;
  lite_profile?: string;
  lite_sync_enabled?: boolean;
  lite_sync_interval_sec?: number;
  lite_sync_outbox_dir?: string;
  lite_sync_target?: string;
  lite_sync_import_enabled?: boolean;
  lite_sync_import_dir?: string;
  lite_sync_import_mode?: string;
};

export type LiteProfile = 'ultra_lite' | 'lite' | 'balanced' | 'full';

export interface LiteSyncConfig {
  enabled: boolean;
  intervalSec: number;
  outboxDir?: string;
  target?: string;
}

export interface LiteSyncImportConfig {
  enabled: boolean;
  dir?: string;
  mode: 'merge' | 'replace';
}

const DEFAULT_PROFILE: LiteProfile = 'ultra_lite';
const DEFAULT_SYNC_INTERVAL_SEC = 900;

const coerceBoolean = (value: unknown): boolean => {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    return normalized === '1' || normalized === 'true' || normalized === 'yes';
  }
  if (typeof value === 'number') return value === 1;
  return false;
};

const coerceNumber = (value: unknown, fallback: number): number => {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Number.parseInt(value, 10);
    return Number.isFinite(parsed) ? parsed : fallback;
  }
  return fallback;
};

const normalizeProfile = (value: unknown): LiteProfile => {
  if (typeof value !== 'string') return DEFAULT_PROFILE;
  const normalized = value.trim().toLowerCase();
  if (normalized === 'ultra_lite' || normalized === 'ultra-lite') return 'ultra_lite';
  if (normalized === 'lite') return 'lite';
  if (normalized === 'balanced') return 'balanced';
  if (normalized === 'full') return 'full';
  return DEFAULT_PROFILE;
};

export const getRuntimeConfig = (): RuntimeConfigLike => {
  const global = globalThis as unknown as { __TITANE_RUNTIME_CONFIG__?: RuntimeConfigLike };
  return (global.__TITANE_RUNTIME_CONFIG__ ?? {}) as RuntimeConfigLike;
};

export const getLiteProfile = (): LiteProfile => {
  const runtime = getRuntimeConfig();
  const raw = runtime.liteProfile ?? runtime.lite_profile;
  return normalizeProfile(raw);
};

export const isLiteMode = (): boolean => {
  const profile = getLiteProfile();
  return profile === 'ultra_lite' || profile === 'lite' || profile === 'balanced';
};

export const getLiteSyncConfig = (): LiteSyncConfig => {
  const runtime = getRuntimeConfig();
  const enabled = coerceBoolean(runtime.liteSyncEnabled ?? runtime.lite_sync_enabled);
  const intervalSec = Math.max(
    60,
    coerceNumber(runtime.liteSyncIntervalSec ?? runtime.lite_sync_interval_sec, DEFAULT_SYNC_INTERVAL_SEC)
  );
  const outboxDir =
    typeof runtime.liteSyncOutboxDir === 'string'
      ? runtime.liteSyncOutboxDir
      : typeof runtime.lite_sync_outbox_dir === 'string'
        ? runtime.lite_sync_outbox_dir
        : undefined;
  const target =
    typeof runtime.liteSyncTarget === 'string'
      ? runtime.liteSyncTarget
      : typeof runtime.lite_sync_target === 'string'
        ? runtime.lite_sync_target
        : undefined;

  return {
    enabled,
    intervalSec,
    outboxDir,
    target,
  };
};

export const getLiteSyncImportConfig = (): LiteSyncImportConfig => {
  const runtime = getRuntimeConfig();
  const enabled = coerceBoolean(
    runtime.liteSyncImportEnabled ?? runtime.lite_sync_import_enabled
  );
  const dir =
    typeof runtime.liteSyncImportDir === 'string'
      ? runtime.liteSyncImportDir
      : typeof runtime.lite_sync_import_dir === 'string'
        ? runtime.lite_sync_import_dir
        : undefined;
  const modeRaw =
    typeof runtime.liteSyncImportMode === 'string'
      ? runtime.liteSyncImportMode
      : typeof runtime.lite_sync_import_mode === 'string'
        ? runtime.lite_sync_import_mode
        : 'merge';
  const mode = modeRaw.toLowerCase() === 'replace' ? 'replace' : 'merge';

  return {
    enabled,
    dir,
    mode,
  };
};
