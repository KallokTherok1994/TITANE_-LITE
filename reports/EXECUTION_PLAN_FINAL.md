# ⚙️ EXECUTION PLAN FINAL — 3-Cycle Implementation

**Document**: `reports/EXECUTION_PLAN_FINAL.md`  
**Scope**: Sprint 1-4 (7 days), 3 cycles  
**Status**: Post-audit remediation plan  
**Authority**: PΩ∞.META.FINAL.REVIEW.SEAL

---

## EXECUTIVE SUMMARY

TITANE∞ has **perfect architecture, incomplete execution**. 

**Status**: 2.5/7 gates PASS (35.7% complete for production)

**Path to Stable**: 7 days, 4 sprints, 8 fixes

**Blocking Issues** (🔴):
1. Provider order inverted (GATE_2 FAIL)
2. Assimilation never called (GATE_3 FAIL)

**Major Issues** (🟡):
3. UIWatchdog unintegrated (GATE_4)
4. Tracing absent (GATE_6)
5. Rust contracts missing (GATE_1)
6. Test coverage gaps (GATE_5)
7. Docs incomplete (Governance)

**Non-Negotiable Guarantees**:
- ✅ Always Respond: VALIDATED (3-layer protection confirmed)
- ✅ Zero Silence: VALIDATED
- ✅ Offline Available: VALIDATED (capability exists)
- ✅ Rollback Works: VALIDATED (all changes reversible)

---

## CYCLE A: ANTI-SILENCE STABILIZATION (Sprint 1 — Days 1-3)

**Goal**: Fix 3 blocking issues (GATE_2, GATE_3 prerequisites); unblock Sprint 2.

**Dependency**: Already validated in Phase 0; focus on integration fixes.

### SPRINT 1 — DAY 1: FIX #1 — Provider Order (GATE_2)

**Blocker**: Online providers (Gemini/OpenAI) called BEFORE offline (Ollama/Skills)

**File**: `src/services/ai/ProviderRouter.ts` line 196

**Change**:
```typescript
// FROM (wrong):
const providerArray = ['cache', 'gemini', 'openai', 'ollama'];

// TO (correct):
const providerArray = ['cache', 'skills', 'template', 'ollama', 'gemini', 'openai'];
```

**Validation**:
```bash
pnpm run test:gates -- gate2-offline-first.spec.ts
# Expected: 8/8 tests PASS
```

**Rollback**: < 5 min (1 git revert)

**Time**: 4-6 hours

---

### SPRINT 1 — DAY 2: FIX #2 — Assimilation Activation (GATE_3)

**Blocker**: `assimilateResponse()` never called; zero learning (skillsCreated=0)

**File**: `src/services/ai/ProviderRouter_Ring3.ts` line 250

**Change**:
```typescript
// After online response, ADD:
if (result && result.ok) {
  AssimilationService.getInstance()
    .assimilateResponse(
      request.content,
      result.content,
      result.provider,
      result.metadata?.confidence ?? 0.8
    )
    .catch(err => console.warn('[Assimilation]', err));
}
```

**Validation**:
```bash
pnpm run test:gates -- gate3-assimilation.spec.ts
# Expected: 12/12 tests PASS
```

**Metrics Proof**:
- Before: skillsCreated = 0
- After 10 online queries: skillsCreated >= 1 (depends on quality)

**Rollback**: < 5 min (1 git reve rt)

**Time**: 4-6 hours

---

### SPRINT 1 — DAY 3: E2E Validation

**Goal**: Run full test suite 3× consecutively; zero failures.

**Commands**:
```bash
# Run 1
pnpm run test:all:full
# Expected: PASS

# Run 2 (5 min after Run 1)
pnpm run test:all:full
# Expected: PASS (identical results to Run 1)

# Run 3 (5 min after Run 2)
pnpm run test:all:full
# Expected: PASS (identical results to Run 1 & 2)
```

**Metrics Validation**:
```bash
# Verify offline capability works
TITANE_MODE=OFFLINE pnpm run test:gates -- gate-offline-zero-network.test.ts
# Expected: ZERO network calls

# Verify skills are created
pnpm run test:gates -- gate3-assimilation.spec.ts
# Expected: skillsCreated > 0 after 10 queries
```

**Sign-off**: If all PASS 3×, mark CYCLE A COMPLETE

**Time**: 6 hours (includes stabilization)

---

## CYCLE B: INTELLIGENCE ORCHESTRATION (Sprint 2 — Days 4-5)

**Goal**: Integrate UI improvements + observability; unblock production deployment.

**Dependency**: CYCLE A must PASS 3×

### SPRINT 2 — DAY 1 (Day 4): FIX #3  — UIWatchdog Integration (GATE_4)

**Issue**: UIWatchdog component exists but not called in production (`useChat.ts`)

**File**: `src/hooks/useChat.ts`

**Change**:
```typescript
// Add import
import { useUIWatchdog } from '@/components/autonomy/UIWatchdog';

// Initialize hook (line 50)
const { startWatching, stopWatching } = useUIWatchdog({
  searchingTimeoutMs: 5000,
  hardTimeoutMs: 10000,
});

// Remove manual timeout (line 513)
// const HARD_TIMEOUT_MS = 10000;  // DELETE

// Use hook instead (line 1193)
// OLD: setTimeout(() => {...}, HARD_TIMEOUT_MS);
// NEW: startWatching(request);
```

**Validation**:
```bash
pnpm run test -- uiwatchdog-integration.spec.ts
# Expected: 3/3 tests PASS
```

**UI Behavior**:
- 0-5s: Silent (searching happening)
- 5s+: Shows "Searching..." indicator
- 10s+: Shows fallback response + indicator hidden

**Time**: 4-6 hours

---

### SPRINT 2 — DAY 2 (Day 5): FIX #4 — Tracing System (GATE_6)

**Issue**: No structured tracing (no trace_id, no offline proof)

**Files to Create**: 
- `src/services/observability/TracingService.ts` (500 lines)
- `src/services/observability/TraceExporter.ts` (200 lines)

**Implementation Overview**:

```typescript
// TracingService: Singleton
export class TracingService {
  private traces: Map<string, Trace> = new Map();
  
  startTrace(requestId: string, mode: AutonomyMode): string {
    const traceId = generateUUID();
    this.traces.set(traceId, {
      trace_id: traceId,
      request_id: requestId,
      steps: [],
      network_calls: 0,
      offline: mode === AutonomyMode.OFFLINE,
    });
    return traceId;
  }
  
  recordStep(traceId: string, step: TraceStep): void {
    const trace = this.traces.get(traceId);
    if (trace) trace.steps.push(step);
  }
  
  endTrace(traceId: string): Trace {
    return this.traces.get(traceId)!;
  }
  
  exportTrace(traceId: string): string {
    const trace = this.traces.get(traceId)!;
    return JSON.stringify(trace, null, 2);
  }
}
```

**Instrumentation**: Add `recordStep()` calls to:
- Ring 2 engines (SkillEngine, StrategySelector, AssimilationEngine)
- Ring 3 services (ProviderRouter, ResponseComposer)
- Ring 4 components (useChat)

**Validation**:
```bash
pnpm run test:gates -- gate6-tracing.spec.ts
# Expected: 10+ tests PASS
```

**Offline Proof Export**:
```typescript
// After request
const trace = TracingService.getInstance().exportTrace(requestId);
console.log(trace);  // JSON with trace_id, steps, network_calls=0, offline=true
```

**Time**: 8-12 hours (extensive instrumentation)

---

## CYCLE C: COMPLIANCE & CERTIFICATION (Sprint 3-4 — Days 6-7)

**Goal**: Ensure all gates PASS; obtain stable certification.

### SPRINT 3 — DAY 1 (Day 6): Contract Layer & Backend Consistency

**Remaining Fixes**:
1. FIX #5: Rust contract mirrors (`src-tauri/src/api/contracts.rs`)
2. FIX #6: Enhanced test suite (`gate1-contract-ipc.spec.ts`)
3. FIX #7: Documentation (`docs/CONVERSATION_AI_CANON.md`)

**Implementation**:
```bash
# Create Rust contracts
# (see PROMPTS_GAPS_AND_FIXES.md GAP_1 for full code)

# Create contract tests
# (see PROMPTS_GAPS_AND_FIXES.md GAP_6 for full code)

# Update documentation
# (see docs/CONVERSATION_AI_CANON.md)
```

**Validation**:
```bash
# All gates
pnpm run test:all:full

# Specific focus on GATE_1
pnpm run test:gates -- gate1-contract-ipc.spec.ts
# Expected: 6+ tests PASS
```

**Time**: 6-8 hours

---

### SPRINT 4 — DAY 1 (Day 7): Final Audit & Certification

**Goal**: Verify all 7 gates PASS; obtain STABLE certification (upgrade from QUALIFIED)

**Execution**:

```bash
# 1. Full test suite (Run 1)
pnpm run test:all:full
# Expected: ALL tests PASS

# 2. Gate validation (Run 1)
./scripts/verify/gate-all.sh
# Expected: 7/7 gates PASS

# 3. Full test suite (Run 2 — 15 min later)
pnpm run test:all:full
# Expected: IDENTICAL to Run 1

# 4. Gate validation (Run 2)
./scripts/verify/gate-all.sh
# Expected: IDENTICAL to Run 1

# 5. Offline proof exportable
TITANE_MODE=OFFLINE pnpm run test:gates -- gate4-offline-zero-network.test.ts
# Expected: PASS + trace_id exported with network_calls=0

# 6. Generate final reports
pnpm run audit:master
# Expected: GREEN across all 7 stages

# 7. Sign-off
echo "CERTIFICATION_APPROVED=2026-02-14T00:00:00Z" > .certification
git add .certification
git commit -m "🎉 STABLE CERTIFICATION: All 7 gates PASS 2×"
```

**Certification Decision**: If all PASS 2× with identical results → **STABLE** ✅

**Time**: 4-6 hours

---

## ROLL-OUT PROCEDURE

### Pre-Deployment (30 min)

```bash
# 1. Code review
# 2. Backup current production
cp -r /app/titane-stable /backups/titane-pre-sprint4-backup

# 3. Run full test suite locally
pnpm run test:all:full

# 4. Build production artifacts
pnpm run build:production

# 5. Generate hashes
sha256sum dist/* src-tauri/target/release/* > .deployment-hashes
```

### Deployment (5-10 min)

```bash
# 1. Deploy frontend
cp dist/* /var/www/titane/

# 2. Deploy backend (or restart service)
systemctl restart titane-backend

# 3. Smoke test (5 min)
curl -X POST http://localhost:9000/api/chat \
  -d '{ "content": "test", "mode": "offline" }' \
  -H "Content-Type: application/json"
# Expected: 200 OK + valid ChatResult

# 4. Verify offline mode
curl ... -d '{ "mode": "offline" }' ...
# Expected: ZERO network calls in trace

# 5. Monitor logs (5 min)
tail -f /var/log/titane/app.log
# Expected: NO errors, gates PASS metrics visible
```

### Rollback (if needed within 5 min)

```bash
# 1. Revert to backup
rm -rf /app/titane-stable
cp -r /backups/titane-pre-sprint4-backup /app/titane-stable

# 2. Restart
systemctl restart titane-backend

# 3. Verify
# (repeat smoke test above)
```

---

## DEPENDENCY MATRIX

```
SPRINT 1
├── Day 1: FIX #1 (Provider Order) — GATE_2
├── Day 2: FIX #2 (Assimilation) — GATE_3 (depends on FIX #1)
└── Day 3: Validation 3× PASS

SPRINT 2
├── Day 1: FIX #3 (UIWatchdog) — GATE_4 (optional, doesn't block)
└── Day 2: FIX #4 (Tracing) — GATE_6 (optional, doesn't block)

SPRINT 3
└── Day 1: FIX #5-7 (Contracts + Tests + Docs)

SPRINT 4
└── Day 1: Final Audit 2× PASS → CERTIFICATION
```

**Critical Path**: FIX #1 → FIX #2 → Validation 3× → (GATE_2 + GATE_3 PASS)

**Optional Path**: FIX #3, FIX #4 (can be parallel with SPRINT 2 IF dev team has capacity)

---

## SUCCESS METRICS

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Gates PASS | 2.5/7 (35.7%) | 7/7 (100%) | 7/7 |
| skillsCreated | 0 | 10+ | > 100 (30-day target) |
| learningRate | 0% | > 0% | > 80% (30-day target) |
| API quota savings | $0 | TBD | 60%+ |
| Offline independence | 35% | 80%+ | 100% (goal) |
| Test coverage | 65% | 75%+ | 80%+ |
| Latency (offline) | - | < 50ms | < 100ms |
| Test flakiness | 0% | 0% | 0% |
| Rollback time | N/A | < 5 min | < 5 min |

---

## CONTINGENCY

### If FIX #1 or #2 breaks production (within 5 min):

```bash
1. git revert HEAD --no-edit
2. cargo build --release && pnpm run build:vite
3. systemctl restart titane-backend
4. Verify smoke test PASS
```

**Decision**: HALT further implementation; investigate root cause; prep FIX v2.

### If CYCLE A doesn't achieve 3× PASS:

```bash
1. Review failed tests (which gate?)
2. Root cause analysis (30 min)
3. Prep corrected fix
4. Re-run validation (don't proceed to CYCLE B)
```

---

## SIGN-OFF

**Validation Required Before Deployment**:
- [ ] CYCLE A: 3× consecutive PASS (identical results)
- [ ] CYCLE B: No new failures introduced
- [ ] CYCLE C: All 7 gates PASS 2×
- [ ] Offline proof exportable
- [ ] Rollback script tested
- [ ] Kevin Thibault explicit approval ("GO FOR STABLE")

**Authority**: PΩ∞.META.FINAL.REVIEW.SEAL

---

**Target Completion**: 2026-02-14 (7 days from 2026-02-07)

**Status**: Ready for SPRINT 1 Day 1 execution.

