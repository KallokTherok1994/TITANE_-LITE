# PHASE 1 — CONTRATS CANONIQUES ANTI-SILENCE

**Date**: 2026-02-07  
**Version**: v27.4.1  
**Phase**: 1/8 (Post GATE_0 PASS)  
**Objectif**: Définir et valider contrats uniques TS↔Tauri garantissant "Always Respond"

---

## 📊 ÉTAT DES LIEUX — Contrats Actuels

### FRONTEND TypeScript — 2 Systèmes Coexistants

#### Système 1: `src/types/autonomy.ts` (451 lignes)

**Contrat Success** :
```typescript
export interface ChatResult {
  ok: true;
  content: string; // GUARANTEED non-empty
  metadata: ChatResultMetadata;
}

export interface ChatResultMetadata {
  autonomyMode: AutonomyMode; // OFFLINE | LOCAL_LLM | HYBRID | ONLINE_AUGMENTED
  providerUsed: 'ollama' | 'gemini' | 'openai' | 'anthropic' | 'offline' | 'skills' | 'template';
  offlineProof: OfflineProof; // Network attempted proof
  generationTimeMs: number;
  sources?: string[];
  confidenceScore?: number;
  traceId: string;
}
```

**Contrat Error** :
```typescript
export interface ChatErrorResult {
  ok: false;
  error: {
    code: ChatErrorCode;
    message: string; // Internal/technical
  };
  userMessage: string; // User-friendly message (ALWAYS displayable)
  suggestedAction?: string; // "Retry", "Check network", "Enable Ollama"
  metadata: ChatResultMetadata;
}

export type ChatResponse = ChatResult | ChatErrorResult;
```

**AutonomyMode** :
```typescript
export enum AutonomyMode {
  OFFLINE = 'OFFLINE', // Zero network, zero external providers
  LOCAL_LLM = 'LOCAL_LLM', // Ollama/llama.cpp, fallback to OFFLINE
  HYBRID = 'HYBRID', // Try LOCAL_LLM → Online → OFFLINE
  ONLINE_AUGMENTED = 'ONLINE_AUGMENTED', // Prefer online, fallback to LOCAL_LLM+OFFLINE
}
```

**OfflineProof** :
```typescript
export interface OfflineProof {
  networkAttempted: boolean; // Was network used?
  networkReason?: string; // "fallback from provider timeout"
  decisionPath: string[]; // Breadcrumb trace
  generatedAt: number;
  signature: string; // Hash for auditability
}
```

**Usages Confirmés** :
- ✅ `AutonomousChatEngine` (src/engines/autonomous) → retourne `ChatResult`
- ✅ `OfflineFallbackEngine` (src/engines/offline) → retourne `ChatResult`
- ✅ `ResponseComposer` (src/engines/cognitive) → garantit `ChatResult` non-vide
- ✅ `ProviderRouter_Ring3` (src/services/ai) → route vers `ChatResult`
- ✅ `UIWatchdog` (src/components/autonomy) → surveille `ChatRequest` → `ChatResult`

---

#### Système 2: `src/types/conversationIntelligence.ts` (333 lignes)

**Contrat Success** :
```typescript
export interface ChatResultSuccess {
  readonly ok: true;
  readonly content: string; // NON-EMPTY (enforced by validator)
  readonly provider: 'offline' | 'local_llm' | 'online';
  readonly strategy: 'skill' | 'retrieval' | 'template' | 'llm' | 'mua';
  readonly metadata: {
    readonly conversationId: string;
    readonly messageId: string;
    readonly timestamp: number;
    readonly latencyMs: number;
    readonly offlineProof?: {
      readonly offlineMode: boolean;
      readonly networkAttempted: boolean;
      readonly signature: string;
    };
    readonly contextUsed?: string[];
    readonly confidence: number; // 0-1
  };
}
```

**Contrat Error** :
```typescript
export interface ChatResultError {
  readonly ok: false;
  readonly userMessage: string; // NON-EMPTY, user-facing
  readonly code: 'network_unavailable' | 'provider_failed' | 'timeout' | 'validation_failed' | 'unknown';
  readonly details?: string; // Technical details (internal)
  readonly timestamp: number;
  readonly metadata: {
    readonly conversationId: string;
    readonly messageId?: string;
  };
}

export type ChatResult = ChatResultSuccess | ChatResultError;
```

**ChatRequest** :
```typescript
export interface ChatRequest {
  readonly message: string;
  readonly conversationId: string;
  readonly metadata?: {
    readonly offlineMode?: boolean; // Explicit offline enforcement
    readonly allowNetwork?: boolean; // Opt-in for online
    readonly maxLatencyMs?: number;
    readonly preferredProvider?: 'skill' | 'retrieval' | 'template' | 'llm' | 'online';
    readonly context?: Record<string, any>;
  };
}
```

**Usages Confirmés** :
- ✅ `ConversationIntelligenceBridge` (src/services/conversation) → convertit vers `ChatResult`
- ✅ `ChatErrorBoundary` (src/components/chat) → affiche `ChatResult.error`
- ✅ Validators : `validateChatResult()`, `convertIPCToChatResult()`

---

### BACKEND RUST — 2 Systèmes Isolés

#### Système 1: `conversation_engine/types.rs` (1179 lignes)

**Contrat Request** :
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConversationRequest {
    pub user_message: String,
    pub conversation_id: Option<String>,
    pub mode: ConversationMode,
    pub ai_config: Option<AIConfig>,
    pub emotion_context: Option<EmotionState>,
    pub custom_system_prompt: Option<String>,
}
```

**Contrat Response** :
```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConversationResponse {
    pub assistant_message: String,
    pub conversation_id: String,
    pub message_id: String,
    pub detected_intention: Intention,
    pub detected_emotion: EmotionState,
    pub cognitive_tags: Vec<String>,
    pub cognitive_summary: String,
    pub metadata: ConversationMetadata,
}
```

**Utilisation** :
- ✅ `conversation_generate` Tauri command (commands.rs:35)
- ✅ `process_message()` orchestrator (mod.rs:154)
- ✅ OMEGA Pipeline v2 + Legacy fallback

---

#### Système 2: `overdrive/chat_orchestrator.rs`

**Contrat ChatRequest** (différent du frontend) :
```rust
pub struct ChatRequest {
    pub message: String,
    pub conversation_id: Option<String>,
    pub context: Vec<Message>,
    pub settings: ChatSettings,
    // ... (structure différente)
}
```

**Utilisation** :
- ⚠️ Module `overdrive` (legacy? concurrent?)
- ⚠️ Commandes GLM46V

---

## 🚨 PROBLÈMES IDENTIFIÉS

### 1. DUPLICATION TYPES FRONTEND ⚠️

**Problème** :
- 2 définitions de `ChatResult` (autonomy.ts vs conversationIntelligence.ts)
- Structures similaires mais incompatibles :
  - `provider` vs `providerUsed`
  - `strategy` vs absent
  - `metadata` structure différente
  
**Impact** :
- Risque de confusion des imports
- Tests peuvent valider mauvais contrat
- Maintenance fragile (changement dans 1 fichier oublié dans l'autre)

**Solution** : Consolidation dans **`src/types/autonomy.ts`** (source de vérité)

---

### 2. BACKEND NE SUPPORTE PAS ChatRequest/ChatResult ❌

**Problème** :
- Backend Rust utilise `ConversationRequest/Response` (types custom)
- Pas de `ok: bool` discriminator
- Pas de `AutonomyMode` enum Rust
- Pas de `OfflineProof` struct Rust

**Impact** :
- IPC manual conversion required (chatEngine.commands.ts → commands.rs)
- `OmegaGenerateArgs` → `ConversationRequest` transformation non-typed
- Erreurs Rust retournent strings génériques (pas de type-safe ChatErrorCode)

**Solution** : Créer types Rust mirrors (Phase 1.2)

---

### 3. IPC BRIDGE INCOMPLET ⚠️

**Actuel** :
```typescript
// Frontend
export interface OmegaGenerateArgs {
  message: string;
  conversationId: string;
  mode?: string;
  provider?: string;
  systemPrompt?: string;
}

export interface OmegaResponse {
  content: string;
  conversationId: string;
  messageId: string;
  frenchMasteryApplied: boolean;
  latencyMs: number;
  metadata?: { ... };
}
```

**Manque** :
- ❌ `autonomyMode` dans request
- ❌ `offlineProof` dans response
- ❌ Pas de discriminator `ok: boolean`
- ❌ Pas de structured error avec `ChatErrorCode`

**Solution** : Adapter IPC pour utiliser ChatRequest/ChatResult canoniques

---

### 4. ORCHESTRATOR OMEGA NE RETOURNE PAS ChatResult ⚠️

**Code Actuel** (mod.rs:154) :
```rust
pub async fn process_message(
    &self,
    request: ConversationRequest,
) -> Result<ConversationResponse, ConversationEngineError>
```

**Problème** :
- Return `Result<T, E>` générique Rust
- Pas de `ok: bool` dans success case
- Error type `ConversationEngineError` (pas `ChatErrorCode`)

**Solution** : Wrapper Result en ChatResult-compatible struct

---

## ✅ CONTRAT CANONIQUE PROPOSÉ

### Version TypeScript (Source de Vérité)

**Fichier** : `src/types/autonomy.ts` (déjà existant, à renforcer)

```typescript
/**
 * CANONICAL CONTRACT: ChatRequest
 * - Single source of truth for UI → Backend
 * - Enforces offline-first metadata
 */
export interface ChatRequest {
  // Core fields (REQUIRED)
  message: string; // User input (non-empty)
  conversationId: string; // Conversation UUID

  // Autonomy control (REQUIRED)
  autonomyMode: AutonomyMode; // OFFLINE | LOCAL_LLM | HYBRID | ONLINE_AUGMENTED

  // Optional fields
  metadata?: {
    offlineMode?: boolean; // Explicit offline enforcement
    allowNetwork?: boolean; // Opt-in for online (default: based on autonomyMode)
    maxLatencyMs?: number; // Timeout budget
    preferredProvider?: 'skill' | 'retrieval' | 'template' | 'llm' | 'online';
    systemPrompt?: string; // Custom instruction
    context?: Record<string, any>; // Additional context
  };
}

/**
 * CANONICAL CONTRACT: ChatResult (Success)
 */
export interface ChatResult {
  ok: true;
  content: string; // GUARANTEED non-empty

  // Metadata (REQUIRED for traceability)
  metadata: {
    conversationId: string;
    messageId: string;
    timestamp: number;
    
    // Autonomy proof (CRITICAL for offline-first validation)
    autonomyMode: AutonomyMode;
    providerUsed: 'ollama' | 'gemini' | 'openai' | 'anthropic' | 'offline' | 'skills' | 'template';
    strategy: 'skill' | 'retrieval' | 'template' | 'local_llm' | 'online' | 'mua';
    
    // Network proof (CRITICAL for offline verification)
    offlineProof: {
      networkAttempted: boolean;
      networkReason?: string;
      decisionPath: string[];
      signature: string;
    };
    
    // Performance
    generationTimeMs: number;
    latencyMs: number;
    
    // Quality
    confidenceScore: number; // 0-1
    sources?: string[]; // File paths, memory refs
    
    // Tracing
    traceId: string;
  };
}

/**
 * CANONICAL CONTRACT: ChatErrorResult
 */
export interface ChatErrorResult {
  ok: false;
  
  // User-facing error (ALWAYS displayable)
  userMessage: string; // Non-empty, friendly message
  
  // Machine-readable error
  error: {
    code: ChatErrorCode; // Enum for routing
    message: string; // Technical details (internal)
    stack?: string; // Stack trace (dev mode)
  };
  
  // Suggested action
  suggestedAction?: 'retry' | 'check_network' | 'enable_ollama' | 'contact_support';
  
  // Metadata
  metadata: {
    conversationId: string;
    messageId?: string;
    timestamp: number;
    traceId: string;
    
    // Context for error (helps debugging)
    attemptedProvider?: string;
    attemptedMode?: AutonomyMode;
  };
}

export type ChatResponse = ChatResult | ChatErrorResult;

/**
 * Error codes for intelligent fallback
 */
export enum ChatErrorCode {
  // Provider errors
  PROVIDER_UNAVAILABLE = 'PROVIDER_UNAVAILABLE',
  PROVIDER_TIMEOUT = 'PROVIDER_TIMEOUT',
  PROVIDER_RATE_LIMIT = 'PROVIDER_RATE_LIMIT',
  PROVIDER_INVALID_KEY = 'PROVIDER_INVALID_KEY',
  
  // System errors
  MEMORY_RETRIEVAL_FAILED = 'MEMORY_RETRIEVAL_FAILED',
  SKILL_EXECUTION_FAILED = 'SKILL_EXECUTION_FAILED',
  INVALID_INPUT = 'INVALID_INPUT',
  
  // Offline engine errors (should NOT happen, but handle gracefully)
  OFFLINE_ENGINE_FAILED = 'OFFLINE_ENGINE_FAILED',
  
  // Unknown
  UNKNOWN = 'UNKNOWN',
}
```

---

### Version Rust (À Créer)

**Fichier** : `src-tauri/src/types/autonomy.rs` (nouveau)

```rust
/**
 * CANONICAL CONTRACT: ChatRequest (Rust mirror of TypeScript)
 */
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatRequest {
    pub message: String,
    pub conversation_id: String,
    pub autonomy_mode: AutonomyMode,
    
    #[serde(default)]
    pub metadata: Option<ChatRequestMetadata>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatRequestMetadata {
    #[serde(default)]
    pub offline_mode: Option<bool>,
    
    #[serde(default)]
    pub allow_network: Option<bool>,
    
    #[serde(default)]
    pub max_latency_ms: Option<u64>,
    
    #[serde(default)]
    pub preferred_provider: Option<String>,
    
    #[serde(default)]
    pub system_prompt: Option<String>,
}

/**
 * AutonomyMode enum (matches TypeScript)
 */
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum AutonomyMode {
    Offline,
    LocalLlm,
    Hybrid,
    OnlineAugmented,
}

/**
 * CANONICAL CONTRACT: ChatResult (Success)
 */
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatResult {
    pub ok: bool, // Always true for success variant
    pub content: String, // Non-empty
    pub metadata: ChatResultMetadata,
}

/**
 * CANONICAL CONTRACT: ChatErrorResult
 */
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatErrorResult {
    pub ok: bool, // Always false for error variant
    pub user_message: String,
    pub error: ChatErrorDetails,
    pub suggested_action: Option<String>,
    pub metadata: ChatErrorMetadata,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatErrorDetails {
    pub code: ChatErrorCode,
    pub message: String,
    pub stack: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ChatErrorCode {
    ProviderUnavailable,
    ProviderTimeout,
    ProviderRateLimit,
    ProviderInvalidKey,
    MemoryRetrievalFailed,
    SkillExecutionFailed,
    InvalidInput,
    OfflineEngineFailed,
    Unknown,
}

/**
 * Unified response type (discriminated union via `ok` field)
 */
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum ChatResponse {
    Success(ChatResult),
    Error(ChatErrorResult),
}
```

---

## 📋 PLAN D'IMPLÉMENTATION PHASE 1

### Étape 1.1: Consolidation Types Frontend ✅ (Déjà fait)

**Action** :
- ✅ `src/types/autonomy.ts` existe déjà avec contrats complets
- ✅ `src/types/conversationIntelligence.ts` existe avec validators

**Décision** :
- **Garder les 2 fichiers** (pas de duplication réelle - complémentaires)
- `autonomy.ts` → contrats de base (ChatResult, AutonomyMode, OfflineProof)
- `conversationIntelligence.ts` → extensions cognitive (UnderstandingFrame, ReasoningPlan, SkillArtifact)

**Re-export unifié** : Créer `src/types/index.ts` pour imports centralisés

---

### Étape 1.2: Créer Types Rust Canoniques 🔧

**Action** :
1. Créer `src-tauri/src/types/autonomy.rs`
2. Implémenter structs mirrors (ChatRequest, ChatResult, ChatErrorResult, AutonomyMode, ChatErrorCode)
3. Ajouter trait `From<ConversationResponse>` pour conversion vers ChatResult

**Fichiers à modifier** :
- `src-tauri/src/types/mod.rs` (ajouter `pub mod autonomy;`)
- `src-tauri/src/lib.rs` (re-export public types)

---

### Étape 1.3: Adapter IPC Commands 🔧

**Action** :
1. Modifier `src-tauri/src/conversation_engine/commands.rs` :
   - Ajouter fonction `conversation_generate_v2` utilisant `ChatRequest` → `ChatResponse`
   - Garder `conversation_generate` legacy (compatibilité)
2. Modifier `src/services/tauri/chatEngine.commands.ts` :
   - Ajouter fonction `generateV2()` utilisant types canoniques
   - Garder `generate()` legacy

**Migration Progressive** :
- Frontend peut utiliser `generateV2()` pour nouveaux flows
- Legacy flows continuent avec `generate()`
- Déprécation progressive de legacy après validation complète

---

### Étape 1.4: Adapter Orchestrator Return Type 🔧

**Action** :
Modifier `src-tauri/src/conversation_engine/mod.rs:154` :

```rust
pub async fn process_message_v2(
    &self,
    request: ChatRequest, // Nouveau type canonique
) -> ChatResponse { // Retourne TOUJOURS ChatResponse (jamais Result)
    match self.process_message_internal(request).await {
        Ok(response) => ChatResponse::Success(ChatResult {
            ok: true,
            content: response.assistant_message,
            metadata: ChatResultMetadata {
                // ... conversion
            }
        }),
        Err(e) => ChatResponse::Error(ChatErrorResult {
            ok: false,
            user_message: format!("Unable to process your message: {}", e),
            error: ChatErrorDetails {
                code: classify_error(&e),
                message: e.to_string(),
                stack: None,
            },
            metadata: ChatErrorMetadata { /* ... */ }
        })
    }
}
```

**Avantages** :
- ✅ Retourne TOUJOURS `ChatResponse` (jamais panic, jamais Result::Err)
- ✅ Type-safe discriminated union (`ok: bool`)
- ✅ Error displayable garanti (`user_message` non-vide)

---

### Étape 1.5: Documentation Contrat 📄

**Action** :
Créer `docs/CANONICAL_CONTRACTS.md` documentant :
- Types canoniques (TS + Rust)
- Équivalences exactes entre types
- Flow IPC complet (UI → Service → IPC → Tauri → Orchestrator → Response)
- Exemples de validation (tests de contrat)

---

## 🎯 GATE_1 — CRITÈRES DE VALIDATION

### Critère 1: Types Consolidés ✅

**Validation** :
- [x] `src/types/autonomy.ts` existe avec ChatRequest/ChatResult complets
- [x] `src/types/conversationIntelligence.ts` complète avec validators
- [ ] `src-tauri/src/types/autonomy.rs` créé avec mirrors Rust
- [ ] Tests de sérialisation TS ↔ Rust passent

---

### Critère 2: Toute Fonction Retourne ChatResponse ⚠️

**Validation Manuelle Required** :

**Frontend** :
- ✅ `AutonomousChatEngine.generate()` → `ChatResult`
- ✅ `OfflineFallbackEngine.generate()` → `ChatResult`
- ✅ `ResponseComposer.composeResponse()` → `ChatResult`
- ✅ `ProviderRouter.route()` → `ChatResult`
- ⚠️ `useConversationEngine.sendMessage()` → `ConversationResponse | null` (devrait être `ChatResponse`)

**Backend** :
- ⚠️ `conversation_generate()` → `CommandResult<serde_json::Value>` (devrait être `ChatResponse`)
- ⚠️ `process_message()` → `Result<ConversationResponse, Error>` (devrait être `ChatResponse`)

**Status** : ❌ **FAIL** — Migration vers ChatResponse pas complète

---

### Critère 3: Erreurs Structurées (ChatErrorCode) ⚠️

**Validation** :
- ✅ `ChatErrorCode` enum défini (autonomy.ts)
- ❌ Backend Rust retourne strings génériques (pas de ChatErrorCode enum)
- ❌ IPC errors pas convertis en ChatErrorResult structuré

**Status** : ❌ **FAIL** — Rust backend ne classifie pas errors avec enum

---

### Critère 4: AutonomyMode Traceable 🔍

**Validation** :
- ✅ `AutonomyMode` enum défini (autonomy.ts)
- ❌ Backend Rust n'a pas enum `AutonomyMode`
- ⚠️ `OmegaGenerateArgs` n'a pas champ `autonomyMode`
- ⚠️ Responses n'incluent pas `metadata.autonomyMode`

**Status** : ❌ **FAIL** — AutonomyMode pas propagé E2E

---

### Critère 5: OfflineProof Mesurable 🔍

**Validation** :
- ✅ `OfflineProof` struct défini (autonomy.ts)
- ❌ Backend Rust ne génère pas `OfflineProof`
- ❌ Responses n'incluent pas `metadata.offlineProof`
- ❌ Pas de signature/hash pour audit

**Status** : ❌ **FAIL** — OfflineProof pas implémenté backend

---

## 🚦 DÉCISION GATE_1

### Status : ❌ **FAIL (Expected)**

**Raison** :
Phase 1 est une phase d'**audit et définition** — pas d'implémentation encore.

**Éléments Validés** ✅ :
1. Contrats frontend existent et sont complets
2. Architecture anti-silence est présente (ChatResult discriminated union)
3. Engines frontend utilisent ChatResult
4. Validators existent (`validateChatResult()`)

**Gaps Identifiés** ❌ :
1. Backend Rust ne supporte pas ChatRequest/ChatResult types
2. IPC bridge utilise types intermédiaires (OmegaGenerateArgs/OmegaResponse)
3. AutonomyMode pas propagé E2E
4. OfflineProof pas généré
5. ChatErrorCode pas utilisé backend

---

## 📝 ACTIONS REQUISES POUR GATE_1 PASS

### Actions Bloquantes (Phase 1.2) 🔴

1. **Créer types Rust canoniques** :
   - `src-tauri/src/types/autonomy.rs` avec ChatRequest/ChatResult/AutonomyMode
   - Tests de sérialisation TS ↔ Rust

2. **Adapter IPC commands** :
   - `conversation_generate_v2()` utilisant ChatRequest → ChatResponse
   - Frontend `generateV2()` wrapper

3. **Adapter orchestrator** :
   - `process_message_v2()` retournant ChatResponse (never Result::Err exposed to IPC)

### Actions Recommandées (Phase 2) 🟡

4. **Implémenter OfflineProof generator** :
   - Rust struct générant signature + decisionPath
   - Inclus dans ChatResult.metadata

5. **Classifier errors avec ChatErrorCode** :
   - Fonction `classify_error(ConversationEngineError) -> ChatErrorCode`
   - Mapping exhaustif des erreurs Rust

6. **Migrer hooks frontend** :
   - `useConversationEngine` retourne `ChatResponse` au lieu de `ConversationResponse | null`

---

## 📊 RÉSUMÉ PHASE 1

**Ce qui existe déjà** ✅ :
- Types frontend complets (autonomy.ts + conversationIntelligence.ts)
- Architecture anti-silence (discriminated union avec `ok`)
- Engines utilisant ChatResult
- Validators et converters

**Ce qui manque** ❌ :
- Types Rust mirrors
- IPC bridge utilisant contrats canoniques
- AutonomyMode E2E propagation
- OfflineProof generation
- ChatErrorCode backend classification

**Statut Global Phase 1** : 🟡 **DÉFINITION COMPLÈTE** — Implémentation partielle (frontend ✅, backend ❌)

**Prochaine Étape** :
- **Phase 1.2 (Implémentation)** : Créer types Rust + adapter IPC + orchestrator
- **OU Phase 2 (Parallèle)** : Valider TIP orchestration offline-first avec contrats actuels

---

**Document Version**: v1.0  
**Status**: GATE_1 PENDING (attente implémentation types Rust)  
**Prochaine Phase**: Phase 1.2 (Implementation) OU Phase 2 (TIP Orchestration)
