#!/bin/bash
# TITANE∞ Build Optimization Helper
# Aide à accélérer les builds en développement

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   TITANE∞ Build Optimization Helper v1.0                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Function to show build tips
show_tips() {
    echo "🚀 BUILD OPTIMIZATION TIPS:"
    echo ""
    echo "1. FOR DEVELOPMENT (Faster builds):"
    echo "   $ export RUSTFLAGS='-C opt-level=1 -C debug-info=0'"
    echo "   $ pnpm run build:app"
    echo ""
    echo "2. FOR QUICK FRONTEND ONLY:"
    echo "   $ pnpm run build:vite"
    echo ""
    echo "3. FOR PRODUCTION (Slower but optimized):"
    echo "   $ ./runtime/stable/build.sh"
    echo ""
    echo "4. MONITOR BUILD PROGRESS:"
    echo "   $ cargo build --release 2>&1 | grep -E 'Compiling|error|warning'"
    echo ""
    echo "5. CLEAN AND REBUILD:"
    echo "   $ cargo clean && pnpm run build:app"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function to show current cargo processes
show_cargo_status() {
    echo ""
    echo "📊 CURRENT BUILD PROCESSES:"
    echo ""
    
    if ps aux | grep -E "cargo|rustc" | grep -v grep > /dev/null; then
        ps aux | grep -E "cargo|rustc" | grep -v grep | awk '{
            print "  PID: "$2" - "$11" - CPU: "$3"% - MEM: "$4"%"
        }'
    else
        echo "  ✅ No active builds"
    fi
    echo ""
}

# Function to check cargo cache size
check_cache() {
    echo ""
    echo "💾 BUILD CACHE INFO:"
    echo ""
    
    if [[ -d "src-tauri/target" ]]; then
        CACHE_SIZE=$(du -sh src-tauri/target | cut -f1)
        echo "  Cargo target size: $CACHE_SIZE"
        
        if [[ -d "src-tauri/target/release" ]]; then
            REL_SIZE=$(du -sh src-tauri/target/release | cut -f1)
            echo "  Release build: $REL_SIZE"
        fi
    else
        echo "  No cache yet"
    fi
    echo ""
}

# Main menu
case "${1:-help}" in
    tips)
        show_tips
        ;;
    status)
        show_cargo_status
        ;;
    cache)
        check_cache
        ;;
    clean)
        echo "🧹 Cleaning cargo cache..."
        cargo clean
        rm -rf dist/ node_modules/.cache
        echo "✅ Cache cleaned"
        ;;
    *)
        echo "Usage: $0 {tips|status|cache|clean}"
        echo ""
        show_tips
        show_cargo_status
        check_cache
        ;;
esac
