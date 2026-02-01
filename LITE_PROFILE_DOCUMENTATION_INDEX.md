# 📖 TITANE Lite Profile Documentation Index

## 🎯 Start Here

**New to Lite Profile?**  
→ Start with: [Quick Start Guide](./LITE_PROFILE_QUICKSTART.md) (5 min read)

**Need Setup Help?**  
→ Read: [Complete Setup Guide](./LITE_PROFILE_SETUP.md) (30 min read)

**Want Full Details?**  
→ See: [Implementation Summary](./LITE_PROFILE_IMPLEMENTATION_SUMMARY.md) (20 min read)

---

## 📚 Documentation Files

### Quick References

| File | Purpose | Read Time | Audience |
|------|---------|-----------|----------|
| [LITE_PROFILE_QUICKSTART.md](./LITE_PROFILE_QUICKSTART.md) | Fast setup in 5-10 min | 5 min | Everyone |
| [LITE_PROFILE_SETUP.md](./LITE_PROFILE_SETUP.md) | Complete configuration guide | 30 min | DevOps/SysAdmin |
| [LITE_PROFILE_IMPLEMENTATION_SUMMARY.md](./LITE_PROFILE_IMPLEMENTATION_SUMMARY.md) | Technical deep dive | 20 min | Developers |

### Tools & Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| [`scripts/setup-lite-sync.sh`](./scripts/setup-lite-sync.sh) | Automated setup | `./scripts/setup-lite-sync.sh lite /mnt/sync` |
| [`scripts/verify-lite-sync.sh`](./scripts/verify-lite-sync.sh) | Health validation | `./scripts/verify-lite-sync.sh /mnt/sync` |

### Source Code

| File | Purpose | Lines |
|------|---------|-------|
| [`src/utils/liteProfile.ts`](./src/utils/liteProfile.ts) | Profile utilities | 273 |
| [`src-tauri/src/runtime_config.rs`](./src-tauri/src/runtime_config.rs) | Config backend | 200+ |
| [`src/main.tsx`](./src/main.tsx) | Sync initialization | ~100 new |

### Tests

| Test File | Tests | Coverage |
|-----------|-------|----------|
| [`src/__tests__/liteProfile.test.ts`](./src/__tests__/liteProfile.test.ts) | 25 tests | Profile detection, config, edge cases |
| [`src-tauri/src/runtime_config_tests.rs`](./src-tauri/src/runtime_config_tests.rs) | 14 tests | Env parsing, sanitization |

---

## 🎓 Learning Paths

### Path 1: User (5 minutes)
1. Read: [Quick Start](./LITE_PROFILE_QUICKSTART.md)
2. Run: `./scripts/setup-lite-sync.sh lite`
3. Test: `./scripts/verify-lite-sync.sh`
4. Launch: `pnpm run dev:tauri`

### Path 2: DevOps (30 minutes)
1. Read: [Setup Guide](./LITE_PROFILE_SETUP.md)
2. Configure: Environment variables + NFS/Samba
3. Deploy: Docker Compose or Kubernetes
4. Monitor: Health checks and logs

### Path 3: Developer (45 minutes)
1. Read: [Implementation Summary](./LITE_PROFILE_IMPLEMENTATION_SUMMARY.md)
2. Review: Source code (`src/utils/liteProfile.ts`, etc.)
3. Study: Tests (`src/__tests__/liteProfile.test.ts`)
4. Extend: Add new profiles or sync strategies

---

## 🔍 Find Answers

### "How do I...?"

| Question | Answer |
|----------|--------|
| Start Lite quickly? | → [Quick Start](./LITE_PROFILE_QUICKSTART.md) |
| Configure NFS sharing? | → [Setup Guide - NFS Section](./LITE_PROFILE_SETUP.md#configuration-nfs-linux) |
| Deploy multi-instance? | → [Setup Guide - Docker Compose](./LITE_PROFILE_SETUP.md#docker-compose-example) |
| Troubleshoot sync? | → [Setup Guide - Troubleshooting](./LITE_PROFILE_SETUP.md#troubleshooting) |
| Check system health? | → `./scripts/verify-lite-sync.sh -v` |
| See performance impact? | → [Implementation Summary - Benchmarks](./LITE_PROFILE_IMPLEMENTATION_SUMMARY.md#-performance-characteristics) |
| Run tests? | → `pnpm run test -- liteProfile` |
| Monitor in real-time? | → [Quick Start - Monitoring](./LITE_PROFILE_QUICKSTART.md#-monitoring) |
| Find code? | → [Implementation Summary - Files](./LITE_PROFILE_IMPLEMENTATION_SUMMARY.md#-files-modifiedcreated) |

---

## 📊 Configuration Profiles

### Profile Comparison

| Feature | Ultra Lite | Lite | Balanced | Full |
|---------|-----------|------|----------|------|
| **RAM** | ~150 MB | ~250 MB | ~400 MB | ~600 MB |
| **CPU (idle)** | ~2% | ~3% | ~5% | ~8% |
| **UI FPS** | 30 max | 45 max | 55 target | ∞ |
| **Sync** | Export | Export | N/A | Import |
| **Use Case** | IoT/Edge | Low-spec | Standard | Full featured |

### Quick Setup Commands

```bash
# Ultra Lite
export TITANE_LITE_PROFILE=ultra_lite && pnpm run dev:tauri

# Lite
export TITANE_LITE_PROFILE=lite && pnpm run dev:tauri

# Balanced (default)
export TITANE_LITE_PROFILE=balanced && pnpm run dev:tauri

# Full
export TITANE_LITE_PROFILE=full && pnpm run dev:tauri
```

---

## 🔗 Cross-References

### Configuration Variables
See: [Setup Guide - Configuration Section](./LITE_PROFILE_SETUP.md#configuration-via-environnement)

### Sync Architecture
See: [Implementation Summary - Architecture](./LITE_PROFILE_IMPLEMENTATION_SUMMARY.md#-architecture)

### Performance Data
See: [Implementation Summary - Performance](./LITE_PROFILE_IMPLEMENTATION_SUMMARY.md#-performance-characteristics)

### Deployment Examples
See: [Setup Guide - Multi-Instance](./LITE_PROFILE_SETUP.md#d%C3%A9ploiement-multi-instance)

---

## ✨ Key Features

- ✅ **Zero-Config** — Environment variables only
- ✅ **Bidirectional** — Export (Lite) + Import (Full)
- ✅ **Local-First** — No HTTP servers needed
- ✅ **Auto-Scaling** — Profile-aware optimization
- ✅ **Type-Safe** — Rust + TypeScript
- ✅ **Well-Tested** — 39 unit tests
- ✅ **Production-Ready** — Full security gates
- ✅ **Monitored** — Health checks + logging

---

## 🚀 Quick Start Commands

```bash
# Clone and setup (if needed)
git clone https://github.com/your-org/TITANE_LITE.git
cd TITANE_LITE

# 1. Generate environment
./scripts/setup-lite-sync.sh lite /tmp/sync

# 2. Activate
source .env.lite-lite

# 3. Install and run
pnpm install
pnpm run dev:tauri

# 4. In another terminal, verify
./scripts/verify-lite-sync.sh /tmp/sync
```

---

## 📱 API Reference

### Environment Variables (Complete List)

```bash
# Profile selection
TITANE_LITE_PROFILE=ultra_lite|lite|balanced|full

# Export (Lite instances)
TITANE_LITE_SYNC_ENABLED=true|false
TITANE_LITE_SYNC_INTERVAL_SEC=900
TITANE_LITE_SYNC_OUTBOX_DIR=/mnt/sync/outbox
TITANE_LITE_SYNC_TARGET=FULL

# Import (Full instances)
TITANE_LITE_SYNC_IMPORT_ENABLED=true|false
TITANE_LITE_SYNC_IMPORT_DIR=/mnt/sync/import
TITANE_LITE_SYNC_IMPORT_MODE=merge|replace
```

### Tauri Commands

```bash
# Export memory (Lite)
POST /api/commands/titan_memory_doctor_export
Body: {"path": "/path/to/backup.tar.gz"}

# Import latest (Full)
POST /api/commands/titan_import_latest_from_dir
Body: {"dir": "/mnt/sync/import", "mode": "merge"}
```

### Runtime Config API

```bash
# Get current config
GET http://localhost:3000/api/runtime-config

# Response example
{
  "lite_profile": "lite",
  "lite_sync_enabled": true,
  "lite_sync_interval_sec": 900,
  "lite_sync_outbox_dir": "/mnt/sync/outbox",
  "lite_sync_target": "FULL",
  "lite_sync_import_enabled": true,
  "lite_sync_import_dir": "/mnt/sync/import",
  "lite_sync_import_mode": "merge"
}
```

---

## 🔐 Security & Compliance

- ✅ Tauri command authorization verified
- ✅ Permission model (755 directories)
- ✅ Archive validation (MANIFEST.json)
- ✅ No credentials stored
- ✅ Type-safe serialization
- ✅ Error handling for corrupt files

See: [Implementation Summary - Security](./LITE_PROFILE_IMPLEMENTATION_SUMMARY.md#-security-considerations)

---

## 📈 Performance & Benchmarks

### Startup Time
- Ultra Lite: ~800ms
- Lite: ~1s
- Balanced: ~1.2s
- Full: ~1.5s

### Idle RAM
- Ultra Lite: ~150 MB
- Lite: ~250 MB
- Balanced: ~400 MB
- Full: ~600 MB

### Sync Performance
- Export: ~2s for 50MB
- Import: ~1.2s for 50MB

See: [Implementation Summary - Benchmarks](./LITE_PROFILE_IMPLEMENTATION_SUMMARY.md#performance-characteristics)

---

## 🧪 Testing

### Run All Tests
```bash
pnpm run test                          # TypeScript tests
cargo test                             # Rust tests
pnpm run test:e2e                      # End-to-end
```

### Run Specific Tests
```bash
pnpm run test -- liteProfile           # Lite profile tests only
cargo test runtime_config_tests        # Config tests only
```

### Test Coverage
- 25 TypeScript tests
- 14 Rust tests
- Full integration scenarios

---

## 📞 Support & Help

### Immediate Help
- `./scripts/setup-lite-sync.sh -h`
- `./scripts/verify-lite-sync.sh -h`
- `env | grep TITANE_LITE`

### Documentation
1. [Quick Start](./LITE_PROFILE_QUICKSTART.md) — 5 min reference
2. [Setup Guide](./LITE_PROFILE_SETUP.md) — Complete guide
3. [Implementation](./LITE_PROFILE_IMPLEMENTATION_SUMMARY.md) — Technical details

### Logs & Debugging
```bash
tail -f ~/.titane/logs/app.log
RUST_LOG=debug pnpm run dev:tauri
./scripts/verify-lite-sync.sh -v
```

---

## ✅ Next Steps

1. **Start Now:** [Quick Start Guide](./LITE_PROFILE_QUICKSTART.md)
2. **Then Setup:** `./scripts/setup-lite-sync.sh lite`
3. **Then Validate:** `./scripts/verify-lite-sync.sh`
4. **Then Deploy:** Follow [Setup Guide](./LITE_PROFILE_SETUP.md)
5. **Then Monitor:** Use provided monitoring commands

---

## 📋 File Directory

```
TITANE_LITE/
├── 📄 LITE_PROFILE_QUICKSTART.md           [Quick 5-min setup]
├── 📄 LITE_PROFILE_SETUP.md                [Complete guide]
├── 📄 LITE_PROFILE_IMPLEMENTATION_SUMMARY.md [Technical details]
├── 📄 LITE_PROFILE_DOCUMENTATION_INDEX.md  [This file]
│
├── scripts/
│   ├── setup-lite-sync.sh                  [Automated setup]
│   └── verify-lite-sync.sh                 [Health checks]
│
├── src/
│   ├── utils/liteProfile.ts               [Core utilities]
│   ├── main.tsx                            [Sync initialization]
│   ├── visual-engine/                      [UI optimization]
│   └── __tests__/                          [Unit tests]
│
└── src-tauri/
    ├── src/
    │   ├── runtime_config.rs              [Config backend]
    │   ├── performance/                   [Thread tuning]
    │   ├── ai/                            [AI concurrency]
    │   └── persistence/                   [Sync commands]
    └── tests/
        └── runtime_config_tests.rs        [Rust tests]
```

---

**Last Updated:** 31 janvier 2026  
**Version:** 1.0  
**Status:** ✅ Complete and Production-Ready

🎉 **Welcome to TITANE Lite Profile System!**
