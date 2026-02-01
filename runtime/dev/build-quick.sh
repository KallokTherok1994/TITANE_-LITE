#!/bin/bash
# TITANE∞ — Quick Build Script (Development)
# Résout le blocage en compilation avec des flags optimisés

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_DIR"

echo "🟢 TITANE∞ — Quick Build (DEV MODE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Build Vite frontend
echo "⚛️  Building React frontend (development)..."
NODE_ENV=development pnpm run build:vite
echo "✅ Frontend built"
echo ""

# Step 2: Build Tauri with optimized flags for dev
echo "🦀 Building Tauri app (development, fast)..."
export RUSTFLAGS="-C debug-info=0 -C opt-level=1"
export CARGO_CFG_OPTIMIZE=1

# Use faster tauri build
pnpm exec tauri build --config runtime/dev/tauri.conf.json
echo "✅ Tauri built"
echo ""

echo "🎉 QUICK BUILD COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
