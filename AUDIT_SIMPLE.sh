#!/bin/bash
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                    AUDIT COMPLET TITANE_LITE v1.0                         ║"
echo "║                    31 janvier 2026                                         ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"

PASSED=0
FAILED=0
WARNED=0

pass() { echo "✅ $1"; ((PASSED++)); }
fail() { echo "❌ $1"; ((FAILED++)); }
warn() { echo "⚠️  $1"; ((WARNED++)); }

# Git
echo ""; echo "📊 GIT & VERSIONING"
[ -d ".git" ] && pass "Git repo valide" || fail "Git manquant"
[ "$(git branch --show-current)" = "MAIN" ] && pass "Branch: MAIN" || warn "Branch: $(git branch --show-current)"

# Structure
echo ""; echo "📁 STRUCTURE FICHIERS"
for d in src src-tauri public scripts runtime; do [ -d "$d" ] && pass "$d existe" || fail "$d manquant"; done
for f in package.json src/main.tsx src-tauri/Cargo.toml; do [ -f "$f" ] && pass "$f existe" || fail "$f manquant"; done

# Dépendances
echo ""; echo "🔧 DÉPENDANCES"
[ -f "node_modules/.pnpm-debug.log" ] && warn "Log debug npm" || true
pnpm list @tauri-apps/api 2>/dev/null | grep -q "tauri" && pass "Tauri present" || fail "Tauri manquant"
pnpm list react 2>/dev/null | grep -q "react" && pass "React present" || fail "React manquant"

# Configuration Tauri
echo ""; echo "⚙️  CONFIGURATION TAURI"
[ -f "src-tauri/tauri.conf.json" ] && pass "tauri.conf.json existe" || fail "tauri.conf.json manquant"
grep -q "productName" src-tauri/tauri.conf.json 2>/dev/null && pass "productName configuré" || fail "productName manquant"

# Fichiers source clés
echo ""; echo "📝 FICHIERS SOURCE CLÉS"
for f in src/main.tsx src/App.tsx src-tauri/src/main.rs; do
    [ -f "$f" ] && [ -s "$f" ] && pass "$f valide" || fail "$f invalide"
done

# Documentation
echo ""; echo "📚 DOCUMENTATION"
DOC_COUNT=$(ls LITE_PROFILE*.md 2>/dev/null | wc -l)
[ "$DOC_COUNT" -ge 5 ] && pass "Documentation complete ($DOC_COUNT fichiers)" || warn "Documentation limitée ($DOC_COUNT fichiers)"

# Tests
echo ""; echo "🧪 TESTS"
[ -d "src/__tests__" ] && pass "Tests TS existent" || warn "Tests TS manquants"
[ -d "src-tauri/tests" ] && pass "Tests Rust existent" || warn "Tests Rust manquants"

# Profil Lite
echo ""; echo "🎯 SYSTÈME PROFIL LITE"
[ -f "src/utils/liteProfile.ts" ] && pass "liteProfile.ts existe" || warn "liteProfile.ts manquant"
[ -f "scripts/setup-lite-sync.sh" ] && pass "setup-lite-sync.sh existe" || warn "setup-lite-sync.sh manquant"

# Sécurité
echo ""; echo "🔐 SÉCURITÉ"
[ -f ".gitignore" ] && pass ".gitignore existe" || warn ".gitignore manquant"
grep -q ".env" .gitignore 2>/dev/null && pass ".env sécurisé" || warn ".env non sécurisé"

# Interface
echo ""; echo "🎨 INTERFACE & COMPOSANTS"
COMP_COUNT=$(find src/components -name "*.tsx" 2>/dev/null | wc -l)
[ "$COMP_COUNT" -gt 0 ] && pass "Composants: $COMP_COUNT fichiers" || warn "Composants manquants"

# Résumé
echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RÉSUMÉ"
echo "✅ Réussis: $PASSED"
echo "⚠️  Avertissements: $WARNED"
echo "❌ Échoués: $FAILED"
echo ""
[ "$FAILED" -eq 0 ] && echo "🎉 AUDIT RÉUSSI!" || echo "⚠️  AUDIT PARTIEL"
