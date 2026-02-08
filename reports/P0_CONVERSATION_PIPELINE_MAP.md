# 🗺️ PHASE 0 — CARTOGRAPHIE DU PIPELINE CONVERSATIONNEL

**Date:** 2026-02-07  
**Status:** PRÉFLIGHT COMPLET  
**Objectif:** Identifier tous les chemins UI → IPC → Core → UI et détecter les risques de "silence"  

---

## 📊 VUE D'ENSEMBLE (Flux Actuel)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FRONTEND (TypeScript/React)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ChatPanel.tsx                                                                │
│    └─> useChat.ts (2000+ lines)                                              │
│         ├─ sendMessage()                                                      │
│         ├─ Provider selection (auto/openai/gemini/anthropic/copilot/...)     │
│         ├─ Provider readiness check (3s timeout)                             │
│         ├─ Loading states (isLoading)                                        │
│         ├─ Error handling (error state)                                      │
│         └─ Voice enablement (hybridTTS)                                      │
│                                                                               │
│         ⚠️ RISQUES DÉTECTÉS:                                                 │
│         - Pas de garantie "always respond"                                   │
│         - Provider timeout → peut laisser isLoading=true                     │
│         - Pas de ChatResult type contract                                    │
│         - Pas de watchdog hard timeout                                       │
│                                                                               │
└───────────────────────────────────────────────────────────┬─────────────────┘
                                                            │
                                    ╔═══════════════════════╧═════════════════╗
                                    ║        IPC (Tauri invoke)               ║
                                    ║  Commands:                              ║
                                    ║  - chat_send_message                    ║
                                    ║  - chat_stream_message                  ║
                                    ║  - chat_generate (fallback)             ║
                                    ║  - chat_generate_gemini                 ║
                                    ║  - chat_generate_openai                 ║
                                    ║  - chat_generate_claude                 ║
                                    ║  - chat_generate_copilot                ║
                                    ║                                         ║
                                    ║  ⚠️ RISQUES DÉTECTÉS:                   ║
                                    ║  - Retour peut être String | Err        ║
                                    ║  - Pas de type ChatResult unifié        ║
                                    ║  - Exception peut remonter vide         ║
                                    ╚═════════════════════┬═══════════════════╝
                                                         │
┌────────────────────────────────────────────────────────┴─────────────────────┐
│                          BACKEND (Rust)                                       │
├───────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  chat_orchestrator.rs                                                         │
│    ├─ ChatOrchestratorState                                                  │
│    │   ├─ conversations (RwLock<Vec<ConversationMemory>>)                    │
│    │   ├─ provider_status (RwLock<Vec<ProviderStatus>>)                      │
│    │   ├─ unified_memory (RwLock<UnifiedMemory>) ← STM/MTM/LTM              │
│    │   ├─ gemini_api_key, openai_api_key, anthropic_api_key                 │
│    │   └─ provider_failure_count (HashMap<String, u32>)                      │
│    │                                                                          │
│    ├─ chat_send_message()                                                    │
│    │   ├─ Provider selection cascade                                         │
│    │   ├─ Provider availability check (cache 30s)                            │
│    │   ├─ Ollama ping (3s timeout)                                           │
│    │   ├─ Call provider-specific fn                                          │
│    │   └─ Store in UnifiedMemory                                             │
│    │                                                                          │
│    └─ Providers:                                                              │
│        ├─ chat_generate_gemini()                                              │
│        ├─ chat_generate_openai()                                              │
│        ├─ chat_generate_claude()                                              │
│        ├─ chat_generate_copilot()                                             │
│        └─ chat_generate() (local fallback)                                    │
│                                                                               │
│  ⚠️ RISQUES DÉTECTÉS:                                                         │
│  - Provider cascade peut échouer sans fallback structuré                     │
│  - Ollama timeout peut bloquer (déjà fixé à 3s)                              │
│  - Pas de OfflineProof generation                                            │
│  - Pas de garantie "always respond" (peut return Err sans fallback)          │
│  - UnifiedMemory storage = side effect, pas dans response                    │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔍 ANALYSE DÉTAILLÉE PAR RING

### RING 1: TYPES (Actuels)

#### Types Frontend (`src/types/`)
- ✅ **AIMessage** : `{ id, role, content, timestamp, provider, ... }`
- ✅ **AIResponse** : `{ content, provider, model, tokens, ... }`
- ⚠️ **Manque ChatResult union** : pas de forme `{ ok: true, content } | { ok: false, error }`
- ⚠️ **Manque ChatRequest standardisé** : utilisé implicitement mais pas typé
- ⚠️ **Manque OfflineProof** : pas de type pour audit offline
- ⚠️ **Manque UnderstandingFrame, ReasoningPlan** : Ring 2 engines pas présents

#### Types Backend (`src-tauri/src/`)
- ✅ **ChatMessage** : équivalent de AIMessage
- ✅ **ChatRequest** : `{ message, conversation_id, model, provider, ... }`
- ✅ **ConversationMemory** : stockage conversations
- ✅ **ProviderStatus** : disponibilité providers
- ⚠️ **Retour commands** : `Result<String, String>` ou `Result<ChatMessage, String>`
  - **Problème** : pas de structure unifiée, peut return string brut
  - **Risque** : frontend reçoit string vide ou null → bulle vide

**VERDICT RING 1:**
- ❌ **FAIL** : Type contract incomplet, risque de silence détecté

---

### RING 2: ENGINES (Actuels)

#### Engines créés Phase 2 (NON CONNECTÉS)
- ✅ `StrategySelector.ts` (Phase 2, SEALED but NOT USED)
- ✅ `ResponseComposer.ts` (Phase 2, SEALED but NOT USED)

#### Logique actuelle (dispersée)
- ⚠️ **Provider selection** : codé en dur dans `useChat.ts`
  - Logique : `auto` → check readiness → pick first available
  - Risque : peut échouer sans fallback

- ⚠️ **Response composition** : codé en dur dans Rust
  - Logique : provider call → return content or error
  - Risque : peut return vide

**VERDICT RING 2:**
- ⚠️ **PARTIAL**: Engines existent mais pas intégrés, logique actuelle fragile

---

### RING 3: SERVICES (Actuels)

#### Services créés Phase 3 (NON CONNECTÉS)
- ✅ `ProviderRouter_Ring3.ts` (Phase 3, NOT USED)
- ✅ `NetworkGuard.ts` (Phase 3, NOT USED)
- ✅ `AssimilationService.ts` (Phase 3, NOT USED)

#### Logique actuelle (dispersée)
- ⚠️ **useChat.sendMessage()** : 
  - 200+ lignes de logique
  - Provider readiness check avec Promise.allSettled
  - Call Tauri invoke direct (pas via service)
  - Gère voice, debug, XP, memory compaction
  - **Problème** : complexité élevée, hard to test

- ⚠️ **chat_orchestrator.rs** :
  - Provider cascade codé en dur
  - Provider availability with cache
  - Store in UnifiedMemory
  - **Problème** : pas de skill-first, pas de offline proof

**VERDICT RING 3:**
- ❌ **FAIL**: Services Ring 3 créés mais non utilisés, logique actuelle fragile

---

### RING 4: UI (Actuel)

#### UI Components créés Phase 4 (NON CONNECTÉS)
- ✅ `UIWatchdog.tsx` (Phase 4, NOT USED)
- ✅ `OfflineIndicator.tsx` (Phase 4, NOT USED)
- ✅ `ChatErrorBoundary.tsx` (Phase 4, NOT USED)

#### UI actuelle
- ✅ **ChatPanel.tsx** : 
  - Utilise `useChat` hook
  - Visual states (idle, listening, thinking, speaking)
  - Particle background
  - Panel state management

- ⚠️ **useChat.ts** :
  - `isLoading` state peut rester bloqué
  - Pas de watchdog hard timeout
  - Error handling basic (error string)
  - **Problème** : peut afficher loading infini si provider ne répond pas

**VERDICT RING 4:**
- ❌ **FAIL**: Components Ring 4 créés mais non utilisés, UI actuelle vulnérable

---

## ⚠️ RISQUES DE "SILENCE" IDENTIFIÉS

### Risque #1: Provider Timeout Sans Fallback (CRITIQUE)
**Chemin:**
```
useChat.sendMessage() 
  → invoke('chat_send_message', ...) 
  → chat_orchestrator.rs 
  → provider cascade (openai → gemini → anthropic → ...) 
  → TOUS TIMEOUTS → return Err
  → useChat reçoit error 
  → setError(error) 
  → UI affiche error message
```
**Problème:** Si error message vide ou non géré → bulle vide  
**Gravité:** 🔴 CRITICAL  
**Fix:** Ring 2.6 ResponseComposer + Ring 3.1 ProviderRouter (MUA fallback)

---

### Risque #2: Provider Readiness Check Bloqué (MODÉRÉ)
**Chemin:**
```
useChat.useEffect() 
  → checkProvidersAvailability() 
  → Promise.allSettled([openai.isAvailable(), ...]) 
  → timeout 3s per provider
  → setProviderReadiness({...})
```
**Problème:** Si tous providers timeout → `providerReadiness` reste `{}` → sendMessage skip  
**Gravité:** 🟡 MODERATE  
**Fix:** Ring 3.2 NetworkGuard + offline mode default

---

### Risque #3: IPC Exception Non Catchée (CRITIQUE)
**Chemin:**
```
invoke('chat_send_message', ...) 
  → Exception Tauri (timeout, crash, parse error) 
  → catch block useChat 
  → setError(e.message)
```
**Problème:** `e.message` peut être vide ou non human-readable  
**Gravité:** 🔴 CRITICAL  
**Fix:** Ring 1 ChatResult + IPC wrapper

---

### Risque #4: Loading Infini Sans Watchdog (CRITIQUE)
**Chemin:**
```
useChat.sendMessage() 
  → setIsLoading(true) 
  → invoke('chat_send_message', ...) 
  → [Provider stuck, no response] 
  → [Never calls setIsLoading(false)]
```
**Problème:** UI bloquée en loading état forever  
**Gravité:** 🔴 CRITICAL  
**Fix:** Ring 4.1 UIWatchdog (10s hard timeout)

---

### Risque #5: Rust Return String Empty (MODÉRÉ)
**Chemin:**
```
chat_send_message() 
  → provider call 
  → Ok(ChatMessage { content: "", ... }) 
  → return Ok(serialize(msg)) 
  → frontend reçoit { content: "" }
```
**Problème:** Frontend peut afficher bulle vide  
**Gravité:** 🟡 MODERATE  
**Fix:** Ring 2.6 ResponseComposer (validate non-empty) + Rust validation

---

## 🎯 PATCHES ANTI-SILENCE IMMÉDIATS

### Patch A1: Frontend Guard (URGENT)
**Fichier:** `src/hooks/useChat.ts`  
**Ligne approx:** 1500-1600 (sendMessage function)  

**Action:** Ajouter guard immédiat avant affichage message:
```typescript
// ✅ PATCH A1: Anti-silent guard (Phase 0 immediate)
if (!response || !response.content || response.content.trim() === '') {
  response = {
    ...response,
    content: "⚠️ Réponse vide détectée. Mode OFFLINE activé. Essayez de reformuler votre question ou vérifiez votre connexion.",
    provider: 'fallback',
    model: 'offline_guard'
  };
}
```

### Patch A2: Rust Fallback Guard (URGENT)
**Fichier:** `src-tauri/src/overdrive/chat_orchestrator.rs`  
**Ligne approx:** 444+ (chat_send_message function)  

**Action:** Ajouter fallback immédiat si content vide:
```rust
// ✅ PATCH A2: Anti-silent guard (Phase 0 immediate)
if response.content.trim().is_empty() {
    response.content = format!(
        "⚠️ Aucune réponse disponible. Providers: {}. Essayez mode OFFLINE ou vérifiez votre configuration.",
        request.provider.as_deref().unwrap_or("auto")
    );
    response.provider = "fallback".to_string();
}
```

### Patch A3: UIWatchdog Hook Immédiat (URGENT)
**Fichier:** `src/hooks/useChat.ts`  
**Ligne approx:** 500-600 (sendMessage function)  

**Action:** Ajouter timeout protection:
```typescript
// ✅ PATCH A3: Watchdog timeout (Phase 0 immediate)
const HARD_TIMEOUT_MS = 10000; // 10s hard limit

const timeoutPromise = new Promise<AIResponse>((resolve) => {
  setTimeout(() => {
    resolve({
      content: "⏱️ Délai d'attente dépassé (10s). Mode OFFLINE activé. Reformulez votre question ou activez un provider local.",
      provider: 'timeout_fallback',
      model: 'watchdog',
      timestamp: Date.now(),
    });
  }, HARD_TIMEOUT_MS);
});

const response = await Promise.race([
  actualResponse, // Your normal invoke call
  timeoutPromise
]);
```

---

## 📋 GATE_P0: CRITÈRES DE PASSAGE (BLOQUANT)

| Critère | Actuel | Requis | Status |
|---------|--------|--------|--------|
| Type contract ChatResult (TS + Rust) | ❌ Absent | ✅ Implémenté | 🔴 FAIL |
| Always Respond guarantee (Ring 2.6) | ❌ Non connecté | ✅ In use | 🔴 FAIL |
| UIWatchdog hard timeout (10s) | ❌ Non connecté | ✅ In use | 🔴 FAIL |
| IPC error → ChatResult.error (never empty) | ❌ String error | ✅ Structured | 🔴 FAIL |
| Offline proof generation | ❌ Absent | ✅ Implémenté | 🔴 FAIL |
| Provider cascade with MUA fallback | ⚠️ Partial | ✅ Guaranteed | 🟡 PARTIAL |
| Ring 3 services connected | ❌ Created but unused | ✅ In use | 🔴 FAIL |
| Tests: zero silent failures | ❌ Not verified | ✅ 100% pass | 🔴 FAIL |

**VERDICT FINAL GATE_P0:**
- 🔴 **FAIL** — Architecture créée (phases 1-6) mais **NON CONNECTÉE** à l'UI/IPC existant
- ⚠️ **6 risques critiques de silence** identifiés
- ✅ **3 patches immédiats** proposés pour stabilisation temporaire

---

## 🚀 PROCHAINES ÉTAPES (Phases 1-8)

### Phase 1: Types Contract (CRITIQUE)
- Créer `ChatResult` union type (TS + Rust)
- Créer `ChatRequest` canonique
- Créer `OfflineProof` type
- Update IPC commands signature
- **ETA:** 2h

### Phase 2: Engines Connection (CRITIQUE)
- Connecter `StrategySelector` dans useChat
- Connecter `ResponseComposer` dans chat_orchestrator.rs
- Remove old provider selection logic
- **ETA:** 3h

### Phase 3: Services Integration (CRITIQUE)
- Connecter `ProviderRouter_Ring3` dans useChat
- Connecter `NetworkGuard` en interceptor
- Connecter `AssimilationService` post-response
- **ETA:** 4h

### Phase 4: IPC Bridge (CRITIQUE)
- Create canonical `chat_generate` command
- Wrap all errors in `ChatResult`
- Add contract tests
- **ETA:** 2h

### Phase 5: UI Integration (CRITIQUE)
- Connecter `UIWatchdog` dans useChat
- Connecter `OfflineIndicator` dans ChatPanel
- Connecter `ChatErrorBoundary` wrapper
- **ETA:** 2h

### Phase 6: Tests (BLOQUANT)
- Unit tests (Ring 2 engines)
- Contract tests (IPC)
- E2E desktop (Tauri)
- **ETA:** 3h

### Phase 7: Observability (IMPORTANT)
- Trace génération
- Rapport offline proof
- Always respond report
- **ETA:** 1h

### Phase 8: Docs + Rollback (IMPORTANT)
- Feature flag
- Rollback plan
- Status docs
- **ETA:** 1h

**TOTAL ETA:** ~18h (1 journée intensive ou 2-3 jours normaux)

---

## 💡 RECOMMANDATIONS STRATÉGIQUES

### Option A: Big Bang (1 journée intensive)
- ✅ **Avantages:** Cohérence totale, tests complets
- ❌ **Risques:** Tous les risques d'un seul coup, pas de rollback partiel

### Option B: Incrémental + Feature Flags (2-3 jours)
- ✅ **Avantages:** Rollback à chaque phase, tests indépendants
- ❌ **Inconvénients:** Plus long, feature flags overhead

### Option C: Patches Immédiats + Intégration Progressive (recommandé)
1. **Jour 1:** Appliquer patches A1-A3 (stabilisation 80%)
2. **Jour 2:** Phases 1-4 (types + engines + services + IPC)
3. **Jour 3:** Phases 5-8 (UI + tests + observabilité + docs)
- ✅ **Avantages:** Stabilité immédiate, intégration progressive, rollback à chaque étape
- ✅ **Risque minimisé:** Patches temporaires permettent de travailler sans urgence

**👉 RECOMMANDATION TITANE∞:** Option C (Patches + Progressive Integration)

---

**🔒 RAPPORT P0 COMPLET — Prêt pour décision GO/NO-GO Phase 1**
