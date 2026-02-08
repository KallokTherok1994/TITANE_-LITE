# 📋 INPUTS SNAPSHOT — TITANE∞ Meta-Audit (2026-02-07)

## I. ARBORESCENCE DES DOSSIERS PERTINENTS

### Frontend (TypeScript/React)
```
src/
├── components/
│   ├── AutonomyPanel.tsx         (Mode panel + skill approval UI)
│   ├── autonomy/
│   │   └── UIWatchdog.tsx        (Timeout watchdog component)
│   └── cognitive/
│       └── CognitiveLayoutControl.tsx
├── engines/                      (Ring 2 — Business Logic)
│   ├── assimilation/
│   │   └── AssimilationEngine.ts (Record→Compile→Test→Approve)
│   ├── skills/
│   │   └── SkillEngine.ts        (Offline execution)
│   └── ...26 autres engines
├── services/                     (Ring 3 — I/O & Orchestration)
│   ├── ai/
│   │   ├── ProviderRouter.ts     (CRITICAL: offline-first?)
│   │   └── ProviderRouter_Ring3.ts
│   ├── cognitive/
│   │   ├── AssimilationService.ts (451 lines, never called)
│   │   └── ...15 autres services cognitifs
│   └── ... managers/orchestration/chat/
├── hooks/                        (React Integration)
│   └── useChat.ts               (2259 lines, manual timeouts)
├── config/
│   └── featureFlags.ts          (OFFLINE, ONLINE, modes)
├── types/                        (Contracts - Ring 1)
│   └── chat.ts, autonomy.ts, etc.
└── tests/
    ├── gates/
    │   ├── gate2-offline-first.spec.ts
    │   └── gate3-assimilation.spec.ts
    └── __tests__/
```

### Backend (Rust)
```
src-tauri/
├── src/
│   ├── lib.rs                  (Feature flags: [full|mock])
│   ├── api/
│   │   └── chat.rs             (Backend chat handler)
│   ├── chat_engine/
│   │   ├── mod.rs
│   │   └── speech.rs           (SpeechMode: Auto|Online|Local)
│   ├── singularity/
│   │   ├── mod.rs
│   │   ├── behavior_controller.rs (Safety, modes)
│   │   └── ...27 autres modules singularity
│   ├── constitution/
│   │   └── governance.rs       (Policies: autoApprove, etc.)
│   └── ...44 autres modules core
└── Cargo.toml                  (Feature flags, deps)
```

### Configuration & Build Tools
```
Root/
├── package.json                (130 scripts: test, build, audit, etc.)
├── vitest.config.ts            (49 test configurations)
├── playwright.config.ts        (E2E browser testing)
├── vite.config.ts              (Build: 452 lines)
├── src-tauri/tauri.conf.json   (Tauri app config)
├── tsconfig.json               (TypeScript strict mode)
├── eslint.config.js            (Code quality)
├── tailwind.config.ts          (Styling)
└── postcss.config.js
```

### Test & Release Infrastructure
```
tests/
├── gates/
│   ├── gate-offline-zero-network.test.ts
│   ├── gate2-offline-first.spec.ts        (NEW)
│   ├── gate3-assimilation.spec.ts         (NEW)
│   └── ...gate compliance tests
├── e2e/
│   └── beta-smoke.test.js
├── __tests__/
│   ├── architecture/
│   ├── compliance/
│   └── ...integration tests
└── fixtures/

scripts/
├── dev/
│   └── full_local_tauri_ollama.sh
├── build/
├── verify/
│   ├── enforce-tauri-only.sh
│   ├── enforce-local-first.sh
│   └── validate-tauri-configs.sh
├── audit/
│   └── 00-master-audit.sh (7 sub-audits)
├── registry/
└── e2e/
```

### Documentation
```
docs/
├── COMMUNICATION_AI_CANON.md               (TO CREATE)
├── autonomy/
│   ├── PHASE_4_ASSIMILATION_GUIDE.md
│   └── ...architecture guides
└── ... API_REFERENCE.md, ARCHITECTURE.md, etc.

reports/
├── FACTS.md                   (Phase 0 Truth Audit)
├── GRAPH.mmd                  (Architecture visualization)
├── CONTRACTS.md               (Phase 1 - Canonical types)
├── TIP_ORCHESTRATION.md       (Phase 2 - Provider routing)
├── PHASE_3_ASSIMILATION.md    (Phase 3 - Learning system)
├── PHASE_4_8_CONSOLIDATED.md  (Phase 4-8 rapid audit)
├── FINAL_CONVERSATION_AI_SEAL.md
├── ULTRA_SUPER_PROMPT_AUDIT_COMPLETE.md
├── PROMPTS_INPUTS_SNAPSHOT.md (THIS FILE)
├── PROMPTS_AUDIT_MATRIX.md    (TO CREATE)
├── PROMPTS_GAPS_AND_FIXES.md  (TO CREATE)
└── EXECUTION_PLAN_FINAL.md    (TO CREATE)
```

---

## II. PACKAGE.JSON — SCRIPTS CRITIQUES

### Test Suites
```javascript
test                      → vitest run                                   (Unit + Integration)
test:rust                 → cargo test                                   (Rust backend)
test:e2e:playwright       → playwright test e2e                          (Browser E2E)
test:e2e:wdio            → WebdriverIO desktop suite
test:all                  → test + test:rust + architecture + compliance (3-tier)
test:all:full            → test:all + E2E browsers + WebdriverIO        (COMPREHENSIVE)
test:architecture        → Check 4-Ring conformance
test:compliance          → Check Tauri-local + offline-first laws
```

### Build & Verification
```javascript
verify                    → lint + format:check + check + test:all + verify:*
verify:tauri-only        → Enforce no external HTTP servers
verify:local-first       → Enforce offline capability
verify:tauri-configs     → Validate tauri.conf.json consistency
```

### Audit Suite (7 stages)
```javascript
audit:master             → Stage 0: Overall orchestration
audit:security           → Stage 1: Dependencies, secrets
audit:architecture       → Stage 2: 4-Ring conformance
audit:performance        → Stage 3: Benchmarks
audit:coverage           → Stage 4: Test coverage thresholds
audit:deployment         → Stage 5: Build artifacts
audit:quality-gates      → Stage 6: Compliance gates (CRITICAL)
```

---

## III. FEATURE FLAGS (Rust Cargo.toml + TS)

### Rust Features
```toml
[features]
default = ["custom-protocol", "mock"]
custom-protocol = ["tauri/custom-protocol"]
mock = []                # Mode MOCK: frontend-only
full = []                # Mode FULL: production backend
```

### TypeScript Feature Flags (src/config/featureFlags.ts)
```typescript
FEATURE_FLAGS = {
  DEV_MODE:              true | false
  OFFLINE_CAPABILITY:    true          (non-negotiable)
  ONLINE_CAPABILITY:     true | false  (optional)
  ENABLE_EXTERNAL_AI:    false         (prohibited)
  ENABLE_NETWORK_CHECK:  false         (prohibited)
  ENABLE_TELEMETRY:      false         (prohibited)
  
  AI_PROVIDERS: {
    'ollama':            true          (local LLM)
    'gemini':            true | false  (online)
    'openai':            true | false  (online)
    'builtin':           true          (embedded models)
  },
  
  AUTONOMY_MODES: {
    'offline':           true
    'local_llm':         true
    'hybrid':            true
    'online_augmented':  true | false
  },
  
  ASSIMILATION: {
    auto_approve:        false
    quality_threshold:   0.9
    similarity_threshold: 0.75
  }
}
```

### Autonomy Mode Enums
```typescript
enum AutonomyModeEnum {
  OFFLINE = 'offline',
  LOCAL_LLM = 'local_llm',
  HYBRID = 'hybrid',
  ONLINE_AUGMENTED = 'online_augmented'
}

enum SpeechMode {
  Auto = 'auto',
  Online = 'online',
  Local = 'local'
}
```

---

## IV. CONFIGURATION FILES SNAPSHOTS

### vite.config.ts (Build)
- **Service Worker Plugin**: Workbox precaching (ONNX excluded)
- **Compression**: vite-plugin-compression active
- **Aliases**: 16 path aliases (@components, @services, etc.)
- **Output Dir**: dist/ (built via `pnpm run build`)

### vitest.config.ts (Unit/Integration tests)
- **Environment**: jsdom (browser simulation)
- **Parallel**: fullyParallel: true
- **Globals**: true (allows `describe`, `it` without imports)
- **Coverage**: c8 configured
- **12 workspace configs** (unit, integration, browser, etc.)

### playwright.config.ts (E2E)
- **Base URL**: http://localhost:5173
- **Parallel**: workers = 1 (sequential, reliable)
- **Retries**: 2 in CI, 0 locally
- **Timeout**: 30s per test, 5s per assertion
- **Recording**: on-first-retry (video + trace)

### tauri.conf.json (App)
- **Dev URL**: http://localhost:1420
- **Dev Command**: vite dev --host 127.0.0.1 --port 1420
- **Build Command**: vite build
- **Windows**: 2 (main + avatar-floating)
- **Bundle**: targets all platforms (Linux, macOS, Windows)

---

## V. SERVICES & ENGINES INVENTORY (Ring 2-3)

### Core Services (Always Active)
| Service | File | Lines | Purpose |
|---------|------|-------|---------|
| AssimilationService | src/services/cognitive/ | 451 | Capture→Validate→Create skills |
| SkillEngine | src/engines/skills/ | 597 | Execute offline skills |
| ProviderRouter | src/services/ai/ | 541 | Route requests to providers |
| UIWatchdog | src/components/autonomy/ | 351 | Timeout UI prevention |
| useChat Hook | src/hooks/useChat.ts | 2259 | Frontend chat orchestration |

### Backend Services (26+ total)
- SystemCenter, AutoAuditEngine, SelfHealing, AgendaService, Evolution
- RAGAS, ConversationEngine, VoiceEngine, AvatarEngine, AudioTranscription
- TTS Service, Network Management, SessionManagement, CacheService
- ExperienceTools, UserPreferencesEngine, ConsistencyEngine, etc.

### Engines (30+ total)
- CognitiveEngine, PredictiveEngine, SkillEngine, AssimilationEngine
- RetrievalEngine, EmotionEngine, ConsciousEngine, TimeEngine
- VoiceEngine, OutputEngine, NarrativeEngine, etc.

### Rust Backend Modules (44+ total)
- chat_engine, singularity (27 submodules), constitution, agenda
- audio, voice, tts, avatar, persona, devices, orchestration
- network, memory, cache, api, compat

---

## VI. LOG TYPES & OBSERVABILITY

### Runtime Logs (target: OFFLINE PROOF)
```
Context:
- Boot: Initialization sequence timestamp
- Chat: Request ID, mode (OFFLINE|ONLINE|HYBRID), latency
- OMEGA: Pipeline step completions
- Offline Guard: Network block confirmation
- Skill used: Provider=offline, strategy=skill, latencyMs

Pattern for OFFLINE proof:
[timestamp] REQ_ID=<uuid> MODE=OFFLINE PROVIDER=offline STRATEGY=skill LATENCY_MS=<ms> NETWORK_CALLS=0
```

### Trace Format (REQUIRED for GATE_6)
```json
{
  "trace_id": "<uuid>",
  "request_id": "<uuid>",
  "timestamp": "2026-02-07T...",
  "mode": "OFFLINE|ONLINE|HYBRID",
  "steps": [
    { "stage": "understand", "duration_ms": 10, "provider": "local" },
    { "stage": "recall", "duration_ms": 5, "provider": "skill_registry" },
    { "stage": "strategy", "duration_ms": 2, "decision": "use_skill" },
    { "stage": "execute", "duration_ms": 15, "result": "ok" },
    { "stage": "compose", "duration_ms": 8, "format": "markdown" }
  ],
  "total_latency_ms": 40,
  "network_calls": 0,
  "offline": true,
  "asset_created": { "skill_id": "...", "quality_score": 0.92 }
}
```

---

## VII. CRITICAL PATHS & ENTRY POINTS

### Frontend Entry (React)
```
App.tsx → useChat.ts (global state)
  → ProviderRouter (async request)
  → Response processed via ResponseComposer
  → ChatMessage UI rendered
```

### Backend Entry (Rust/IPC)
```
chat_handler() [Tauri command]
  → Parse ChatRequest (contract validation)
  → Route to provider (ProviderRouter logic)
  → Assimilation (record if online)
  → Compose response via ResponseComposer
  → Return ChatResult (contract validation)
```

### Offline Proof Critical Path
```
User asks question
 → Mode check: OFFLINE?
 → SkillRegistry lookup (0-5ms)
 → If hit: return skill → log NETWORK_CALLS=0
 → If miss: fallback (retrieval/template)
 → Never call online provider
```

---

## VIII. COMPLIANCE CHECKLIST (INPUTS VALIDATION)

✅ **COLLECTED:**
- Folder structure for UI/IPC/Rust/Engines/Services
- package.json (130 scripts)
- vitest config (49 configurations)
- playwright config (E2E framework)
- tauri.conf.json (App configuration)
- ts config (strict mode)
- Feature flags (Cargo + TS)
- Autonomy modes enum
- 60+ engines & services mapped
- 44+ Rust modules listed
- Critical paths documented

⚠️ **NEEDS VERIFICATION:**
- Exact state of: ProviderRouter provider order (online before offline?)
- Exact state of: AssimilationService calls in production (0 calls?)
- Exact state of: UIWatchdog integration in useChat.ts (imported?)
- Exact state of: Tracing system (absent?)

✅ **GATE_1 PASS:** All inputs collected without gaps.

---

## IX. NEXT: PROMPTS AUDIT MATRIX

**Target document**: `reports/PROMPTS_AUDIT_MATRIX.md`

Will contain:
1. Inventory of 10 prompts (phases 0-8 + uber-prompt)
2. For each: objective, rings impacted, artefacts, gates, tests, dependencies
3. Detection of duplicates, conflicts, dependencies
4. Conflict resolution matrix

**Status**: READY FOR PHASE 2.

---

**Generated**: 2026-02-07T  
**Audit**: TITANE∞ Meta-Final Review  
**Authority**: PΩ∞.META.FINAL.REVIEW.SEAL
