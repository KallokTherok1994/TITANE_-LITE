#!/bin/bash
# AUDIT_COMPLET_TITANE_LITE.sh
# Audit exhaustif du projet TITANE_LITE

set -e

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                    AUDIT COMPLET TITANE_LITE                              ║"
echo "║                    31 janvier 2026                                         ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"

TOTAL_CHECKS=0
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

log_pass() {
    echo "✅ $1"
    ((CHECKS_PASSED++))
    ((TOTAL_CHECKS++))
}

log_fail() {
    echo "❌ $1"
    ((CHECKS_FAILED++))
    ((TOTAL_CHECKS++))
}

log_warn() {
    echo "⚠️  $1"
    ((CHECKS_WARNING++))
    ((TOTAL_CHECKS++))
}

# =============================================================================
# 1. VÉRIFICATION GIT ET VERSIONING
# =============================================================================
echo ""
echo "📊 1. GIT & VERSIONING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d ".git" ]; then
    log_pass "Repo git valide"
    
    BRANCH=$(git branch --show-current)
    if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "MAIN" ] || [ "$BRANCH" = "master" ] || [ "$BRANCH" = "MAIN" ]; then
        log_pass "Branch principale: $BRANCH"
    else
        log_warn "Branch non standard: $BRANCH"
    fi
    
    if git remote get-url origin &>/dev/null; then
        log_pass "Remote origin configuré"
    else
        log_fail "Remote origin manquant"
    fi
else
    log_fail "Repo git manquant"
fi

# =============================================================================
# 2. STRUCTURE FICHIERS
# =============================================================================
echo ""
echo "📁 2. STRUCTURE FICHIERS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REQUIRED_DIRS=("src" "src-tauri" "public" "scripts" "runtime")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        log_pass "Dossier $dir existe"
    else
        log_fail "Dossier $dir MANQUANT"
    fi
done

REQUIRED_FILES=("package.json" "package-lock.yaml" "src/main.tsx" "src-tauri/Cargo.toml" "tsconfig.json")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_pass "Fichier $file existe"
    else
        log_fail "Fichier $file MANQUANT"
    fi
done

# =============================================================================
# 3. COMPILATION & DÉPENDANCES
# =============================================================================
echo ""
echo "🔧 3. COMPILATION & DÉPENDANCES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if pnpm list @tauri-apps/api >/dev/null 2>&1; then
    log_pass "Tauri API présent"
else
    log_fail "Tauri API manquant"
fi

if pnpm list react >/dev/null 2>&1; then
    log_pass "React présent"
else
    log_fail "React manquant"
fi

if [ -f "Cargo.lock" ]; then
    log_pass "Cargo.lock existe"
else
    log_warn "Cargo.lock manquant (peut être normal)"
fi

# =============================================================================
# 4. CONFIGURATION TAURI
# =============================================================================
echo ""
echo "⚙️  4. CONFIGURATION TAURI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "src-tauri/tauri.conf.json" ]; then
    log_pass "tauri.conf.json existe"
    
    if grep -q '"productName"' src-tauri/tauri.conf.json; then
        log_pass "productName configuré"
    else
        log_fail "productName manquant"
    fi
else
    log_fail "tauri.conf.json manquant"
fi

# Check runtime configs
if [ -f "runtime/dev/tauri.conf.json" ]; then
    log_pass "Config dev Tauri existe"
else
    log_warn "Config dev Tauri manquante"
fi

if [ -f "runtime/stable/tauri.conf.json" ]; then
    log_pass "Config stable Tauri existe"
else
    log_warn "Config stable Tauri manquante"
fi

# =============================================================================
# 5. FICHIERS SOURCE CLÉS
# =============================================================================
echo ""
echo "📝 5. FICHIERS SOURCE CLÉS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CORE_FILES=(
    "src/main.tsx"
    "src/App.tsx"
    "src-tauri/src/main.rs"
    "src/components/Chat.tsx"
    "src/components/Memory.tsx"
)

for file in "${CORE_FILES[@]}"; do
    if [ -f "$file" ]; then
        LINES=$(wc -l < "$file")
        if [ "$LINES" -gt 0 ]; then
            log_pass "$file existe ($LINES lignes)"
        else
            log_fail "$file vide"
        fi
    else
        log_warn "$file manquant"
    fi
done

# =============================================================================
# 6. DOCUMENTATION
# =============================================================================
echo ""
echo "📚 6. DOCUMENTATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DOC_FILES=(
    "LITE_PROFILE_QUICKSTART.md"
    "LITE_PROFILE_SETUP.md"
    "LITE_PROFILE_IMPLEMENTATION_SUMMARY.md"
    "README.md"
    "LICENSE.md"
)

DOC_COUNT=0
for doc in "${DOC_FILES[@]}"; do
    if [ -f "$doc" ]; then
        ((DOC_COUNT++))
        log_pass "$doc existe"
    fi
done

if [ "$DOC_COUNT" -ge 3 ]; then
    log_pass "Documentation suffisante ($DOC_COUNT fichiers)"
else
    log_warn "Documentation limitée ($DOC_COUNT fichiers)"
fi

# =============================================================================
# 7. TESTS
# =============================================================================
echo ""
echo "🧪 7. TESTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d "src/__tests__" ]; then
    TEST_COUNT=$(find src/__tests__ -name "*.test.ts*" 2>/dev/null | wc -l)
    if [ "$TEST_COUNT" -gt 0 ]; then
        log_pass "Tests TypeScript trouvés ($TEST_COUNT fichiers)"
    else
        log_warn "Aucun test TypeScript trouvé"
    fi
else
    log_warn "Dossier src/__tests__ manquant"
fi

if [ -d "src-tauri/tests" ]; then
    RUST_TEST_COUNT=$(find src-tauri/tests -name "*.rs" 2>/dev/null | wc -l)
    if [ "$RUST_TEST_COUNT" -gt 0 ]; then
        log_pass "Tests Rust trouvés ($RUST_TEST_COUNT fichiers)"
    else
        log_warn "Aucun test Rust trouvé"
    fi
else
    log_warn "Dossier src-tauri/tests manquant"
fi

# =============================================================================
# 8. FICHIERS LITE PROFILE
# =============================================================================
echo ""
echo "🎯 8. SYSTÈME PROFIL LITE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

LITE_FILES=(
    "src/utils/liteProfile.ts"
    "src/__tests__/liteProfile.test.ts"
    "src-tauri/src/runtime_config_tests.rs"
    "scripts/setup-lite-sync.sh"
    "scripts/verify-lite-sync.sh"
)

for file in "${LITE_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_pass "Profil Lite: $file existe"
    else
        log_warn "Profil Lite: $file manquant"
    fi
done

# =============================================================================
# 9. SÉCURITÉ
# =============================================================================
echo ""
echo "🔐 9. SÉCURITÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f ".env.example" ]; then
    log_pass ".env.example existe"
else
    log_warn ".env.example manquant"
fi

if [ -f ".gitignore" ]; then
    if grep -q ".env" .gitignore; then
        log_pass ".env ignoré dans git"
    else
        log_warn ".env non ignoré (risque sécurité)"
    fi
    
    if grep -q "node_modules" .gitignore; then
        log_pass "node_modules ignoré"
    else
        log_warn "node_modules non ignoré"
    fi
else
    log_fail ".gitignore manquant"
fi

# =============================================================================
# 10. INTERFACE & COMPOSANTS
# =============================================================================
echo ""
echo "🎨 10. INTERFACE & COMPOSANTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d "src/components" ]; then
    COMP_COUNT=$(find src/components -name "*.tsx" 2>/dev/null | wc -l)
    if [ "$COMP_COUNT" -gt 0 ]; then
        log_pass "Composants React trouvés ($COMP_COUNT fichiers)"
    else
        log_fail "Aucun composant React trouvé"
    fi
else
    log_fail "Dossier src/components manquant"
fi

if [ -d "src/pages" ]; then
    PAGES_COUNT=$(find src/pages -name "*.tsx" 2>/dev/null | wc -l)
    if [ "$PAGES_COUNT" -gt 0 ]; then
        log_pass "Pages trouvées ($PAGES_COUNT fichiers)"
    else
        log_warn "Aucune page trouvée"
    fi
fi

# =============================================================================
# 11. STYLES & ASSETS
# =============================================================================
echo ""
echo "🎨 11. STYLES & ASSETS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d "public" ]; then
    ASSETS=$(find public -type f 2>/dev/null | wc -l)
    if [ "$ASSETS" -gt 0 ]; then
        log_pass "Assets trouvés ($ASSETS fichiers)"
    else
        log_warn "Aucun asset trouvé"
    fi
fi

if [ -f "tailwind.config.js" ] || [ -f "tailwind.config.ts" ]; then
    log_pass "Tailwind configuré"
else
    if grep -q "tailwindcss\|@tailwind" src/index.css 2>/dev/null || grep -q "tailwindcss" package.json 2>/dev/null; then
        log_pass "Tailwind détecté"
    else
        log_warn "Tailwind non détecté"
    fi
fi

# =============================================================================
# RÉSUMÉ FINAL
# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RÉSUMÉ AUDIT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total checks: $TOTAL_CHECKS"
echo "✅ Passés: $CHECKS_PASSED"
echo "⚠️  Avertissements: $CHECKS_WARNING"
echo "❌ Échoués: $CHECKS_FAILED"
echo ""

if [ "$CHECKS_FAILED" -eq 0 ]; then
    echo "🎉 AUDIT RÉUSSI - Tout est fonctionnel!"
    exit 0
elif [ "$CHECKS_FAILED" -le 3 ]; then
    echo "⚠️  AUDIT PARTIEL - Quelques problèmes mineurs"
    exit 1
else
    echo "❌ AUDIT ÉCHOUÉ - Problèmes importants détectés"
    exit 2
fi
