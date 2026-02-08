# 🎯 TITANE∞ Testing Strategy — Priority Action Plan

**Date**: 2026-02-07  
**Status**: Phase 0 Complete → Phase 1-8 Roadmap  
**Authority**: ULTRA SUPER PROMPT — TESTS.FULL.STACK.SEAL.FINAL

---

## 🚨 CRITICAL FINDINGS (Phase 0 Audit)

### ❌ BLOCKING ISSUES

1. **Test Duration**: Suites bloquent/timeout (test:architecture, test:compliance)  
   → **Impact**: CI pipeline fragile, développement ralenti  
   → **Root Cause**: Tests lourds ou mal isolés

2. **E2E Dual-Runner Chaos**: Playwright (web) + WDIO (desktop) en parallèle  
   → **Impact**: Confusion, maintenance 2×, flakiness potentiel  
   → **Root Cause**: Pas de stratégie E2E canonique unique

3. **Offline Proof Missing**: Aucun test prouvant 0 réseau en mode OFFLINE  
   → **Impact**: ❌ VIOLATION LOI #1 (local-first absolu)  
   → **Root Cause**: NetworkGuard non testé contractuellement

4. **IPC Contract Gaps**: Contrats ChatResult non systématiquement testés  
   → **Impact**: Risque silence/empty responses  
   → **Root Cause**: Tests contract/ incomplets

### ⚠️ HIGH-RISK ISSUES

5. **Watchdog Anti-Silence**: Tests UI anti-loading-infini non vérifiés  
   → **Impact**: UX freeze possible  
   → **Root Cause**: Patches A1-A3 actifs mais non testés

6. **4-Ring Coverage Unknown**: Aucune matrice Ring → Tests  
   → **Impact**: Régression possible sur architecture  
   → **Root Cause**: Pas de mapping Ring 1-4 → test files

7. **Flakiness Non Mesuré**: Pas de baseline flakiness (3× runs)  
   → **Impact**: Tests instables non détectés  
   → **Root Cause**: Pas de protocole systematic retry

---

## 🎯 PHASE-BY-PHASE ROADMAP

### ✅ PHASE 0: INVENTAIRE (COMPLETE)

**Deliverables**:
- ✅ `TESTS_INVENTORY.md` (exhaustif, 98 test files identified)
- ⏳ `TESTS_BASELINE.json` (exécution bloquée → workaround rapide)

**Next**: Phase 1 avec baseline minimal

---

### 🔥 PHASE 1: GATES CRITIQUES IMMÉDIATS (PRIORITY 1)

**Objectif**: Implémenter gates bloquants minimum pour éviter régressions critiques

#### 1.1 GATE_BOOT (Boot Deterministe)

**Test à créer**: `tests/gates/gate-boot.test.ts`

```typescript
describe('GATE_BOOT: App Must Boot', () => {
  it('should boot dev server in < 30s', async () => {
    // Start dev → Wait for "ready" marker → Assert success
  });

  it('should mount UI with OMEGA marker', async () => {
    // Check window.TITANE_OMEGA_READY || DOM marker
  });
});
```

**Blocker si**: Boot > 30s OU pas de marker ready

---

#### 1.2 GATE_CHAT_ALWAYS_RESPOND (Zéro Silence)

**Test à créer**: `tests/gates/gate-chat-always-respond.test.ts`

```typescript
describe('GATE_CHAT: Always Respond', () => {
  it('should NEVER return empty content', async () => {
    // Mock 10 providers failures → Assert userMessage fallback
  });

  it('should trigger watchdog on timeout', async () => {
    // Mock provider timeout → Assert UI shows fallback < 10s
  });

  it('should display userMessage on backend error', async () => {
    // Mock IPC error → Assert UI shows error (not empty bubble)
  });
});
```

**Blocker si**: ANY test return silence/empty bubble

---

#### 1.3 GATE_OFFLINE_ZERO_NETWORK (Offline Proof)

**Test à créer**: `tests/gates/gate-offline-zero-network.test.ts`

```typescript
describe('GATE_OFFLINE: Zero Network Attempts', () => {
  it('should block all network in OFFLINE mode', async () => {
    // Set offlineMode: true
    // Spy on fetch/axios/http
    // Send 10 prompts
    // Assert: 0 network calls
  });

  it('should generate offline proof', async () => {
    // offlineMode: true → Assert proof.offlineMode === true
    // Assert proof.networkAttempted === false
    // Assert proof.signature exists
  });
});
```

**Blocker si**: networkAttempted === true en mode OFFLINE

---

#### 1.4 GATE_IPC_CONTRACT (ChatResult Strict)

**Test à créer**: `tests/gates/gate-ipc-contract.test.ts`

```typescript
describe('GATE_IPC: ChatResult Contract', () => {
  it('should return ok:true + non-empty content on success', async () => {
    // Mock success → Assert ChatResult.ok === true
    // Assert ChatResult.content.trim().length > 0
  });

  it('should return ok:false + userMessage on error', async () => {
    // Mock error → Assert ChatResult.ok === false
    // Assert ChatResult.userMessage exists
  });

  it('should NEVER throw uncaught exceptions', async () => {
    // Test all IPC commands with invalid inputs
    // Assert: all return ChatResult (no throw)
  });
});
```

**Blocker si**: ANY command throws OR returns undefined

---

### 📋 PHASE 2: MATRICE 4-RING (PRIORITY 2)

**Objectif**: Mapper tous les tests existants aux Rings + identifier gaps

#### 2.1 Créer `TEST_MATRIX.md`

Format:

```markdown
| Test File | Ring | Coverage | Priority Gap |
|-----------|------|----------|--------------|
| tests/integration/conversation-intelligence-bridge.test.ts | Ring 2-3 | ✅ 17/17 | None |
| tests/engines/*.test.ts | Ring 2 | ⏳ TBD | Understanding/Reasoning |
| tests/services/*.test.ts | Ring 3 | ⏳ TBD | NetworkGuard proof |
| tests/components/*.test.ts | Ring 4 | ⏳ TBD | Watchdog, empty bubble |
| e2e/*.spec.ts | Cross-Ring | ⚠️ Unstable | Desktop E2E canonical |
```

#### 2.2 Validation GATE_P1

**Requis**: Tous les composants critiques DOIVENT avoir ≥1 test

**Critical Components** (minimum):
- [x] Ring 1: Types (via tsc)
- [ ] Ring 2: StrategySelector
- [ ] Ring 2: ResponseComposer
- [ ] Ring 2: UnderstandingEngine
- [ ] Ring 2: ReasoningEngine
- [ ] Ring 3: ProviderRouter (offline proof)
- [ ] Ring 3: NetworkGuard (zero network)
- [ ] Ring 4: ChatBubble (no empty)
- [ ] Ring 4: UIWatchdog (timeout fallback)
- [ ] Cross: E2E Desktop boot
- [ ] Cross: E2E Desktop chat

**Blocker si**: ANY critical component sans test

---

### 🔒 PHASE 3: CONTRACTS ANTI-SILENCE (PRIORITY 1)

**Objectif**: Garantir 100% "Always Respond" (zéro silence possible)

#### 3.1 IPC All Commands Audit

**Script à créer**: `scripts/audit/audit-ipc-contracts.ts`

```typescript
// Scan src-tauri/src/**/*.rs
// Extract all #[tauri::command] functions
// Generate test skeleton for each
// Validate: all return Result<ChatResult, String>
```

#### 3.2 UI Anti-Empty Bubble Tests

**Tests à ajouter** dans `tests/components/chat/ChatBubble.test.tsx`:

```typescript
describe('ChatBubble Anti-Empty', () => {
  it('should refuse to render empty content', () => {
    // Try render with content: ""
    // Assert: fallback message displayed
  });

  it('should show error on undefined content', () => {
    // Try render with content: undefined
    // Assert: error boundary or fallback
  });
});
```

#### 3.3 Watchdog Tests

**Tests à ajouter** dans `tests/components/autonomy/UIWatchdog.test.tsx`:

```typescript
describe('UIWatchdog Timeout', () => {
  it('should trigger fallback after 10s', async () => {
    vi.useFakeTimers();
    // Start chat request
    // Advance time 10s
    // Assert: fallback message shown
  });
});
```

---

### 🌐 PHASE 4: E2E DESKTOP STABLE (PRIORITY 1)

**Objectif**: Stratégie E2E canonique unique (Tauri desktop)

#### 4.1 Décision: Playwright OU WDIO (pas les deux)

**Recommandation**: **WDIO + tauri-driver** (car Tauri-only mode)

**Rationale**:
- Playwright = web-first (Vite dev server)
- WDIO = desktop-first (Tauri app binary)
- TITANE∞ = Tauri-only → WDIO canonical

**Action**:
1. Migrer tests Playwright critiques → WDIO
2. Garder Playwright en "legacy smoke" (optionnel)
3. Documenter: WDIO = canonical, Playwright = deprecated

#### 4.2 E2E Minimum Suite (Tauri Desktop)

**Scénarios obligatoires** dans `e2e/desktop/critical.spec.ts`:

```javascript
describe('Critical Desktop E2E', () => {
  it('BOOT: App launches in < 30s', async () => {
    // Start Tauri app
    // Wait for window
    // Assert: title contains "TITANE"
  });

  it('CHAT: 3 prompts → 3 responses', async () => {
    // Type 3 messages
    // Assert: 3 assistant bubbles (non-empty)
  });

  it('OFFLINE: Network disabled → responses still work', async () => {
    // Disable network (mock or real)
    // Send 3 prompts
    // Assert: 3 responses + offline proof
  });

  it('PERSISTENCE: Conversation persists on reload', async () => {
    // Send message
    // Restart app
    // Assert: message still visible
  });

  it('ERROR_VISIBILITY: Backend error → UI shows message', async () => {
    // Trigger backend error
    // Assert: error message visible (not empty)
  });
});
```

**GATE_P4**: 3 runs consécutifs → 3× PASS (no flaky)

---

### ⚡ PHASE 5: VITEST OPTIMISATION (PRIORITY 2)

**Objectif**: Tests rapides, déterministes, non-flaky

#### 5.1 Anti-Flaky Rules

**À implémenter partout**:

```typescript
// ✅ GOOD
vi.useFakeTimers(); // Déterministe
const seed = 12345; // Random seedé
const timeout = 5000; // Timeout centralisé

// ❌ BAD
await sleep(1000); // Non déterministe
Math.random(); // Non seedé
setTimeout(() => {}, 500); // Race condition
```

**Script audit**: `scripts/audit/detect-flaky-patterns.sh`

```bash
# Grep pour patterns flaky:
grep -r "sleep(" tests/
grep -r "setTimeout" tests/
grep -r "Math.random()" tests/
```

#### 5.2 Coverage Cible par Ring

**Thresholds à configurer** dans `vitest.config.ts`:

```typescript
coverage: {
  thresholds: {
    './src/types/**': { lines: 0 },      // Ring 1: TS check only
    './src/engines/**': { lines: 80 },   // Ring 2: Pure logic
    './src/services/**': { lines: 70 },  // Ring 3: I/O complex
    './src/components/**': { lines: 60 }, // Ring 4: UI render
    global: { lines: 70, branches: 65 },
  }
}
```

---

### 🦀 PHASE 6: RUST TESTS SYSTEMATIC (PRIORITY 2)

**Objectif**: Tests Rust complets + zero panic uncaught

#### 6.1 Tests Rust Minimum

**Critical modules** à tester:

```rust
// src-tauri/src/overdrive/chat_orchestrator.rs
#[cfg(test)]
mod tests {
    #[test]
    fn test_empty_content_guard() {
        // Test Patch A2: empty → fallback
    }

    #[test]
    fn test_provider_timeout_fallback() {
        // Test timeout → offline
    }
}

// src-tauri/src/memory/mod.rs
#[cfg(test)]
mod tests {
    #[test]
    fn test_persistence_roundtrip() {
        // Write → Read → Assert same
    }
}
```

#### 6.2 Tauri Command Contract Tests

**Script à créer**: `src-tauri/tests/tauri_commands_contract.rs`

```rust
#[cfg(test)]
mod tauri_commands_tests {
    #[test]
    fn all_commands_return_result() {
        // Test: aucun command ne panic
        // Test: tous retournent Result<T, E>
    }
}
```

**GATE_P6**: 0 panic non testé sur chemins critiques

---

### 🔧 PHASE 7: PIPELINE ONE-COMMAND (PRIORITY 3)

**Objectif**: Simplicité exécution + gates automatiques

#### 7.1 Scripts Normalisés

**Créer/Normaliser**:

```json
// package.json
{
  "scripts": {
    "test:smoke": "vitest run --config vitest.smoke.config.ts",
    "test:unit": "vitest run --config vitest.unit.config.ts",
    "test:integration": "vitest run --config vitest.integration.config.ts",
    "test:ui": "vitest run --config vitest.ui.config.ts",
    "test:e2e": "node scripts/e2e/run-desktop-suite.js",
    "test:rust": "cd src-tauri && cargo test",
    "test:gates": "vitest run tests/gates/**",
    "test:all": "pnpm run test:gates && pnpm run test:unit && pnpm run test:integration && pnpm run test:ui && pnpm run test:rust",
    "test:ci": "pnpm run test:all && pnpm run test:e2e"
  }
}
```

#### 7.2 Gates Orchestration

**Script**: `scripts/test/run-gates.sh`

```bash
#!/bin/bash
set -e

echo "🚪 Running Quality Gates..."

# GATE_BOOT
pnpm run test:gates:boot || { echo "❌ GATE_BOOT FAIL"; exit 1; }

# GATE_CHAT
pnpm run test:gates:chat || { echo "❌ GATE_CHAT FAIL"; exit 1; }

# GATE_OFFLINE
pnpm run test:gates:offline || { echo "❌ GATE_OFFLINE FAIL"; exit 1; }

# GATE_CONTRACT
pnpm run test:gates:contract || { echo "❌ GATE_CONTRACT FAIL"; exit 1; }

echo "✅ All Gates PASS"
```

**CI Integration**: `.github/workflows/tests.yml`

```yaml
- name: Quality Gates
  run: pnpm run test:gates
  # Blocker: exit 1 if any gate fails
```

---

### 🚀 PHASE 8: OPTIMISATION (PRIORITY 4)

**Objectif**: Vitesse + fiabilité (sans sacrifier qualité)

#### 8.1 Parallélisation

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    maxConcurrency: 4, // Limite workers
    sequence: {
      concurrent: true, // Tests // sauf E2E
    },
  },
});
```

#### 8.2 Cache Intelligent

```bash
# .github/workflows/tests.yml
- uses: actions/cache@v4
  with:
    path: |
      node_modules/.vite
      target/
      ~/.cargo
    key: test-cache-${{ hashFiles('pnpm-lock.yaml', 'Cargo.lock') }}
```

#### 8.3 Split Smoke vs Full

**Smoke** (< 2min):
- Gates
- Unit tests Ring 2
- Smoke E2E (3 scénarios)

**Full** (< 15min):
- Smoke +
- Integration Ring 3
- UI Ring 4
- E2E complet
- Rust backend

---

## 📊 SUCCESS METRICS (Done = PASS)

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| **Gates Implemented** | 4 | 0 | ❌ |
| **Gates Passing** | 4/4 | 0/4 | ❌ |
| **4-Ring Matrix** | 100% mapped | 0% | ❌ |
| **Critical Components Tested** | 11/11 | Unknown | ❌ |
| **Offline Proof Tests** | ≥3 | 0 | ❌ |
| **E2E Desktop Stable** | 3× PASS | Not run | ❌ |
| **Test Duration (smoke)** | < 2min | Unknown | ❌ |
| **Test Duration (full)** | < 15min | Unknown | ❌ |
| **Flakiness** | 0% | Unknown | ❌ |
| **Coverage Ring 2** | ≥ 80% | Unknown | ❌ |
| **Coverage Global** | ≥ 70% | Unknown | ❌ |

---

## 🎯 IMMEDIATE NEXT ACTIONS (PRIORITY ORDER)

### 🔥 CRITICAL (START NOW)

1. **Create Gates Suite** (`tests/gates/`)  
   - [ ] gate-boot.test.ts
   - [ ] gate-chat-always-respond.test.ts
   - [ ] gate-offline-zero-network.test.ts
   - [ ] gate-ipc-contract.test.ts

2. **Fix Test Execution Blocking**  
   - [ ] Debug why test:architecture/test:compliance timeout
   - [ ] Add timeout limits to all test configs
   - [ ] Skip broken tests temporarily (document reasons)

3. **Baseline Execution** (sans blocage)  
   - [ ] Run test:unit (timeout 5min)
   - [ ] Run test:integration (timeout 5min)
   - [ ] Capture results → `TESTS_BASELINE.json`

### 🟠 HIGH (THIS WEEK)

4. **4-Ring Matrix**  
   - [ ] Map all 98 test files to Rings
   - [ ] Identify gaps per ring
   - [ ] Generate `TEST_MATRIX.md`

5. **E2E Strategy Decision**  
   - [ ] Document: WDIO canonical, Playwright legacy
   - [ ] Create `E2E_DESKTOP_SUITE.md`
   - [ ] Implement 5 critical scenarios

6. **Coverage Baselines**  
   - [ ] Run test:coverage (capture report)
   - [ ] Set thresholds per ring
   - [ ] Document in `COVERAGE_REPORT.md`

### 🟡 MEDIUM (THIS MONTH)

7. **Rust Tests Expansion**  
   - [ ] Add tests for all critical Rust modules
   - [ ] Tauri command contract tests
   - [ ] Zero panic validation

8. **Flakiness Measurement**  
   - [ ] Run each suite 3× consecutively
   - [ ] Identify flaky tests
   - [ ] Document in `FLAKINESS_REPORT.md`

9. **Pipeline Optimization**  
   - [ ] Parallelize suites
   - [ ] Cache setup
   - [ ] Split smoke vs full

---

## 📞 SUPPORT & ESCALATION

**Blocker Escalation Path**:
1. Tests timeout > 5min sans progress → Document + skip avec FIXME
2. Gates fail → **NO MERGE** until fixed
3. E2E flaky > 10% → Quarantine test, investigate root cause

**Documentation Updates**:
- Update `TESTS_INVENTORY.md` après chaque changement structure
- Update ce document (`ACTION_PLAN.md`) avec status changes
- Générer `TESTS_FINAL_SUMMARY.md` à la fin Phase 8

---

**🎯 STATUS: Phase 0 COMPLETE → Phase 1 GATES (CRITICAL) IN PROGRESS**

_Prochaine mise à jour: Après création gates suite + baseline execution_
