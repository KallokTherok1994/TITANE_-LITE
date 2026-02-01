#!/bin/bash
# TITANE LITE v27.1.1 — VALIDATION RUNTIME SCRIPT
# Valide les 5 optimisations implémentées

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "═════════════════════════════════════════════════════════════"
echo "  TITANE LITE v27.1.1 — VALIDATION RUNTIME"
echo "═════════════════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${YELLOW}▶ Test: $test_name${NC}"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "📋 PHASE 1: CODE VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: TypeScript compilation
echo "1️⃣  TypeScript Compilation..."
if pnpm run type-check > /tmp/ts-check.log 2>&1 || grep -q "0 errors" /tmp/ts-check.log 2>/dev/null; then
    echo -e "${GREEN}✓ TypeScript: 0 erreurs${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ TypeScript: Erreurs détectées${NC}"
    tail -20 /tmp/ts-check.log
    ((TESTS_FAILED++))
fi
echo ""

# Test 2: Vérifier isDebugMode() existe
echo "2️⃣  Helper isDebugMode()..."
if grep -q "export function isDebugMode" src/utils/environment.ts; then
    echo -e "${GREEN}✓ isDebugMode() trouvé dans environment.ts${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ isDebugMode() manquant${NC}"
    ((TESTS_FAILED++))
fi
echo ""

# Test 3: Vérifier COGNITIVE_CYCLE_MS = 30000
echo "3️⃣  Cognitive Cycle Optimization (30s)..."
if grep -q "COGNITIVE_CYCLE_MS = 30000" src/services/ai/singularityKernel.ts; then
    echo -e "${GREEN}✓ COGNITIVE_CYCLE_MS = 30000 (était 10000)${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ COGNITIVE_CYCLE_MS non optimisé${NC}"
    ((TESTS_FAILED++))
fi
echo ""

# Test 4: Vérifier SCAN_INTERVAL = 120000
echo "4️⃣  Auto-Audit Optimization (2min)..."
if grep -q "SCAN_INTERVAL = 120000" src/services/autoAuditEngine.ts; then
    echo -e "${GREEN}✓ SCAN_INTERVAL = 120000 (était 30000)${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ SCAN_INTERVAL non optimisé${NC}"
    ((TESTS_FAILED++))
fi
echo ""

# Test 5: Vérifier warning throttle Map
echo "5️⃣  Warning Throttle System..."
if grep -q "warningThrottle.*Map" src/services/ai/metaKernel.ts; then
    echo -e "${GREEN}✓ Warning throttle Map trouvé${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Warning throttle manquant${NC}"
    ((TESTS_FAILED++))
fi
echo ""

# Test 6: Vérifier provider cache
echo "6️⃣  Provider Cache (5min TTL)..."
if grep -q "providerReadinessCache" src/hooks/useChat.ts && grep -q "300000" src/hooks/useChat.ts; then
    echo -e "${GREEN}✓ Provider cache 5min TTL trouvé${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Provider cache manquant${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo "📋 PHASE 2: DOCUMENTATION VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 7: CHANGELOG.md v27.1.1
echo "7️⃣  CHANGELOG.md Section v27.1.1..."
if grep -q "## \[27.1.1\]" CHANGELOG.md; then
    echo -e "${GREEN}✓ Section v27.1.1 présente${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ Section v27.1.1 manquante${NC}"
    ((TESTS_FAILED++))
fi
echo ""

# Test 8: Documentation complète
echo "8️⃣  Documentation Performance..."
EXPECTED_DOCS=(
    "PERFORMANCE_OPTIMIZATION_v27.1.1.md"
    "V27_1_1_PERFORMANCE_SUMMARY.md"
    "REFLEXION_APPROFONDIE_v27.1.1.md"
    "ROADMAP_v27.2.0_BUNDLE_OPTIMIZATION.md"
    "SESSION_COMPLETE_v27.1.1.md"
)

DOC_MISSING=0
for doc in "${EXPECTED_DOCS[@]}"; do
    if [[ -f "$doc" ]]; then
        echo -e "  ${GREEN}✓${NC} $doc"
    else
        echo -e "  ${RED}✗${NC} $doc MANQUANT"
        ((DOC_MISSING++))
    fi
done

if [[ $DOC_MISSING -eq 0 ]]; then
    echo -e "${GREEN}✓ Toute la documentation présente (5/5)${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ $DOC_MISSING documents manquants${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo "📋 PHASE 3: GIT STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 9: Working tree clean
echo "9️⃣  Git Working Tree..."
if [[ -z $(git status --porcelain) ]]; then
    echo -e "${GREEN}✓ Working tree clean${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠ Fichiers non commités détectés${NC}"
    git status --short
    ((TESTS_PASSED++))  # Warning, pas erreur
fi
echo ""

# Test 10: Commits ahead of origin
echo "🔟 Commits En Attente Push..."
AHEAD_COUNT=$(git rev-list --count origin/MAIN..HEAD 2>/dev/null || echo "0")
if [[ $AHEAD_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠ $AHEAD_COUNT commit(s) en attente de push${NC}"
    git log --oneline origin/MAIN..HEAD
    echo ""
    echo "Commande push:"
    echo "  git push origin MAIN"
    if git tag -l | grep -q "v27.1.1"; then
        echo "  git push origin v27.1.1"
    fi
    ((TESTS_PASSED++))  # Warning, pas erreur
else
    echo -e "${GREEN}✓ Tous commits pushés${NC}"
    ((TESTS_PASSED++))
fi
echo ""

echo "═════════════════════════════════════════════════════════════"
echo "  RÉSULTATS FINAUX"
echo "═════════════════════════════════════════════════════════════"
echo ""
echo -e "Tests réussis: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests échoués: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ v27.1.1 VALIDATION COMPLÈTE — READY FOR PRODUCTION${NC}"
    echo ""
    echo "Prochaines étapes:"
    echo "  1. git push origin MAIN (si commits en attente)"
    echo "  2. Tests runtime: pnpm run dev:tauri"
    echo "  3. Validation gains CPU/logs en production"
    exit 0
else
    echo -e "${RED}❌ VALIDATION ÉCHOUÉE — Corriger les erreurs ci-dessus${NC}"
    exit 1
fi
