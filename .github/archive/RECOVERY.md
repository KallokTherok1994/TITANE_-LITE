# 🔧 Archive Recovery Procedures

**Step-by-step guides for recovering files and configurations from archive.**

---

## Quick Recovery Commands

### Restore Specific File
```bash
# Find file in archive
find .github/archive -name "FILENAME"

# Copy to root
cp .github/archive/category/FILENAME ./

# Verify content
cat FILENAME
```

### Restore From Backup
```bash
# List available backups
ls -la .github/archive/v*/

# Restore specific backup
cp -r .github/archive/v37_legacy_docs/* ./docs/backup/

# Verify restoration
ls -la ./docs/backup/
```

### Roll Back to Previous Version
```bash
# Check archive for version
git tag -l | grep v37

# Checkout version
git checkout v37.1.0

# Build and deploy
pnpm run build
```

---

## Detailed Procedures

### 1. Find Archived File
1. Check [MANIFEST.md](MANIFEST.md) for file location
2. Browse `ls -la .github/archive/*/`
3. Use `find .github/archive -name "*search*"`

### 2. Restore Lost Configuration
1. Identify configuration file needed
2. Check archive for version with that file
3. Copy from archive: `cp .github/archive/v37_*/config.* ./`
4. Verify configuration: `cat config.*`
5. Test before using in production

### 3. Access Historical Logs
1. Navigate to logs: `ls .github/archive/v37_logs/`
2. View specific log: `cat .github/archive/v37_logs/build_*.log`
3. Search log: `grep ERROR .github/archive/v37_logs/build_*.log`

### 4. Execute Migration
1. Find migration file: `ls .github/archive/v37_migrations/`
2. Review migration: `cat .github/archive/v37_migrations/MIGRATION_*.md`
3. Follow steps exactly
4. Verify results after migration

### 5. Emergency Rollback
```bash
# Stop current deployment
npm run stop

# Rollback to previous version
git checkout v37.1.0
pnpm run build

# Deploy previous version
npm run deploy:prod

# Verify deployment
curl http://localhost:3000/health
```

---

## Time Estimates

| Operation | Time | Difficulty |
|-----------|------|------------|
| Find file | <1 min | Easy |
| Restore file | 1-2 min | Easy |
| Restore config | 2-5 min | Medium |
| Rollback deploy | 5-10 min | Medium |
| Full migration | 30+ min | Hard |

---

## Troubleshooting Recovery

| Problem | Solution |
|---------|----------|
| File not found | Check MANIFEST.md, search archive |
| Corruption | Check backup in different version |
| Compatibility | Check migration guide first |
| Permission denied | Use appropriate access level |

---

## Contact For Help

- **For file access:** See MANIFEST.md
- **For procedures:** Contact Kevin Thibault
- **For emergencies:** Follow rollback procedure above

---

**Recovery Guide Last Updated:** February 1, 2026

