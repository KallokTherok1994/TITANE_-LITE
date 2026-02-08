# PHASE 0 — UI SITEMAP CANONIQUE (Inventaire Réel)

**Date**: 2026-02-08  
**Version**: TITANE∞ v15 (PRESEAL)  
**Scope**: Audit UI/AI complet, "No Silence", Offline-First, Preseal preparation

---

## 📍 SITEMAP COMPLET

### Routes Découvertes (src/router.tsx)

| # | Route | Page/Component | Responsabilité | Dépendances | State OFFLINE |
|---|-------|---------------|-----------------|-------------|---------------|
| 1 | `/` | DashboardPage | Vue d'ensemble, moniteur système | Store, AIRouter | ✓ Readonly |
| 2 | `/chat` | Chat | Conversation + IA directe | AIRouter, UIWatchdog, TTS, Memory | ✓ Full MUA |
| 3 | `/stats` | Stats | Métriques, historique, trends | Store, Memory, Analytics | ✓ Readonly |
| 4 | `/sentinel` | Sentinel | Monitoring, alerts, logging | Log service, Store | ✓ Readonly |
| 5 | `/watchdog` | Watchdog | Timeout prevention, UI health | UIWatchdog, Traces | ✓ Readonly |
| 6 | `/selfheal` | SelfHeal | Auto-repair, diagnostics | DiagnosticsService, FileSystem | ⚠ Partial |
| 7 | `/adaptive` | AdaptiveEngine | Stratégies d'apprentissage | AIRouter, SkillRegistry | ✓ Offline skills |
| 8 | `/memory` | Memory | Gestion mémoire/retrieval | MemoryService, Storage | ✓ Full |
| 9 | `/settings` | Settings | Configuration, preferences | ConfigService, Store | ✓ Full |
| 10 | `/devtools` | DevTools | Debug, logs, inspection | All services | ⚠ Limited |
| 11 | `/cloud` | CloudCenter | Cloud sync (optionnel) | CloudAPI | ✗ Offline |
| 12 | `/agenda` | AgendaPage | Planning, tâches | Store, Calendar | ✓ Full |
| 13 | `/design-system` | DesignSystemShowcase | UI components showcase | None (isolated) | ✓ Full |

---

## 🏗️ ARCHITECTURE RINGS

### Ring 1 (Core Contracts)
- `ChatRequest / ChatResult` (IPC)
- `SkillArtifact` (SQL)
- Rust contracts (src-tauri/src/api/contracts.rs)

### Ring 2.5 (Orchestration)
- `AIRouter` (main façade)
- `ProviderRouter` (Law #2: offline-first)
- `StrategySelector` (TIP order)
- `UIWatchdog` (timeout prevention)

### Ring 3 (Services)
- `TracingService` (audit trail)
- `AssimilationService` (learning)
- `SkillRegistry` (offline skills)
- `MemoryService` (retrieval)
- `ResponseComposer` (always respond)

### Ring 4 (UI Components)
- Sidebar, Header, Layout
- ChatInput, ChatBubble, ActionResult
- ConfigPanel, DevTools, etc.

---

## 📋 CRITÈRES "PASS UI×AI COMPLETE"

### ✅ No Silent Failure (GATE_1)
- [ ] **Chat**: Send message → always gets response (or visible error)
- [ ] **Dashboard**: Load → displays metrics or "Waiting for data"
- [ ] **Memory**: Search → shows results or "No matches (offline)"
- [ ] **Stats**: Render → shows data or "Loading..." → data or "No data"
- [ ] **Adaptive**: Strategy selection → log visible or error visible
- [ ] **Settings**: Save config → toast "Saved" or "Error: reason"
- [ ] **All pages**: Error in render → ErrorBoundary catches + displays

### ✅ Offline Mode (GATE_5)
- [ ] **OFFLINE=true**: AI Chat still works (MUA/Skills)
- [ ] **OFFLINE=true**: Dashboard shows "Offline" badge clearly
- [ ] **OFFLINE=true**: CloudCenter disabled (or "Offline" message)
- [ ] **OFFLINE=true**: No network calls (verify logs)

### ✅ AI Connectedness (GATE_2)
- [ ] **Chat** → AIRouter → TracingService → Response
- [ ] **Adaptive** → AIRouter → SkillRegistry → Trace
- [ ] **Dashboard** → AIRouter stats displayed
- [ ] **Memory** → MemoryService + AIRouter integration
- [ ] 0 direct `fetch()` from UI to external provider

### ✅ E2E Desktop (GATE_7)
- [ ] Boot → Load all pages
- [ ] 3 chat prompts → all get responses
- [ ] 3 consecutive runs → same results → **no flakiness**

---

## 🔴 PAGES À AUDITER EN PRIORITÉ

1. **Chat** (critère #1: always respond)
2. **Dashboard** (critère #2: offline badge)
3. **Memory** (critère #3: retrieval + AI)
4. **Adaptive** (critère #4: strategy selection + trace)
5. **Settings** (critère #5: config save without network)

---

## 📊 STATUS INITIAL

| Page | Route | Audit | No-Silence | Offline | AI-Connected | E2E |
|------|-------|-------|-----------|---------|--------------|-----|
| Dashboard | `/` | ⏳ TODO | ❓ TBD | ❓ TBD | ❓ TBD | ❓ TBD |
| Chat | `/chat` | ⏳ TODO | ❓ TBD | ❓ TBD | ❓ TBD | ❓ TBD |
| Stats | `/stats` | ⏳ TODO | ❓ TBD | ❓ TBD | ❓ TBD | ❓ TBD |
| Sentinel | `/sentinel` | ⏳ TODO | ❓ TBD | ❓ TBD | ❓ TBD | ❓ TBD |
| Watchdog | `/watchdog` | ⏳ TODO | ❓ TBD | ❓ TBD | ❓ TBD | ❓ TBD |
| SelfHeal | `/selfheal` | ⏳ TODO | ❓ TBD | ❓ TBD | ❓ TBD | ❓ TBD |
| Adaptive | `/adaptive` | ⏳ TODO | ❓ TBD | ❓ TBD | ❓ TBD | ❓ TBD |
| Memory | `/memory` | ⏳ TODO | ❓ TBD | ❓ TBD | ❓ TBD | ❓ TBD |
| Settings | `/settings` | ⏳ TODO | ❓ TBD | ❓ TBD | ❓ TBD | ❓ TBD |
| DevTools | `/devtools` | ⏳ TODO | ❓ TBD | ❓ TBD | ❓ TBD | ❓ TBD |
| CloudCenter | `/cloud` | ⏳ TODO | ❓ TBD | ❓ TBD | ⚠ Optional | ❓ TBD |
| Agenda | `/agenda` | ⏳ TODO | ❓ TBD | ❓ TBD | ❓ TBD | ❓ TBD |
| DesignSystem | `/design-system` | ⏳ TODO | ✅ N/A | ✅ N/A | ✅ N/A | ✅ N/A |

---

## 🎯 NEXT STEPS

1. **PHASE 1**: Audit each critical page for "No Silence"
2. **PHASE 2**: Check AI façade usage (0 direct provider calls)
3. **PHASE 3**: Chat regression test (20 prompts)
4. **PHASE 4**: Offline mode verification (global freeze test)
5. **PHASE 5**: E2E full tour (3 runs)
6. **PHASE 6**: Generate preseal reports + checklist

---

**File**: `reports/UI_SITEMAP.md`  
**Status**: DISCOVERY COMPLETE → Starting PHASE 1 (No Silence Audit)
