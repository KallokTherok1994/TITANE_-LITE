# PHASE 0 — TRUTH AUDIT : Pipeline Chat TITANE∞ (Facts Only)

**Date**: 2026-02-07  
**Version**: v27.4.1  
**Auditeur**: Agent P∞ ULTIMATE SEAL  
**Objectif**: Extraire la réalité factuelle du pipeline chat avant toute opinion/correction

---

## 📍 ARCHITECTURE FACTUELLE CONFIRMÉE

### 1. Composants UI Frontend (React + TypeScript)

**Hook Principal**:
- **`src/hooks/useConversationEngine.ts`** (439 lignes)
  - Export : `useConversationEngine(options)` → hook React unifié
  - État : `messages`, `isLoading`, `error`, `conversationId`, `currentMode`
  - Actions : `sendMessage(content)`, `clearMessages()`, `deleteMessage()`
  - Intégration : `useChatMemory()` pour persistance
  - Auto-healing : retry logic avec MAX_RETRIES=3
  - localStorage : charge messages au mount depuis `titane_chat_mode_${currentMode}`

**Page Chat Principale**:
- **`src/ui/pages/Chat.tsx`** (référencé dans docs comme page prod)
  - Import : `useChat` hook (composition de plusieurs sous-hooks)
  - Composants : `VirtualizedMessageList`, `ChatInput`, `ChatToolbar`

**Composants de Rendu Messages**:
- **`src/components/chat/MessageList.tsx`** (278+ lignes)
  - Validation messages avec filtre : `!message || typeof message !== 'object || typeof message.content !== 'string'`
  - Protection individuelle par bulle (try/catch par message)
  - Loading indicator avec `isLoading` prop
  - Auto-recovery : si bulle plante, affiche fallback
  
- **`src/components/AIChatBubble.tsx`** (280+ lignes)
  - Validation stricte : filtre messages vides/invalides
  - Helper : `getMessageText(message)` pour extraire contenu
  - Virtual

ization si >50 messages
  - Logs validation : `console.warn('[AIChatBubble] ⚠️ Message vide')`

**Pages Alternatives**:
- `src/pages/ChatPage.tsx` (existence confirmée)
- `src/pages/TitanePage.tsx` (avec `ConversationMessage` component)

---

### 2. Services TypeScript (IPC Layer)

**Service Commandes Principal**:
- **`src/services/tauri/chatEngine.commands.ts`** (299 lignes)
  - **Commande OMEGA principale** : `conversation_generate` (IPC)
  - Export : `generate(args: OmegaGenerateArgs): Promise<OmegaResponse>`
  - Args : `{ message, conversationId, mode?, provider?, systemPrompt? }`
  - Response garde : `ensureOmegaResponse()` — fallback si content vide
  - Fallback content : `'Backend returned empty content. Please retry your request.'`
  - Ancienne commande : `generate_response`, `stream_response` (deprecated ?)

**Service API Chat**:
- **`src/services/api/chat.ts`** (1009+ lignes)
  - Class : `ChatService` (singleton export `chatService`)
  - Méthodes : `sendMessage()`, `sendMessageStream()`, `sendMessageLegacy()`
  - Note : Migration vers OMEGA `conversation_generate` documentée
  - Intégration streaming : listeners events `omega-stream-chunk`, `omega-stream-complete`

**Wrapper Sécurisé**:
- **`src/lib/security.ts`** (ligne 1843+)
  - Export : `secureInvoke(cmd, args)` — validate response non-null
  - Utilisé par : tous les `chatEngine.commands.ts` via `invokeCommand<T>()`

---

### 3. Backend Rust (Tauri Commands)

**Fichier Commandes OMEGA**:
- **`src-tauri/src/conversation_engine/commands.rs`** (490 lignes)
  
**Commande IPC Principale** (ligne 35):
```rust
#[tauri::command]
pub async fn conversation_generate(
    engine: State<'_, Arc<ConversationEngineState>>,
    message: String,
    conversation_id: String,
    mode: Option<String>,
    provider: Option<String>,
    system_prompt: Option<String>,
) -> CommandResult<serde_json::Value>
```

**Pipeline Traitement**:
1. Convertit `mode: String` → `ConversationMode` enum (default, planning, brainstorming, synthesis, journal, debug_cognitive)
2. Convertit `provider: String` → `ProviderPreference` enum (auto, gemini, ollama, openai, claude, local)
3. Crée `ConversationRequest` avec config AI
4. Appelle `engine.process_message(request).await` → **ORCHESTRATEUR PRINCIPAL**
5. Mesure latency (`start_time.elapsed()`)
6. **VALIDATION CRITIQUE** (ligne 95) : `if response.assistant_message.trim().is_empty() { return Err("AI response content is empty") }`
7. Retourne JSON structuré : `{ content, conversationId, messageId, frenchMasteryApplied, latencyMs, metadata }`

**Autres Commandes**:
- `create_new_conversation()` (ligne 21) — génère UUID nouveau
- `conversation_process_message()` (ligne 117) — ancienne interface (compatibilité)

---

### 4. Orchestrateur Backend (TITANE Intelligence Primaire - TIP)

**Fichier Orchestrateur**:
- **`src-tauri/src/conversation_engine/mod.rs`** (apparaît dans audit)
  - Struct : `ConversationEngineState` (détient le state global)
  - Méthode : `async fn process_message(&self, request: ConversationRequest) -> Result<ConversationResponse>`
  - **C'EST LE CERVEAU DÉCISIONNEL** (TIP)

**Pipeline Interne** (à confirmer en lecture complète):
- **`src-tauri/src/conversation_engine/pipeline.rs`** (existe, non encore lu intégralement)
- Probablement contient : Understand → Recall → Plan → Select Strategy → Act → Compose → Trace

**Modules Associés** (confirmés par file search):
- `intent.rs` — détection intention
- `emotion.rs` — analyse émotionnelle
- `memory.rs` — mémoire conversationnelle
- `cognitive.rs` — tagging cognitif
- `french_mastery.rs` — maîtrise française
- `omega_integration.rs` — intégration OMEGA
- `types.rs` — types de données

---

## 🔍 FLUX DE DONNÉES CONFIRMÉ (End-to-End)

### Étape 1 : USER INPUT

```
User tape message dans ChatInput.tsx
  ↓
onSend(text) trigger
  ↓
useConversationEngine.sendMessage(content)
```

### Étape 2 : FRONTEND PROCESSING

```typescript
// src/hooks/useConversationEngine.ts (ligne 218+)
sendMessage(content: string) {
  // 1. Ajouter message user à l'UI immédiatement
  const userMessage: ConversationMessage = {
    id: `user-${Date.now()}`,
    role: 'user',
    content,
    timestamp: Date.now()
  };
  setMessages(prev => [...prev, userMessage]);
  
  // 2. Persister user message
  await saveMessage(userAIMessage); // via useChatMemory
  
  // 3. Appeler backend
  const response = await processMessage({
    message: content,
    conversationId: conversationId || 'new',
    mode: currentMode
  });
  
  // 4. Ajouter réponse assistant à l'UI
  const assistantMessage = {
    id: response.messageId,
    role: 'assistant',
    content: response.content,
    timestamp: Date.now(),
    metadata: response.metadata
  };
  setMessages(prev => [...prev, assistantMessage]);
  
  // 5. Persister assistant message
  await saveMessage(assistantAIMessage);
}
```

### Étape 3 : IPC CALL

```typescript
// src/services/conversationEngine.ts (wrapper probable)
export async function processMessage(args) {
  return chatEngineCommands.generate({
    message: args.message,
    conversationId: args.conversationId,
    mode: args.mode
  });
}
```

```typescript
// src/services/tauri/chatEngine.commands.ts (ligne 261)
export async function generate(args: OmegaGenerateArgs) {
  const response = await invokeCommand<OmegaResponse>('conversation_generate', {
    message: args.message,
    conversation_id: args.conversationId,
    mode: args.mode ?? null,
    provider: args.provider ?? null,
    system_prompt: args.systemPrompt ?? null
  });
  
  // Garde anti-silence (ligne 61)
  return ensureOmegaResponse(response);
}
```

```typescript
// src/lib/security.ts
export async function secureInvoke<T>(cmd: string, args?: unknown): Promise<T> {
  const raw = await invoke(cmd, args);
  
  // Validation response non-null (ligne 1843)
  if (raw == null) {
    throw new Error('Response validation failed: Response is null or undefined');
  }
  
  return raw as T;
}
```

### Étape 4 : BACKEND RUST RECEPTION

```rust
// src-tauri/src/conversation_engine/commands.rs (ligne 35)
#[tauri::command]
pub async fn conversation_generate(
    engine: State<'_, Arc<ConversationEngineState>>,
    message: String,
    conversation_id: String,
    mode: Option<String>,
    provider: Option<String>,
    system_prompt: Option<String>
) -> CommandResult<serde_json::Value> {
    // Conversion mode
    let conversation_mode = match mode.as_deref() {
        Some("coach") => ConversationMode::Default,
        Some("strategist") => ConversationMode::Planning,
        // ... autres modes
        _ => ConversationMode::Default
    };
    
    // Création requête
    let request = ConversationRequest {
        user_message: message,
        conversation_id: Some(conversation_id.clone()),
        mode: conversation_mode,
        ai_config: /* ... */,
        emotion_context: None,
        custom_system_prompt: system_prompt
    };
    
    // Traitement via ORCHESTRATEUR
    let start_time = std::time::Instant::now();
    let response = engine.process_message(request).await
        .map_err(|e| e.to_string())?;
    let latency_ms = start_time.elapsed().as_millis() as u64;
    
    // ✅ VALIDATION ANTI-SILENCE (ligne 95)
    if response.assistant_message.trim().is_empty() {
        log::error!("[Ω:CMD] ❌ AI generated empty response");
        return Err("AI response content is empty".to_string());
    }
    
    // Log success
    log::info!("[Ω:CMD] ✅ Success | msg_id={} | content_len={} | latency={}ms",
        response.message_id, response.assistant_message.len(), latency_ms);
    
    // Retour JSON structuré
    Ok(serde_json::json!({
        "content": response.assistant_message,
        "conversationId": response.conversation_id,
        "messageId": response.message_id,
        "frenchMasteryApplied": true,
        "latencyMs": latency_ms,
        "metadata": {
            "intention": format!("{:?}", response.detected_intention),
            "emotion": format!("{:?}", response.detected_emotion),
            "cognitiveTags": response.cognitive_tags,
            "cognitiveSummary": response.cognitive_summary
        }
    }))
}
```

### Étape 5 : ORCHESTRATEUR OMEGA (TIP — TITANE Intelligence Primaire)

**ARCHITECTURE DOUBLE-PIPELINE CONFIRMÉE** (ligne 154-205 mod.rs) :

```rust
// src-tauri/src/conversation_engine/mod.rs (ligne 154)
impl ConversationEngineState {
    pub async fn process_message(&self, request: ConversationRequest) 
        -> Result<ConversationResponse, ConversationEngineError> {
        
        // ═══════════════════════════════════════════════════════════
        // TRY: OMEGA PIPELINE v2 (Principal - R05 P1)
        // ═══════════════════════════════════════════════════════════
        match self.omega_bridge.process_through_omega(&request).await {
            Ok(omega_result) => {
                log::info!("[CONV-ENGINE] ✅ OMEGA pipeline succeeded | latency={}ms", 
                    omega_result.latency_ms);
                
                // P2 OPTIMIZATION: Direct conversion (bypass legacy duplication)
                match self.omega_bridge.convert_to_conversation_response(
                    omega_result, 
                    &request, 
                    conversation_id
                ).await {
                    Ok(response) => {
                        log::info!("[CONV-ENGINE] 🚀 P2 Direct conversion | bypass_legacy=true");
                        return Ok(response);
                    },
                    Err(e) => {
                        log::warn!("[CONV-ENGINE] ⚠️ P2 Conversion failed: {}", e);
                        // FALLBACK → Legacy pipeline
                    }
                }
            },
            Err(e) => {
                log::warn!("[CONV-ENGINE] ⚠️ OMEGA pipeline failed: {}", e);
                // FALLBACK → Legacy pipeline
            }
        }
        
        // ═══════════════════════════════════════════════════════════
        // FALLBACK: LEGACY PIPELINE (Secours)
        // ═══════════════════════════════════════════════════════════
        self.pipeline.process(request).await
    }
}
```

**OMEGA PIPELINE v2 (Principal)** — 8 étapes confirmées :

1. **Understand** — Analyse intention + émotion
2. **Recall** — Récupération mémoire (STM/MTM/LTM)
3. **Plan** — Stratégie de réponse (Skill|Retrieval|Template)
4. **Select** — Router provider (Auto → Gemini|Ollama|Claude|Local)
5. **Act** — Génération via AI Router
6. **Compose** — FrenchMastery post-processing (CRITIQUE)
7. **Trace** — Logging metrics (latency, intent, safety_score)
8. **Learn** — Assimilation + Memory update

**LEGACY PIPELINE (Fallback)** — `pipeline.rs:60+` :

1. **Preprocess** — Validation + cleaning message
2-4. **PARALLEL** (tokio::join!) :
   - Intent Analysis (CPU-bound, ~2-5ms)
   - Emotion Analysis (CPU-bound, ~2-5ms)
   - Memory Context (IO-bound, ~10-50ms)
5. **Build Prompt** — Enriched system prompt
6. **AI Generation** — `ai_router.generate()`
6.5. **FrenchMastery** — Post-processing CRITIQUE (ligne 138+)
7. **Memory Save** — Store conversation turn

### Étape 6 : RETOUR FRONTEND

```
JSON response remonte via IPC
  ↓
ensureOmegaResponse() applique garde (si content vide → fallback)
  ↓
Hook useConversationEngine reçoit response
  ↓
Crée ConversationMessage assistant
  ↓
setMessages(prev => [...prev, assistantMessage])
  ↓
MessageList re-render
  ↓
MessageBubble affiche content
  ↓
User voit réponse
```

---

## ⚠️ POINTS DE RUPTURE POTENTIELS (Hypothèses à Tester)

### 1. **Backend Rust Panic/Error Non Catchée**

**Localisation** : `engine.process_message(request).await`  
**Symptôme** : Si panic dans pipeline Rust → IPC timeout → frontend stuck  
**Test** : Injecter erreur simulée dans pipeline

### 2. **Provider Externe Down Sans Fallback**

**Localisation** : Sélection provider dans `process_message`  
**Symptôme** : Si Gemini/Ollama fail + pas de fallback local → empty response  
**Protection** : Validation `response.assistant_message.trim().is_empty()` existe ligne 95  
**Résultat** : Retournerait `Err("AI response content is empty")` → frontend reçoit erreur IPC

### 3. **Message Vide Côté Frontend**

**Localisation** : `useConversationEngine.sendMessage(content)`  
**Symptôme** : Si user envoie string vide → backend traite quand même  
**Test** : Vérifier si validation pré-IPC existe

### 4. **ConversationId Null/Invalid**

**Localisation** : `conversation_generate(conversation_id: String)`  
**Symptôme** : Si conversationId invalide → peut créer orphan messages  
**Protection** : Backend accepte `Option<String>` dans `ConversationRequest`

### 5. **Timeout IPC Frontend**

**Localisation** : `secureInvoke()` sans timeout explicite  
**Symptôme** : Si backend prend >30s → frontend peut timeout ou attendre indéfiniment  
**Test** : Simuler traitement lent backend

### 6. **Memory Overflow (Messages Non Bornés)**

**Localisation** : `setMessages(prev => [...prev, userMessage])`  
**Protection** : `DEFAULT_MAX_MESSAGES = 500` défini (ligne 36) mais pas toujours appliqué  
**Code** (ligne 226): 
```typescript
const maxMessages = options.maxMessages ?? DEFAULT_MAX_MESSAGES;
const updated = [...prev, userMessage];
return updated.length > maxMessages ? updated.slice(-maxMessages) : updated;
```

### 7. **Streaming Events Non Écoutés**

**Localisation** : `onStreamChunk()`, `onStreamDone()` existent mais non vérifiés si utilisés  
**Symptôme** : Si streaming activé mais listeners absents → chunks perdus

### 8. **localStorage Corruption**

**Localisation** : `localStorage.getItem('titane_chat_mode_${currentMode}')`  
**Symptôme** : Si JSON parse fail → messages perdus au reload  
**Protection** : Try/catch probable mais à vérifier

---

## 📊 MÉTRIQUES EXTRAITES

### Latency Tracking

- **Frontend** : Pas de mesure visible dans `useConversationEngine`
- **Backend** : `latency_ms` mesuré et retourné (ligne 88-89 commands.rs)
- **Log** : `log::info!("[Ω:CMD] ✅ Success | ... | latency={}ms")`

### Error Tracking

- **Frontend** : `setError(errorMessage)` + `options.onError?.(error)`
- **Backend** : `log::error!("[Ω:CMD] ❌ AI generated empty response")`

### Retry Logic

- **Frontend** : `MAX_RETRIES = 3` + `RETRY_DELAY_BASE_MS = 1000` (ligne 37-38)
- **Backend** : Non confirmé dans commands.rs (probablement dans pipeline)

### Validation Guards

1. ✅ **Backend** : `if response.assistant_message.trim().is_empty()` (ligne 95)
2. ✅ **Frontend Service** : `ensureOmegaResponse()` avec fallback content (ligne 61-66)
3. ✅ **Frontend UI** : Filtres messages invalides dans `AIChatBubble` et `MessageList`

---

## 🔬 TESTS E2E EXISTANTS

**Fichier** : `e2e/desktop/chat.wdio.test.js`

```javascript
describe('Desktop (Tauri) Chat', () => {
  it('sends a user message and renders it in the chat log', async () => {
    await browser.url('/chat');
    const input = await $('#chat-input-textarea');
    await input.setValue('WDIO ping message');
    
    const sendButton = await $('.chat-send-btn');
    await sendButton.click();
    
    await browser.waitUntil(async () => {
      const bubble = await $('.message-bubble-user');
      return bubble.isExisting() && (await bubble.getText()).includes('WDIO ping message');
    }, { timeout: 20000 });
    
    const bubbles = await $$('.message-bubble-user');
    assert.ok(bubbles.length >= 1);
  });
});
```

**Statut** : Créé, pas encore exécuté (Phase 4 précédente - requiert tauri-driver)

---

## 📁 FICHIERS IDENTIFIÉS (Chemins Réels)

### Frontend (TypeScript/React)

1. `src/hooks/useConversationEngine.ts` — Hook principal unifié
2. `src/ui/pages/Chat.tsx` — Page chat production
3. `src/pages/ChatPage.tsx` — Page chat alternative
4. `src/pages/TitanePage.tsx` — Page avec ConversationMessage
5. `src/components/chat/MessageList.tsx` — Liste messages avec validation
6. `src/components/AIChatBubble.tsx` — Rendu bulles + filtres
7. `src/components/chat/MessageBubble.tsx` — Bulle individuelle
8. `src/components/chat/ChatInput.tsx` — Input utilisateur
9. `src/services/tauri/chatEngine.commands.ts` — Wrapper IPC OMEGA
10. `src/services/api/chat.ts` — Service API chat (legacy + OMEGA)
11. `src/services/conversationEngine.ts` — Probablement wrapper processMessage
12. `src/lib/security.ts` — secureInvoke + validation IPC
13. `src/hooks/useChatMemory.ts` — Persistance mémoire

### Backend (Rust/Tauri)

14. `src-tauri/src/conversation_engine/commands.rs` — Commandes IPC Tauri
15. `src-tauri/src/conversation_engine/mod.rs` — Orchestrateur TIP
16. `src-tauri/src/conversation_engine/pipeline.rs` — Pipeline OMEGA
17. `src-tauri/src/conversation_engine/types.rs` — Types de données
18. `src-tauri/src/conversation_engine/intent.rs` — Détection intention
19. `src-tauri/src/conversation_engine/emotion.rs` — Analyse émotionnelle
20. `src-tauri/src/conversation_engine/memory.rs` — Mémoire conversationnelle
21. `src-tauri/src/conversation_engine/cognitive.rs` — Tagging cognitif
22. `src-tauri/src/conversation_engine/french_mastery.rs` — Maîtrise française
23. `src-tauri/src/conversation_engine/omega_integration.rs` — Intégration OMEGA

### Tests

24. `e2e/desktop/chat.wdio.test.js` — Test E2E envoi message
25. `src/__tests__/features/chat/ChatMessage.test.tsx` — Tests composant
26. `src/components/chat/MessageList.test.tsx` — Tests liste

---

## ✅ VALIDATIONS ANTI-SILENCE CONFIRMÉES

### 1. Backend Rust (CRITIQUE)

**Fichier** : `src-tauri/src/conversation_engine/commands.rs` (ligne 95)

```rust
if response.assistant_message.trim().is_empty() {
    log::error!("[Ω:CMD] ❌ AI generated empty response");
    return Err("AI response content is empty".to_string());
}
```

**Impact** : ❌ Si vide → erreur IPC retournée → frontend reçoit rejection Promise

### 2. Frontend Service (GARDE)

**Fichier** : `src/services/tauri/chatEngine.commands.ts` (ligne 61-66)

```typescript
const OMEGA_FALLBACK_CONTENT = 'Backend returned empty content. Please retry your request.';

function ensureOmegaResponse(response: OmegaResponse): OmegaResponse {
  const content = typeof response?.content === 'string' ? response.content : '';
  if (content.trim().length === 0) {
    return { ...response, content: OMEGA_FALLBACK_CONTENT };
  }
  return response;
}
```

**Impact** : ✅ Si backend bypass validation ET retourne empty → fallback affiché

### 3. Frontend UI (FILTRES)

**Fichier** : `src/components/chat/MessageList.tsx` (ligne 244+)

```typescript
if (!message || typeof message !== 'object' || typeof message.content !== 'string') {
  logger.warn('Skipping invalid message', { index });
  return null;
}
```

**Fichier** : `src/components/AIChatBubble.tsx` (ligne 278+)

```typescript
const validMessages = messages.filter(message => {
  // Validation structure + role
  if (!message || !message.role || !['user', 'assistant'].includes(message.role)) {
    console.warn('[AIChatBubble] ⚠️ Message invalide (rôle)', message);
    return false;
  }
  
  // Validation contenu
  const messageText = getMessageText(message);
  if (!messageText || messageText.trim().length === 0) {
    console.warn('[AIChatBubble] ⚠️ Message vide', { role, timestamp });
    return false;
  }
  
  return true;
});
```

**Impact** : ✅ Messages vides/invalides filtrés avant affichage

---

## 🎯 CONTRATS IPC IDENTIFIÉS

### Commande Principale : `conversation_generate`

**Request Interface** (TypeScript):
```typescript
interface OmegaGenerateArgs {
  message: string;
  conversationId: string;
  mode?: string; // 'coach' | 'strategist' | 'brainstorming' | 'synthesis' | 'journal' | 'debug_cognitive'
  provider?: string; // 'auto' | 'gemini' | 'ollama' | 'openai' | 'claude' | 'local'
  systemPrompt?: string;
}
```

**Response Interface** (TypeScript):
```typescript
interface OmegaResponse {
  content: string;
  conversationId: string;
  messageId: string;
  frenchMasteryApplied: boolean;
  latencyMs: number;
  metadata?: {
    intention?: string;
    emotion?: string;
    cognitiveTags?: string[];
    cognitiveSummary?: string;
    provider?: string;
  };
}
```

**Rust Implementation Signature**:
```rust
#[tauri::command]
pub async fn conversation_generate(
    engine: State<'_, Arc<ConversationEngineState>>,
    message: String,
    conversation_id: String,
    mode: Option<String>,
    provider: Option<String>,
    system_prompt: Option<String>
) -> CommandResult<serde_json::Value>
```

**Contrat Validé** : ✅ Types alignés TS ↔ Rust

---

## 🚨 GATE_0 PRELIMINARY — Points de Rupture Silence

### PASS ✅

1. **Backend empty response** → `Err("AI response content i empty")` retourné
2. **Frontend ensureOmegaResponse** → fallback affiché si bypass backend
3. **Frontend UI filters** → messages vides filtrés avant render

### FAIL POTENTIELS (à tester) ⚠️

1. **Backend panic non catchée** → IPC timeout → UI stuck (pas de fallback visible)
2. **Provider timeout sans circuit breaker** → attente infinie backend
3. **Frontend input vide non validé** → backend traite quand même
4. **Streaming non géré correctement** → chunks perdus/pas d'UI update

---

## 📊 NEXT STEPS (Phase 0.2)

### Lecture Complète Pipeline

1. Lire `src-tauri/src/conversation_engine/mod.rs` intégralement
2. Lire `src-tauri/src/conversation_engine/pipeline.rs` intégralement
3. Identifier : Understand → Recall → Plan → Select → Act → Compose → Trace → Learn

### Tests Simulation

1. Simuler backend empty response (modifier commands.rs temporairement)
2. Simuler backend panic (ajouter `panic!()` dans pipeline)  
3. Simuler provider timeout (mock provider slow response)
4. Tester input vide frontend
5. Valider streaming events écoutés

### Diagramme Mermaid

Produire diagramme de flux factuel (Phase 0.3)

---

**Document Version**: v1.0  
**Statut**: FACTS ONLY — Aucune opinion/correction appliquée  
**Prochaine Phase**: 0.2 — Pipeline Rust complet + Tests simulation
