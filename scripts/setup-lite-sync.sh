#!/bin/bash
# setup-lite-sync.sh
# Configure and validates lite profile sync environment

set -e

echo "🔧 TITANE Lite Profile Sync Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Defaults
PROFILE="${1:-lite}"
SYNC_BASE_DIR="${2:-/mnt/titane-sync}"
INSTANCE_ID="${HOSTNAME}"

echo "📋 Configuration"
echo "  Profile: $PROFILE"
echo "  Sync base: $SYNC_BASE_DIR"
echo "  Instance ID: $INSTANCE_ID"
echo ""

# Validate profile
case "$PROFILE" in
  ultra_lite|lite)
    echo -e "${GREEN}✓${NC} Profile: $PROFILE (sync enabled)"
    IS_CLIENT=1
    ;;
  balanced|full)
    echo -e "${GREEN}✓${NC} Profile: $PROFILE (import enabled)"
    IS_CLIENT=0
    ;;
  *)
    echo -e "${RED}✗${NC} Invalid profile: $PROFILE"
    exit 1
    ;;
esac

# Create directories
if [ $IS_CLIENT -eq 1 ]; then
  OUTBOX_DIR="$SYNC_BASE_DIR/outbox/$INSTANCE_ID"
  mkdir -p "$OUTBOX_DIR"
  chmod 755 "$OUTBOX_DIR"
  echo -e "${GREEN}✓${NC} Created outbox: $OUTBOX_DIR"
else
  IMPORT_DIR="$SYNC_BASE_DIR/import"
  mkdir -p "$IMPORT_DIR"
  chmod 755 "$IMPORT_DIR"
  echo -e "${GREEN}✓${NC} Created import: $IMPORT_DIR"
fi

# Validate shared directory
if [ ! -d "$SYNC_BASE_DIR" ]; then
  echo -e "${YELLOW}⚠${NC}  Shared directory not accessible: $SYNC_BASE_DIR"
  echo "  → Create manually or mount NFS/SMB"
else
  echo -e "${GREEN}✓${NC} Shared directory accessible"
  
  # Check permissions
  if [ ! -w "$SYNC_BASE_DIR" ]; then
    echo -e "${YELLOW}⚠${NC}  No write permission to $SYNC_BASE_DIR"
    echo "  → Run: sudo chmod 755 $SYNC_BASE_DIR"
  else
    echo -e "${GREEN}✓${NC} Write permission OK"
  fi
fi

# Check disk space
DISK_AVAILABLE=$(df "$SYNC_BASE_DIR" | awk 'NR==2 {print $4}')
if [ "$DISK_AVAILABLE" -lt 1048576 ]; then  # Less than 1GB
  echo -e "${YELLOW}⚠${NC}  Low disk space: ${DISK_AVAILABLE}KB available"
else
  echo -e "${GREEN}✓${NC} Disk space OK: ${DISK_AVAILABLE}KB available"
fi

# Create environment file
ENV_FILE=".env.lite-$PROFILE"
cat > "$ENV_FILE" << EOF
# TITANE Lite Profile Configuration
# Generated: $(date -Iseconds)
# Profile: $PROFILE

TITANE_LITE_PROFILE=$PROFILE

EOF

if [ $IS_CLIENT -eq 1 ]; then
  cat >> "$ENV_FILE" << EOF
# Export Configuration (Lite → Shared)
TITANE_LITE_SYNC_ENABLED=true
TITANE_LITE_SYNC_INTERVAL_SEC=900
TITANE_LITE_SYNC_OUTBOX_DIR=$OUTBOX_DIR
TITANE_LITE_SYNC_TARGET=FULL

# Disable import on client
TITANE_LITE_SYNC_IMPORT_ENABLED=false
EOF
else
  cat >> "$ENV_FILE" << EOF
# Import Configuration (Shared → Full)
TITANE_LITE_SYNC_IMPORT_ENABLED=true
TITANE_LITE_SYNC_IMPORT_DIR=$SYNC_BASE_DIR/import
TITANE_LITE_SYNC_IMPORT_MODE=merge

# Disable export on server
TITANE_LITE_SYNC_ENABLED=false
EOF
fi

echo ""
echo -e "${GREEN}✓${NC} Created environment file: $ENV_FILE"
echo ""

# Show environment file content
echo "📄 Environment Configuration:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$ENV_FILE"
echo ""

# Usage instructions
echo "🚀 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $IS_CLIENT -eq 1 ]; then
  echo "1. Source the environment file:"
  echo "   source $ENV_FILE"
  echo ""
  echo "2. Start the Lite instance:"
  echo "   pnpm run dev:tauri"
  echo ""
  echo "3. Monitor exports:"
  echo "   watch -n 5 'ls -lh $OUTBOX_DIR/'"
else
  echo "1. Source the environment file:"
  echo "   source $ENV_FILE"
  echo ""
  echo "2. Start the Full instance:"
  echo "   pnpm run dev:tauri"
  echo ""
  echo "3. Monitor imports:"
  echo "   watch -n 5 'ls -lh $SYNC_BASE_DIR/import/'"
fi

echo ""
echo -e "${GREEN}✅ Setup Complete!${NC}"
