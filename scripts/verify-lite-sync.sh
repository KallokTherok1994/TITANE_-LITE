#!/bin/bash
# verify-lite-sync.sh
# Validates lite profile sync system and health

set -e

echo "🔍 TITANE Lite Profile Sync Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SYNC_BASE_DIR="${1:-/mnt/titane-sync}"
VERBOSE="${2:-0}"

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

check_pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((CHECKS_PASSED++))
}

check_fail() {
  echo -e "${RED}✗${NC} $1"
  ((CHECKS_FAILED++))
}

check_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
  ((CHECKS_WARNING++))
}

# 1. Directory Structure
echo ""
echo "📁 Directory Structure"
echo "─────────────────────────────────────────────────"

if [ ! -d "$SYNC_BASE_DIR" ]; then
  check_fail "Sync directory not found: $SYNC_BASE_DIR"
else
  check_pass "Sync directory exists"
  
  # Check subdirectories
  if [ ! -d "$SYNC_BASE_DIR/outbox" ]; then
    check_warn "Outbox directory not found (for Lite instances)"
  else
    check_pass "Outbox directory exists"
  fi
  
  if [ ! -d "$SYNC_BASE_DIR/import" ]; then
    check_warn "Import directory not found (for Full instances)"
  else
    check_pass "Import directory exists"
  fi
fi

# 2. Permissions
echo ""
echo "🔐 Permissions"
echo "─────────────────────────────────────────────────"

if [ -d "$SYNC_BASE_DIR" ]; then
  if [ -w "$SYNC_BASE_DIR" ]; then
    check_pass "Write permission to sync directory"
  else
    check_fail "No write permission to sync directory"
  fi
  
  if [ -x "$SYNC_BASE_DIR" ]; then
    check_pass "Execute permission to sync directory"
  else
    check_fail "No execute permission to sync directory"
  fi
  
  # Check subdirectory permissions
  if [ -d "$SYNC_BASE_DIR/outbox" ] && [ -w "$SYNC_BASE_DIR/outbox" ]; then
    check_pass "Write permission to outbox"
  fi
  
  if [ -d "$SYNC_BASE_DIR/import" ] && [ -w "$SYNC_BASE_DIR/import" ]; then
    check_pass "Write permission to import"
  fi
fi

# 3. Disk Space
echo ""
echo "💾 Disk Space"
echo "─────────────────────────────────────────────────"

if [ -d "$SYNC_BASE_DIR" ]; then
  TOTAL=$(df "$SYNC_BASE_DIR" | awk 'NR==2 {print $2}')
  USED=$(df "$SYNC_BASE_DIR" | awk 'NR==2 {print $3}')
  AVAILABLE=$(df "$SYNC_BASE_DIR" | awk 'NR==2 {print $4}')
  PERCENT=$(df "$SYNC_BASE_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
  
  TOTAL_GB=$((TOTAL / 1048576))
  AVAILABLE_GB=$((AVAILABLE / 1048576))
  
  if [ "$PERCENT" -lt 70 ]; then
    check_pass "Disk usage OK: ${PERCENT}% used (${AVAILABLE_GB}GB available)"
  elif [ "$PERCENT" -lt 85 ]; then
    check_warn "Disk usage moderate: ${PERCENT}% used (${AVAILABLE_GB}GB available)"
  else
    check_fail "Disk usage critical: ${PERCENT}% used (${AVAILABLE_GB}GB available)"
  fi
fi

# 4. Backup Files
echo ""
echo "📦 Backup Files"
echo "─────────────────────────────────────────────────"

if [ -d "$SYNC_BASE_DIR/outbox" ]; then
  OUTBOX_COUNT=$(find "$SYNC_BASE_DIR/outbox" -name "*.tar.gz" 2>/dev/null | wc -l)
  if [ "$OUTBOX_COUNT" -eq 0 ]; then
    check_warn "No backups in outbox (expected if Lite not running)"
  else
    check_pass "Found $OUTBOX_COUNT backup(s) in outbox"
    if [ "$VERBOSE" -eq 1 ]; then
      find "$SYNC_BASE_DIR/outbox" -name "*.tar.gz" -exec ls -lh {} \; | awk '{print "  " $9 " (" $5 ")"}'
    fi
  fi
  
  # Check for old backups
  OLD_BACKUPS=$(find "$SYNC_BASE_DIR/outbox" -name "*.tar.gz" -mtime +7 2>/dev/null | wc -l)
  if [ "$OLD_BACKUPS" -gt 0 ]; then
    check_warn "Found $OLD_BACKUPS backup(s) older than 7 days (consider cleanup)"
  fi
fi

if [ -d "$SYNC_BASE_DIR/import" ]; then
  IMPORT_COUNT=$(find "$SYNC_BASE_DIR/import" -name "*.tar.gz" 2>/dev/null | wc -l)
  if [ "$IMPORT_COUNT" -eq 0 ]; then
    check_warn "No backups in import (expected if Full not running)"
  else
    check_pass "Found $IMPORT_COUNT backup(s) in import"
    if [ "$VERBOSE" -eq 1 ]; then
      find "$SYNC_BASE_DIR/import" -name "*.tar.gz" -exec ls -lh {} \; | awk '{print "  " $9 " (" $5 ")"}'
    fi
  fi
fi

# 5. Backup Integrity
echo ""
echo "🔍 Backup Integrity"
echo "─────────────────────────────────────────────────"

check_backups() {
  local dir=$1
  local dir_name=$2
  
  if [ -d "$dir" ]; then
    local backups=$(find "$dir" -name "*.tar.gz" 2>/dev/null | head -3)
    local count=0
    
    while IFS= read -r backup; do
      if [ -z "$backup" ]; then
        continue
      fi
      
      # Check if tar file is valid
      if tar -tzf "$backup" > /dev/null 2>&1; then
        check_pass "$dir_name: Valid backup: $(basename $backup)"
      else
        check_fail "$dir_name: Corrupted backup: $(basename $backup)"
      fi
      
      ((count++))
      if [ $count -ge 3 ]; then
        break
      fi
    done <<< "$backups"
  fi
}

check_backups "$SYNC_BASE_DIR/outbox" "Outbox"
check_backups "$SYNC_BASE_DIR/import" "Import"

# 6. Configuration
echo ""
echo "⚙️  Configuration Check"
echo "─────────────────────────────────────────────────"

if [ -n "$TITANE_LITE_PROFILE" ]; then
  check_pass "TITANE_LITE_PROFILE set: $TITANE_LITE_PROFILE"
else
  check_warn "TITANE_LITE_PROFILE not set (will default to balanced)"
fi

if [ -n "$TITANE_LITE_SYNC_ENABLED" ]; then
  check_pass "TITANE_LITE_SYNC_ENABLED: $TITANE_LITE_SYNC_ENABLED"
fi

if [ -n "$TITANE_LITE_SYNC_IMPORT_ENABLED" ]; then
  check_pass "TITANE_LITE_SYNC_IMPORT_ENABLED: $TITANE_LITE_SYNC_IMPORT_ENABLED"
fi

# 7. Network Check (if mounted)
echo ""
echo "🌐 Network Check"
echo "─────────────────────────────────────────────────"

if mount | grep -q "$SYNC_BASE_DIR"; then
  MOUNT_INFO=$(mount | grep "$SYNC_BASE_DIR")
  check_pass "Directory is mounted: $MOUNT_INFO"
  
  # Test write
  TEST_FILE="$SYNC_BASE_DIR/.sync-test-$$"
  if touch "$TEST_FILE" 2>/dev/null; then
    rm -f "$TEST_FILE"
    check_pass "Write test successful"
  else
    check_fail "Write test failed"
  fi
else
  check_warn "Directory is not a mounted filesystem (local directory)"
fi

# 8. Cleanup Recommendations
echo ""
echo "🧹 Cleanup Recommendations"
echo "─────────────────────────────────────────────────"

# Old files
OLD_FILES=$(find "$SYNC_BASE_DIR" -name "*.tar.gz" -mtime +30 2>/dev/null | wc -l)
if [ "$OLD_FILES" -gt 0 ]; then
  echo "  → Remove $OLD_FILES backups older than 30 days:"
  echo "    find $SYNC_BASE_DIR -name '*.tar.gz' -mtime +30 -delete"
fi

# Orphaned directories
if [ -d "$SYNC_BASE_DIR/outbox" ]; then
  EMPTY_DIRS=$(find "$SYNC_BASE_DIR/outbox" -type d -empty 2>/dev/null | wc -l)
  if [ "$EMPTY_DIRS" -gt 0 ]; then
    echo "  → Remove $EMPTY_DIRS empty instance directories:"
    echo "    find $SYNC_BASE_DIR/outbox -type d -empty -delete"
  fi
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"
echo -e "${RED}Failed: $CHECKS_FAILED${NC}"

if [ $CHECKS_FAILED -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✅ All checks passed!${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}❌ Some checks failed. Please review above.${NC}"
  exit 1
fi
