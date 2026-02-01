# Archive Index - TITANE v27-v37 Legacy

This directory contains all legacy documentation, scripts, logs, and migration files from TITANE versions 27 through 37. These files are preserved for historical reference and can be recovered if needed.

---

## Archive Structure

```
.github/archive/
├── v37_legacy_docs/         # Legacy documentation (v27-v37)
├── v37_legacy_scripts/      # Deployment and test scripts
├── v37_logs/                # Build logs and artifacts
├── v37_migrations/          # Migration guides and reports
└── ARCHIVE_INDEX.md         # This file
```

---

## v37_legacy_docs/ (36 files, ~300 KB)

**Contents:**
- All documentation files from v27.0.0 through v37.x
- Executive summaries from each major version
- Audit reports and compliance documents
- Optimization guides and benchmarks
- Migration guides between versions
- Technical specifications from legacy versions

**When to use:**
- Understanding historical decisions
- Reference architecture from specific versions
- Audit trail for compliance
- Learning version progression

**Example files:**
- `V27_*.md` - Version 27 documentation
- `V37_*.md` - Version 37 documentation
- `EXECUTIVE_SUMMARY_v27_*.md` - Phase summaries
- `OPTIMIZATION_REPORT_*.md` - Performance reports
- `AUDIT_*.md` - Compliance audits

**To recover a file:**
```bash
cp .github/archive/v37_legacy_docs/FILE.md FILE.md
# Then review and integrate as needed
```

---

## v37_legacy_scripts/ (29 files, ~200 KB)

**Contents:**
- Deployment automation scripts (v27-v37)
- Test verification scripts
- Build helper scripts
- Migration automation scripts
- Verification and health-check scripts

**When to use:**
- Understanding how deployments worked in previous versions
- Replicating legacy build processes for compatibility
- Debugging version-specific issues
- Audit trail for deployment history

**Script categories:**
- `deploy-*.sh` - Deployment scripts
- `verify-*.sh` - Verification scripts
- `check-*.sh` - Health checks
- `test-*.sh` - Testing utilities
- `build-*.sh` - Build helpers

**To use a legacy script:**
```bash
# Copy and review first!
cp .github/archive/v37_legacy_scripts/deploy-stable.sh ./deploy-legacy.sh

# Read and understand it
less deploy-legacy.sh

# Modify as needed for current version
# Then use with caution
```

**⚠️ WARNING:** These scripts may contain:
- Hard-coded paths that no longer exist
- Deprecated dependencies
- Version-specific configuration
- Insecure practices (from older standards)

**Always review and update before using!**

---

## v37_logs/ (9 files, ~150 KB)

**Contents:**
- Build logs from production builds
- Deployment logs from releases
- Test reports and results
- CI/CD artifacts
- Error logs and diagnostics

**When to use:**
- Investigating build failures from specific versions
- Understanding deployment history
- Performance benchmarking over time
- Audit trail for deployments

**Log types:**
- `build_log_*.txt` - Complete build output
- `deploy_*.txt` - Deployment records
- `test_report_*.txt` - Test results
- `error_*.txt` - Error diagnostics
- `ci_*.txt` - CI/CD outputs

**To search logs:**
```bash
grep -r "ERROR" .github/archive/v37_logs/
grep -r "failed" .github/archive/v37_logs/ | head -20
```

**Note:** These are large text files. Use `less`, `grep`, or `tail` to view.

---

## v37_migrations/ (4 files, ~50 KB)

**Contents:**
- Migration guides between versions
- Database schema changes
- API breaking changes
- Upgrade instructions

**When to use:**
- Understanding how users upgraded between versions
- Planning major version updates
- Understanding data format changes
- API compatibility documentation

**File types:**
- `MIGRATION_HMR_v27_*.md` - Hot Module Replacement migrations
- `MIGRATION_INDEX.md` - Master migration guide
- `MIGRATION_REPORT_*.md` - Detailed migration reports

**To use migrations:**
```bash
# Review migration path
cat .github/archive/v37_migrations/MIGRATION_INDEX.md

# For specific version
cat .github/archive/v37_migrations/MIGRATION_HMR_v27_3_0.md
```

---

## Quick Recovery Guide

### I need a file from version 27.0.0

```bash
# List all v27 files
ls .github/archive/v37_legacy_docs/V27_*.md

# Copy specific file
cp .github/archive/v37_legacy_docs/V27_FINAL_AUDIT_REPORT.md ./

# Review and decide if integration needed
cat V27_FINAL_AUDIT_REPORT.md | less
```

### I need to understand an old deployment process

```bash
# Find deployment script from version 35
grep -l "v35" .github/archive/v37_legacy_scripts/*.sh

# Review script
cat .github/archive/v37_legacy_scripts/deploy-v35-stable.sh

# Understand what it did
# Adapt as needed for current version
```

### I'm debugging a build issue from v36

```bash
# Find build log from v36
ls .github/archive/v37_logs/ | grep v36

# View last 100 lines
tail -100 .github/archive/v37_logs/build_log_v36_final.txt

# Search for errors
grep "ERROR" .github/archive/v37_logs/build_log_v36_final.txt
```

### I need migration info between versions

```bash
# See all migrations available
ls .github/archive/v37_migrations/

# Read migration guide
cat .github/archive/v37_migrations/MIGRATION_INDEX.md
```

---

## Archive Statistics

| Directory | Files | Size | Archive Date |
|-----------|-------|------|--------------|
| v37_legacy_docs | 36 | ~300 KB | 2026-02-01 |
| v37_legacy_scripts | 29 | ~200 KB | 2026-02-01 |
| v37_logs | 9 | ~150 KB | 2026-02-01 |
| v37_migrations | 4 | ~50 KB | 2026-02-01 |
| **TOTAL** | **78** | **~800 KB** | **2026-02-01** |

---

## Important Notes

### This is NOT the active codebase
- Active code is in `src/`, `src-tauri/`, `tests/`
- Active documentation is in root (`README.md`, `ARCHITECTURE.md`, etc.)
- Use archive for **reference only**

### Archive is read-only
- Do not modify files in archive
- Copy to root if you need to use them
- Never commit changes to archived files

### Git history is preserved
If you need a specific version's full state:
```bash
# See all commits
git log --oneline | head -20

# Checkout specific version
git checkout v37.0.0

# Return to main
git checkout main
```

### Staying up-to-date
- Archive was created Feb 1, 2026 for v38.0.0 cleanup
- As v38+ develops, this archive becomes more useful as historical reference
- Future versions will create new archives

---

## Disaster Recovery

If you accidentally deleted something important:

### From archive
```bash
# Find what you deleted
find .github/archive -name "*something*"

# Copy it back
cp .github/archive/v37_legacy_docs/something.md ./
```

### From git
```bash
# See deleted file
git log -p -- deleted_file.md | head -50

# Recover deleted file
git checkout HEAD~1 deleted_file.md
```

---

## Contributing

If you find something in the archive that should be in current docs:

1. Open an issue: "Move X from archive to current docs"
2. Include reasoning
3. Reference the archive file
4. Maintainers will evaluate and integrate if appropriate

---

## Questions?

- 📖 [Main README](../../README.md)
- 🏗️ [ARCHITECTURE.md](../../ARCHITECTURE.md)
- 🤝 [CONTRIBUTING.md](../../CONTRIBUTING.md)
- 💬 [GitHub Issues](https://github.com/titane/titane-lite/issues)

---

**Archive Created:** February 1, 2026  
**Archive Version:** v37 Legacy (all files v27.0.0 through v37.x)  
**Status:** Read-only reference material  

*Historical preservation for TITANE v38.0.0 cleanup*
