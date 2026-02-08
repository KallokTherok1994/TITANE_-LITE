# 🔴 OFFLINE GAP ANALYSIS REPORT

**Generated:** 7 février 2026 19:10:00Z  
**Authority:** SUPER PROMPT #2 — Conversation Intelligence Implementation  
**Status:** PHASE 0 PREFLIGHTCHECK  

---

## EXECUTIVE SUMMARY

TITANE∞ cannot currently guarantee **100% offline mode** because:

1. ✅ Cognitive core (Ring 1-2) **IS offline-capable** (no network calls)
2. ✅ Memory service (Ring 3) **IS offline-capable** (localStorage)
3. ❌ **ProviderRouter does NOT enforce offline-first** → may attempt network
4. ❌ **No Always Respond guarantee** → can return empty on all provider failure
5. ❌ **No proof mechanism** → cannot verify zero network attempts
6. ❌ **No UI watchdog** → frozen UI possible on timeouts

**What prevents OFFLINE mode today:** 5 missing components + weak isolation.

---

## DETAILED GAPS

### GAP #1: NO EXPLICIT OFFLINE MODE (CRITICAL)

**Current State**

```typescript
// ProviderRouter.ts (current)
async routeRequest(message: string, context?: any) {
  // No "offlineMode" parameter
  // No way to disable network calls
  const response = await this.primaryProvider.generate(message);
  // If primary fails, tries secondary (which might be online)
}
```

**Problem**

- No flag to enforce OFFLINE mode
- Providers may attempt network calls without permission
- User cannot opt-in to guaranteed offline

**Impact**

- Test "Airplane Mode" impossible (no way to disable network)
- Users cannot guarantee privacy
- Providers cannot be audited for network access

**Blocked By**

- ProviderRouter + all providers need `offlineMode: boolean` parameter

---

### GAP #2: NO STRATEGY SELECTOR (CRITICAL)

**Current State**

Provider cascade order (hardcoded):
1. Ollama (local LLM, if available)
2. OpenAI (online, if key present)
3. Anthropic (online, if key present)
4. Gemini (online, if key present)
5. Local fallback (template)

**Problem**

- Skills never checked first
- Online providers may run before offline skills
- No retrieval step (if memory available)
- No template step (generic response)

**Impact in OFFLINE Mode**

Even with `offlineMode: true`:
- Skills (highest confidence) **bypassed**
- Online providers never get tried (correct) **but**
- Fallback order wrong (templates before skills)

**Desired Offline-First Strategy**

```
1. Skills (deterministic, pre-loaded, offline)
   → If match found, execute + return
   
2. Retrieval (from memory/knowledge base)
   → If sources found, compose + return
   
3. Templates (generic responses for common tasks)
   → If pattern matches, format + return
   
4. Local LLM (if available, though still "local")
   → If dispo, generate + return
   
5. Minimum Useful Answer (MUA fallback)
   → Always respond (never silent)
```

**Blocked By**

Need: `StrategySelector` engine (Ring 2.5) that:
- Takes UnderstandingFrame
- Available skills
- Available retrieval sources
- Available templates
- Environment flags (offlineMode, localLLMAvailable)
- Returns ranked list of strategies to try

---

### GAP #3: NO ALWAYS RESPOND GUARANTEE (CRITICAL)

**Current State**

```typescript
// useChat.ts (current fallback)
if (!finalResponse) {
  const fallbackContent = await createMinimalFallback();
}

// But: fallbackContent can STILL be empty if:
// - All providers timeout
// - All providers return empty
// - All fallback attempts fail
```

**Problem**

- Fallback exists but not guaranteed
- UI can appear frozen with empty message
- No explicit "return non-empty content always" rule

**Impact**

- Messages appear empty
- UX feels broken even though system tried
- No indication of failure to user

**Blocked By**

Need: `ResponseComposer` engine (Ring 2) that:
- Takes any ReasoningPlan result (success or failure)
- Produces non-empty ChatResult ALWAYS
- Includes:
  - Summary of what understood
  - Plan/steps user can take
  - Questions if clarification needed
  - Provenance (memory/skill/doc/fallback)

---

### GAP #4: NO NETWORK GUARD / PROOF (HIGH)

**Current State**

No instrumentation to prove "zero network attempts".

**Problem**

- Cannot verify offline mode actually prevents network
- No audit trail of what called what
- Provider implementations may have hidden network calls

**Impact**

- Offline mode trust is unverifiable
- Cannot pass compliance tests
- Users cannot verify their privacy

**Blocked By**

Need: `NetworkGuard` service (Ring 3) that:
- Intercepts all fetch/axios/tauri invoke calls in OFFLINE mode
- Logs blocked attempts with:
  - URL/endpoint targeted
  - Stack trace (who called)
  - Timestamp
- Throws if network call attempted in OFFLINE
- Produces `OfflineProof` object:
  ```typescript
  {
    offlineMode: true,
    networkAttempted: false,
    proof: "signature_OFFLINE_xyz",
  }
  ```

---

### GAP #5: NO ASSIMILATION SERVICE (HIGH)

**Current State**

```typescript
// If user opts-in to use OpenAI online:
// - Response is generated
// - Response is served to user
// - Response is LOST (no asset created)

// Meanwhile, next offline prompt
// - Cannot use previous learning
// - Repeats same provider cascade
```

**Problem**

- Every online call is wasted for offline learning
- No local asset generation
- No skill/corpus/test capture
- Violates "learning from online → local asset" rule

**Impact**

- Cannot pass Assimilation Gate
- Cognitive debt accumulates
- System never improves offline capabilities

**Blocked By**

Need: `AssimilationService` (Ring 3) that:
- Listens to successful online responses
- Captures:
  - Prompt + response
  - Context + metadata
  - Latency + quality score
- Produces 1+ `SkillArtifact`:
  - Generic skill (if general pattern)
  - Specialized skill (if specific domain)
  - OR corpus chunk for retrieval
- Validates with local tests
- Stores in SkillRegistry or KnowledgeBase
- Rejects if tests fail (anti-debt)

---

### GAP #6: NO ANTI-SILENCE WATCHDOG (HIGH)

**Current State**

```typescript
// UI_Chat.tsx
<ChatMessage content={message.content} />
// If content is empty:
// - Renders empty bubble
// - No indication of timeout/failure
// - Appears frozen
```

**Problem**

- No timeout watchdog
- Hidden failures appear as silence
- User has no idea what went wrong

**Impact**

- Frozen UI (worst UX)
- No indication to try offline/retry
- User assumes system is broken

**Blocked By**

Need: `UIWatchdog` (Ring 4) that:
- Sets timeout on every message send (5s default)
- If no response in X sec:
  - Shows spinner with message: "Searching offline..."
  - After 2X sec: Shows diagnostic + retry button
  - Never shows empty bubble
- Never renders empty content
- Forces fallback if timeout

---

### GAP #7: PROVIDER ROUTER NOT OFFLINE-FIRST (MEDIUM-HIGH)

**Current State**

```typescript
// ProviderRouter.ts
async routeRequest(message: string) {
  // Tries:
  // 1. Primary (ollama, openai, anthropic, gemini, local)
  // 2. Fallback
  // But NO offline-first enforcement
}
```

**Problem**

- Skills not explicitly tried first
- No offline parameter
- No StrategySelector to reorder

**Blocked By**

Gap #2 (StrategySelector) + Gap #1 (offlineMode parameter)

---

### GAP #8: NO SKILL-FIRST EXECUTION IN PROVIDER CASCADE (MEDIUM)

**Current State**

```rust
// src-tauri/src/chat_orchestrator.rs
let providers_to_try = vec![
  "ollama",
  "openai", 
  "anthropic",
  "gemini",
  "local",
];
// Skills not checked
```

**Problem**

- SkillRegistry exists but not consulted in provider cascade
- Skills (high confidence) bypassed for provider chain
- Wastes latency on providers when skill would work

**Impact in OFFLINE Mode**

- Skill for "what is my name?" → skipped
- Provider cascade exhausted → fallback
- Offline guarantee broken

**Blocked By**

Need: Modify `chat_orchestrator.rs` to:
1. Check SkillRegistry FIRST (skills Ring 2)
2. If skill matches + confidence > threshold:
   - Execute skill (offline, deterministic)
   - Return (no provider chain)
3. Else: Continue provider cascade as fallback

---

## DEPENDENCY GRAPH  (What blocks what)

```
┌─────────────────────────────────────────┐
│  TO ACHIEVE: Full OFFLINE Mode          │
└──────────────┬──────────────────────────┘
               │
     ┌─────────┴───────────┐
     │                     │
  GAP #1               GAP #2
  OFFLINE MODE         STRATEGY
  FLAG                 SELECTOR
     │                     │
     │    ┌────────────────┤
     │    │                │
  GAP #4             GAP #5
  NETWORK         ASSIMILATION
  GUARD           SERVICE
     │                │
     └───────┬────────┘
             │
         GAP #3
         ALWAYS
         RESPOND
             │
         GAP #6
         WATCHDOG
```

**Blocking Order (must do in sequence):**

1. **GAP #1** (offlineMode parameter) → enables enforcement
2. **GAP #2** (StrategySelector) → sets correct priority
3. **GAP #8** (Skill-first in cascade) → execute skills offline
4. **GAP #3** (Always Respond) → no empty responses
5. **GAP #4** (NetworkGuard) → proof
6. **GAP #5** (Assimilation) → learning from online
7. **GAP #6** (Watchdog) → UX safety

---

## RISK ANALYSIS

### If we don't fix GAP #1 (offlineMode)

- Test "Airplane Mode" fails (cannot disable network)
- Users cannot opt-in to offline
- No privacy guarantee

### If we don't fix GAP #2 (StrategySelector)

- Skills unnecessarily skipped
- Latency degraded
- Offline capability exists but unused

### If we don't fix GAP #3 (Always Respond)

- Test "No empty messages" fails
- UX broken (frozen bubbles)
- Users lose trust

### If we don't fix GAP #4 (NetworkGuard)

- Offline mode is unverifiable
- Cannot prove zero network attempts
- Feature is unusable for compliance

### If we don't fix GAP #5 (Assimilation)

- Online calls produce no offline assets
- Violates "local asset per API call" rule
- Cannot pass Assimilation Gate

---

## GATE_P0 VERDICT

**Status:** ❌ **FAIL (3 CRITICAL + 2 HIGH)**

Cannot proceed to Phase 1 until:
1. ✅ No silent responses possible (GAP #3 fixed)
2. ✅ offlineMode enforcement exists (GAP #1 fixed)
3. ✅ Skills checked before providers (GAP #8 fixed)

**Recommended Action:** Start Phase 1 patches simultaneously:
- Ring 2.5: StrategySelector engine
- Ring 2: ResponseComposer engine
- Ring 3: ProviderRouter mod (+ offlineMode param)
- Ring 3: NetworkGuard service
- Ring 3: AssimilationService
- Rust: Modify chat_orchestrator.rs (skill-first)

---

## REPAIR ROADMAP (Phase 1-6)

| Phase | Gap | Severity | Effort | Est. Time |
|-------|-----|----------|--------|-----------|
| P1 | GAP #1 | CRITICAL | 2h | Ring 1 types + ProviderRouter |
| P2 | GAP #2 | CRITICAL | 3h | StrategySelector engine |
| P2 | GAP #8 | MEDIUM | 2h | Rust orchestrator patch |
| P3 | GAP #3 | CRITICAL | 2h | ResponseComposer engine |
| P3 | GAP #4 | HIGH | 2h | NetworkGuard service |
| P3 | GAP #5 | HIGH | 3h | AssimilationService |
| P4 | GAP #6 | HIGH | 1h | UIWatchdog component |

**Total Estimated:** ~15 hours (distributed across phases)

---

## CONCLUSION

TITANE∞ cognitive core is **architecturally sound** (Ring 1-2 complete), but **integration gaps** prevent offline guarantee. All gaps are **fixable**, none are fundamental design flaws.

**GATE_P0 Verdict:** GO with tracked gaps (implement fixes in Phase 1-4).

---

**Report Authority:** SUPER PROMPT #2  
**Next Step:** Phase 1 — Ring 1 Types Completion  
**Status:** Ready to proceed
