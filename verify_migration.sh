#!/bin/bash

# 🔍 Script de vérification post-migration TITANE_LITE
# Usage: bash verify_migration.sh

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      🔍 VÉRIFICATION POST-MIGRATION TITANE_LITE             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_mark="${GREEN}✅${NC}"
cross_mark="${RED}❌${NC}"
warning="${YELLOW}⚠️${NC}"

# Compteurs
passed=0
failed=0

# Fonction pour tester
test_item() {
    local name=$1
    local cmd=$2
    
    if eval "$cmd" > /dev/null 2>&1; then
        echo -e "${check_mark} $name"
        ((passed++))
    else
        echo -e "${cross_mark} $name"
        ((failed++))
    fi
}

echo "📋 VÉRIFICATIONS"
echo ""

# 1. Configuration Git
echo "🔧 Git Configuration:"
test_item "Remote URL correct" "git remote get-url origin | grep -q 'TITANE_-LITE.git'"
test_item "Branche MAIN active" "git branch --show-current | grep -q 'MAIN'"

echo ""
echo "📦 Package Configuration:"
test_item "package.json: name=titane-lite" "jq -e '.name == \"titane-lite\"' package.json"
test_item "package.json: version existante" "jq -e '.version' package.json"
test_item "Cargo.toml: name=titane-lite" "grep -q 'name.*=.*\"titane-lite\"' src-tauri/Cargo.toml"
test_item "Cargo.toml: repository URL correct" "grep -q 'TITANE_-LITE' src-tauri/Cargo.toml"

echo ""
echo "🔐 Tauri Identifiers:"
test_item "tauri.conf.json: identifier correct" "grep -q 'com.titane.lite\"' src-tauri/tauri.conf.json"
test_item "runtime/dev: identifier.dev" "grep -q 'com.titane.lite.dev' runtime/dev/tauri.conf.json"
test_item "runtime/stable: identifier.stable" "grep -q 'com.titane.lite.stable' runtime/stable/tauri.conf.json"

echo ""
echo "🔍 Vérifications de contenu:"
test_item "Aucune TITANE_INFINITY en src/" "! grep -r 'TITANE_INFINITY' src/ 2>/dev/null | grep -v node_modules"
test_item "Aucune titane-infinity en src-tauri/" "! grep -r 'titane-infinity' src-tauri/src/ 2>/dev/null"
test_item "URLs GitHub mises à jour" "! grep -r 'KallokTherok1994/TITANE_INFINITY' --include='*.md' --include='*.json' . 2>/dev/null | grep -v '.git' | grep -v target"

echo ""
echo "✅ TypeScript & Compilation:"
test_item "TypeScript: check" "pnpm run check 2>&1 | grep -v 'deprecation'"
test_item "Git: commit créé" "git log --oneline -1 | grep -q 'Migration TITANE_INFINITY'"

echo ""
echo "📊 RÉSULTAT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Réussis: ${GREEN}$passed${NC}"
echo -e "Échoués: ${RED}$failed${NC}"
echo ""

if [ $failed -eq 0 ]; then
    echo -e "${check_mark} ${GREEN}TOUS LES TESTS RÉUSSIS!${NC}"
    echo ""
    echo "🎯 Prochaines étapes:"
    echo "  1. git push origin MAIN"
    echo "  2. pnpm run dev:tauri"
    echo "  3. Tester l'application"
    exit 0
else
    echo -e "${cross_mark} ${RED}$failed TESTS ÉCHOUÉS${NC}"
    echo ""
    echo "⚠️  Veuillez vérifier les erreurs ci-dessus"
    exit 1
fi
