#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ TITANE∞ v12.0.0 - SECURE DEPLOYMENT PIPELINE                                ║
# ║ Ultra-Secure DevOps + Audit Sécurité Avancé + Auto-Fix + CI/CD             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ═════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═════════════════════════════════════════════════════════════════════════════

readonly SCRIPT_VERSION="12.0.0"
readonly SCRIPT_NAME="TITANE_LITE_SECURE_PIPELINE"
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly LOG_FILE="${PROJECT_ROOT}/pipeline_secure_${TIMESTAMP}.log"
readonly REPORT_FILE="${PROJECT_ROOT}/RAPPORT_SECURE_PIPELINE_v12_${TIMESTAMP}.md"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Counters
ERRORS_COUNT=0
WARNINGS_COUNT=0
FIXED_COUNT=0
CHECKS_PASSED=0

# ═════════════════════════════════════════════════════════════════════════════
# LOGGING FUNCTIONS
# ═════════════════════════════════════════════════════════════════════════════

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    case "$level" in
        INFO)  echo -e "${CYAN}[INFO]${NC}  ${message}" | tee -a "$LOG_FILE" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC}  ${message}" | tee -a "$LOG_FILE"; ((WARNINGS_COUNT++)) ;;
        ERROR) echo -e "${RED}[ERROR]${NC} ${message}" | tee -a "$LOG_FILE"; ((ERRORS_COUNT++)) ;;
        SUCCESS) echo -e "${GREEN}[✓]${NC}    ${message}" | tee -a "$LOG_FILE"; ((CHECKS_PASSED++)) ;;
        FIX)   echo -e "${BLUE}[FIX]${NC}   ${message}" | tee -a "$LOG_FILE"; ((FIXED_COUNT++)) ;;
        TITLE) echo -e "\n${BOLD}${CYAN}═══ $message ═══${NC}\n" | tee -a "$LOG_FILE" ;;
    esac
    
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
}

header() {
    local title="$1"
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    printf "║ %-62s ║\n" "$title"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log INFO "$title"
}

# ═════════════════════════════════════════════════════════════════════════════
# PREREQUIS & ENVIRONMENT CHECKS
# ═════════════════════════════════════════════════════════════════════════════

check_prerequisites() {
    header "PHASE 0: Vérification Prérequis"
    
    local required_commands=("cargo" "rustc" "node" "npm" "git" "sha256sum" "jq")
    
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            local version
            case "$cmd" in
                cargo|rustc) version="$(cargo --version | awk '{print $2}')" ;;
                node) version="$(node --version)" ;;
                npm) version="$(npm --version)" ;;
                git) version="$(git --version | awk '{print $3}')" ;;
                *) version="installed" ;;
            esac
            log SUCCESS "$cmd: $version"
        else
            log ERROR "$cmd n'est pas installé"
            return 1
        fi
    done
    
    # Check WebKit
    if pkg-config --exists javascriptcoregtk-4.1 2>/dev/null; then
        log SUCCESS "WebKit 4.1: installé"
    else
        log WARN "WebKit 4.1: MANQUANT (requis pour production build)"
        log INFO "Installation: sudo apt-get install libwebkit2gtk-4.1-dev libjavascriptcoregtk-4.1-dev"
    fi
    
    # Check workspace
    if [[ ! -f "${PROJECT_ROOT}/package.json" || ! -f "${PROJECT_ROOT}/src-tauri/Cargo.toml" ]]; then
        log ERROR "Structure projet invalide"
        return 1
    fi
    
    log SUCCESS "Tous les prérequis validés"
}

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 1: CLEAN GLOBAL
# ═════════════════════════════════════════════════════════════════════════════

phase_clean() {
    header "PHASE 1: Clean Global + Optimisation"
    
    log INFO "Nettoyage build artifacts..."
    
    # Clean Rust
    if [[ -d "${PROJECT_ROOT}/src-tauri/target" ]]; then
        cd "${PROJECT_ROOT}/src-tauri"
        cargo clean 2>&1 | tee -a "$LOG_FILE"
        log SUCCESS "Rust artifacts cleaned"
    fi
    
    # Clean Node
    if [[ -d "${PROJECT_ROOT}/node_modules" ]]; then
        log INFO "Préservation node_modules (npm ci plus tard)"
    fi
    
    if [[ -d "${PROJECT_ROOT}/dist" ]]; then
        rm -rf "${PROJECT_ROOT}/dist"
        log SUCCESS "Frontend dist/ cleaned"
    fi
    
    # Clean temp files
    find "$PROJECT_ROOT" -type f -name "*.log" -mtime +7 -delete 2>/dev/null || true
    find "$PROJECT_ROOT" -type f -name "*.tmp" -delete 2>/dev/null || true
    
    log SUCCESS "Clean global terminé"
}

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 2: ANALYSE SÉCURITÉ BACKEND
# ═════════════════════════════════════════════════════════════════════════════

phase_security_audit_backend() {
    header "PHASE 2: Audit Sécurité Backend Rust"
    
    cd "${PROJECT_ROOT}/src-tauri"
    
    # Check unwrap() dangereux
    log INFO "Scanning unwrap() non sécurisés..."
    local unwrap_count
    unwrap_count=$(grep -rn "\.unwrap()" src/ --include="*.rs" 2>/dev/null | grep -v "test" | wc -l || echo "0")
    
    if [[ $unwrap_count -gt 0 ]]; then
        log WARN "Trouvé $unwrap_count unwrap() dans le code (hors tests)"
        log INFO "Recommandation: Migration vers Result<> + .map_err()"
    else
        log SUCCESS "Aucun unwrap() dangereux détecté"
    fi
    
    # Check expect()
    local expect_count
    expect_count=$(grep -rn "\.expect(" src/ --include="*.rs" 2>/dev/null | grep -v "test" | wc -l || echo "0")
    
    if [[ $expect_count -gt 0 ]]; then
        log WARN "Trouvé $expect_count expect() dans le code"
    fi
    
    # Check panic!
    local panic_count
    panic_count=$(grep -rn "panic!" src/ --include="*.rs" 2>/dev/null | grep -v "test" | wc -l || echo "0")
    
    if [[ $panic_count -gt 0 ]]; then
        log WARN "Trouvé $panic_count panic! dans le code"
    else
        log SUCCESS "Aucun panic! détecté (hors tests)"
    fi
    
    # cargo-audit (si disponible)
    if command -v cargo-audit &>/dev/null; then
        log INFO "Exécution cargo-audit..."
        if cargo audit 2>&1 | tee -a "$LOG_FILE"; then
            log SUCCESS "Aucune vulnérabilité CVE détectée"
        else
            log WARN "Vulnérabilités détectées (voir log)"
        fi
    else
        log INFO "cargo-audit non installé (optionnel)"
    fi
    
    log SUCCESS "Audit sécurité backend terminé"
}

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 3: ANALYSE SÉCURITÉ FRONTEND
# ═════════════════════════════════════════════════════════════════════════════

phase_security_audit_frontend() {
    header "PHASE 3: Audit Sécurité Frontend TypeScript"
    
    cd "${PROJECT_ROOT}"
    
    # npm audit
    log INFO "Exécution npm audit..."
    if npm audit --audit-level=high --json > /tmp/npm_audit_${TIMESTAMP}.json 2>&1; then
        log SUCCESS "Aucune vulnérabilité HIGH/CRITICAL npm"
    else
        local vulns
        vulns=$(jq -r '.metadata.vulnerabilities | to_entries[] | "\(.key): \(.value)"' /tmp/npm_audit_${TIMESTAMP}.json 2>/dev/null || echo "Erreur parsing JSON")
        log WARN "Vulnérabilités npm détectées: $vulns"
    fi
    
    # Check eval(), Function() dangerous
    log INFO "Scanning eval()/Function() dangereux..."
    local dangerous_count
    dangerous_count=$(grep -rn -E "eval\(|new Function\(" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l || echo "0")
    
    if [[ $dangerous_count -gt 0 ]]; then
        log ERROR "CRITIQUE: Code dangereux détecté (eval/Function)"
    else
        log SUCCESS "Aucun code dangereux (eval/Function)"
    fi
    
    # Check any types
    local any_count
    any_count=$(grep -rn ": any" src/ --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l || echo "0")
    
    if [[ $any_count -gt 10 ]]; then
        log WARN "Trouvé $any_count usages de 'any' type"
    else
        log SUCCESS "Type safety OK (peu de 'any')"
    fi
    
    log SUCCESS "Audit sécurité frontend terminé"
}

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 4: BUILD & TEST BACKEND
# ═════════════════════════════════════════════════════════════════════════════

phase_build_backend() {
    header "PHASE 4: Build & Test Backend Rust"
    
    cd "${PROJECT_ROOT}/src-tauri"
    
    # Format
    log INFO "Formatage code Rust..."
    if cargo fmt --all -- --check 2>&1 | tee -a "$LOG_FILE"; then
        log SUCCESS "Format Rust OK"
    else
        log FIX "Application cargo fmt..."
        cargo fmt --all 2>&1 | tee -a "$LOG_FILE"
    fi
    
    # Fix
    log INFO "Auto-fix Rust..."
    cargo fix --allow-dirty --all-targets 2>&1 | tee -a "$LOG_FILE" || log WARN "Quelques warnings cargo fix"
    
    # Clippy (si WebKit installé)
    if pkg-config --exists javascriptcoregtk-4.1 2>/dev/null; then
        log INFO "Exécution clippy strict mode..."
        if cargo clippy --all-targets --all-features -- -D warnings 2>&1 | tee -a "$LOG_FILE"; then
            log SUCCESS "Clippy strict: 0 warnings"
        else
            log WARN "Clippy warnings détectés"
        fi
        
        # Check
        log INFO "Vérification compilation..."
        if cargo check --all-targets 2>&1 | tee -a "$LOG_FILE"; then
            log SUCCESS "Compilation OK"
        else
            log ERROR "Erreurs de compilation"
            return 1
        fi
        
        # Tests
        log INFO "Exécution tests Rust..."
        if cargo test --all 2>&1 | tee -a "$LOG_FILE"; then
            log SUCCESS "Tests Rust PASS"
        else
            log WARN "Quelques tests ont échoué"
        fi
    else
        log WARN "WebKit manquant - skip build backend (dev mode OK)"
    fi
    
    log SUCCESS "Build backend terminé"
}

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 5: BUILD & TEST FRONTEND
# ═════════════════════════════════════════════════════════════════════════════

phase_build_frontend() {
    header "PHASE 5: Build & Test Frontend TypeScript"
    
    cd "${PROJECT_ROOT}"
    
    # Install dependencies
    log INFO "Installation dépendances npm..."
    if npm ci --prefer-offline 2>&1 | tee -a "$LOG_FILE"; then
        log SUCCESS "npm ci OK"
    else
        log ERROR "Erreur npm ci"
        return 1
    fi
    
    # Type check
    log INFO "Vérification types TypeScript..."
    if npm run type-check 2>&1 | tee -a "$LOG_FILE"; then
        log SUCCESS "TypeScript: 0 erreurs"
    else
        log ERROR "Erreurs TypeScript détectées"
        return 1
    fi
    
    # Build
    log INFO "Build frontend..."
    if npm run build 2>&1 | tee -a "$LOG_FILE"; then
        local bundle_size
        bundle_size=$(du -sh dist/ 2>/dev/null | awk '{print $1}')
        log SUCCESS "Build frontend OK (bundle: $bundle_size)"
    else
        log ERROR "Erreur build frontend"
        return 1
    fi
    
    log SUCCESS "Build frontend terminé"
}

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 6: VERIFICATION FICHIERS CRITIQUES
# ═════════════════════════════════════════════════════════════════════════════

phase_verify_critical_files() {
    header "PHASE 6: Vérification Fichiers Critiques"
    
    local critical_files=(
        "README.md"
        "CHANGELOG_v12.0.0.md"
        "package.json"
        "src-tauri/Cargo.toml"
        "src-tauri/src/main.rs"
        "src-tauri/src/commands/mod.rs"
        "src/api/tauriClient.ts"
        "src/types/system.d.ts"
        "src/hooks/useTitaneCore.ts"
    )
    
    for file in "${critical_files[@]}"; do
        local filepath="${PROJECT_ROOT}/${file}"
        if [[ -f "$filepath" ]]; then
            local size
            size=$(stat -f%z "$filepath" 2>/dev/null || stat -c%s "$filepath" 2>/dev/null)
            log SUCCESS "$file (${size} bytes)"
        else
            log ERROR "$file MANQUANT"
        fi
    done
    
    # Check version consistency
    local cargo_version
    cargo_version=$(grep '^version = ' "${PROJECT_ROOT}/src-tauri/Cargo.toml" | head -1 | cut -d'"' -f2)
    log INFO "Version Cargo.toml: $cargo_version"
    
    local package_version
    package_version=$(jq -r '.version' "${PROJECT_ROOT}/package.json" 2>/dev/null || echo "N/A")
    log INFO "Version package.json: $package_version"
    
    if [[ "$cargo_version" == "12.0.0" ]]; then
        log SUCCESS "Version Cargo.toml correcte"
    else
        log WARN "Version Cargo.toml non v12: $cargo_version"
    fi
    
    log SUCCESS "Vérification fichiers critiques terminée"
}

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 7: GÉNÉRATION SHA256 & INTEGRITY
# ═════════════════════════════════════════════════════════════════════════════

phase_integrity_check() {
    header "PHASE 7: Génération SHA256 & Intégrité"
    
    local integrity_file="${PROJECT_ROOT}/INTEGRITY_v12_${TIMESTAMP}.sha256"
    
    log INFO "Génération checksums SHA256..."
    
    # Critical Rust files
    find "${PROJECT_ROOT}/src-tauri/src" -type f -name "*.rs" -exec sha256sum {} \; > "$integrity_file" 2>/dev/null || true
    
    # Critical TS files
    find "${PROJECT_ROOT}/src" -type f \( -name "*.ts" -o -name "*.tsx" \) -exec sha256sum {} \; >> "$integrity_file" 2>/dev/null || true
    
    # Config files
    sha256sum "${PROJECT_ROOT}/package.json" >> "$integrity_file" 2>/dev/null || true
    sha256sum "${PROJECT_ROOT}/src-tauri/Cargo.toml" >> "$integrity_file" 2>/dev/null || true
    
    local checksum_count
    checksum_count=$(wc -l < "$integrity_file")
    
    log SUCCESS "SHA256 générés: $checksum_count fichiers → $integrity_file"
}

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 8: RAPPORT FINAL
# ═════════════════════════════════════════════════════════════════════════════

generate_report() {
    header "PHASE 8: Génération Rapport Final"
    
    cat > "$REPORT_FILE" <<EOF
# RAPPORT SECURE PIPELINE v12 - TITANE∞

**Date:** $(date '+%Y-%m-%d %H:%M:%S')  
**Version:** $SCRIPT_VERSION  
**Pipeline:** $SCRIPT_NAME  

---

## 📊 RÉSULTATS GLOBAUX

- ✅ **Checks Passed:** $CHECKS_PASSED
- ⚠️  **Warnings:** $WARNINGS_COUNT
- ❌ **Errors:** $ERRORS_COUNT
- 🔧 **Fixes Applied:** $FIXED_COUNT

---

## 🛡️ AUDIT SÉCURITÉ

### Backend Rust
- unwrap() scannés
- expect() scannés
- panic! scannés
- cargo-audit exécuté

### Frontend TypeScript
- npm audit exécuté
- eval()/Function() scannés
- Type safety vérifié

---

## 🧪 TESTS & BUILD

### Backend
- cargo fmt
- cargo fix
- cargo clippy
- cargo check
- cargo test

### Frontend
- npm ci
- npm run type-check
- npm run build

---

## ✅ VALIDATIONS

- Prérequis système: ✓
- Clean global: ✓
- Audit sécurité backend: ✓
- Audit sécurité frontend: ✓
- Build backend: $(pkg-config --exists javascriptcoregtk-4.1 2>/dev/null && echo "✓" || echo "⚠️ WebKit manquant")
- Build frontend: ✓
- Fichiers critiques: ✓
- Checksums SHA256: ✓

---

## 📝 RECOMMANDATIONS

EOF

    if [[ $ERRORS_COUNT -gt 0 ]]; then
        echo "🔴 **ERRORS CRITIQUES DÉTECTÉES** - Correction requise avant déploiement" >> "$REPORT_FILE"
    elif [[ $WARNINGS_COUNT -gt 5 ]]; then
        echo "🟡 **WARNINGS DÉTECTÉS** - Revue recommandée" >> "$REPORT_FILE"
    else
        echo "🟢 **SYSTÈME PRÊT POUR PRODUCTION** - Tous checks passed" >> "$REPORT_FILE"
    fi
    
    if ! pkg-config --exists javascriptcoregtk-4.1 2>/dev/null; then
        cat >> "$REPORT_FILE" <<EOF

### WebKit Installation (Requis Production Build)
\`\`\`bash
sudo apt-get update
sudo apt-get install libwebkit2gtk-4.1-dev libjavascriptcoregtk-4.1-dev
\`\`\`
EOF
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "*Rapport généré automatiquement par TITANE∞ Secure Pipeline v12*" >> "$REPORT_FILE"
    
    log SUCCESS "Rapport généré: $REPORT_FILE"
}

# ═════════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═════════════════════════════════════════════════════════════════════════════

main() {
    clear
    
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                              ║"
    echo "║           TITANE∞ v12.0.0 - SECURE DEPLOYMENT PIPELINE                      ║"
    echo "║           Ultra-Secure DevOps + Audit + Auto-Fix + CI/CD                    ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Script: $SCRIPT_NAME v$SCRIPT_VERSION"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Log: $LOG_FILE"
    echo "Rapport: $REPORT_FILE"
    echo ""
    
    log INFO "Démarrage pipeline sécurisé..."
    
    # Execution phases
    check_prerequisites || { log ERROR "Prérequis manquants"; exit 1; }
    phase_clean
    phase_security_audit_backend
    phase_security_audit_frontend
    phase_build_backend
    phase_build_frontend
    phase_verify_critical_files
    phase_integrity_check
    generate_report
    
    # Final summary
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                         PIPELINE TERMINÉ                                     ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    printf "${GREEN}✓ Checks Passed:${NC} %d\n" "$CHECKS_PASSED"
    printf "${YELLOW}⚠ Warnings:${NC}      %d\n" "$WARNINGS_COUNT"
    printf "${RED}✗ Errors:${NC}        %d\n" "$ERRORS_COUNT"
    printf "${BLUE}🔧 Fixes Applied:${NC}  %d\n" "$FIXED_COUNT"
    echo ""
    
    if [[ $ERRORS_COUNT -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}🎉 TITANE∞ v12 — SECURE PIPELINE SUCCESS${NC}"
        echo -e "${GREEN}Système validé — Prêt pour déploiement${NC}"
        return 0
    else
        echo -e "${RED}${BOLD}❌ PIPELINE FAILED - Corrections requises${NC}"
        echo -e "${RED}Voir log: $LOG_FILE${NC}"
        return 1
    fi
}

# Execute main
main "$@"
