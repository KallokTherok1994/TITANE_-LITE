# 🔍 NETWORK_SURFACE.md — Dépendances Réseau & Risques (PHASE 0.2)

**Date:** 7 février 2026  
**Version:** 1.0.0  
**Scope:** Détection complète des tentatives réseau (Frontend + Backend)  
**Objective:** Valider que TITANE peut opérer en OFFLINE sans aucune tentative réseau

---

## 📊 Résumé Exécutif

| Aspect | Status | Risque | Action |
|--------|--------|--------|--------|
| **Local-first Default** | ✅ | Bas | Keep - Tauri (pas HTTP serveur) |
| **Ollama Local** | ✅ | Bas | Optional, localhost only |
| **Gemini API** | ⚠️ | Moyen | API key gated + NetworkGuard |
| **OpenAI API** | ⚠️ | Moyen | API key gated + NetworkGuard |
| **Anthropic API** | ⚠️ | Moyen | API key gated + NetworkGuard |
| **Chat Fallback** | 🔄 | Moyen | **MUST** validate offline path |

---

## 🌐 SURFACE RÉSEAU DÉTAILLÉE

### Frontend (React)

#### 1. **Chat Message Flow** (src/services/api/chat.ts)

```
USER INPUT
  ↓
ChatService.sendMessageStream()
  ↓
Tauri IPC: invoke('conversation_generate', {...})
  ↓
BACKEND (isolated)
  ↓
ChatResult (structured response)
```

**Network Path:** ❌ **NONE** (IPC is local)  
**Risk:** 🟢 Green (all async through Tauri local bridge)  

---

#### 2. **Ollama Health Check** (src/features/governance-center/hooks/useGovernance.ts)

```typescript
// Line 105-131
const loadOllamaStatus = useCallback(async () => {
  const response = await fetch(
    'http://localhost:11434/api/tags',
    { timeout: 1000 }
  );
```

**Network Endpoint:** `http://127.0.0.1:11434/api/tags`  
**Risk Level:** 🟡 **MEDIUM**
- ✅ Localhost only
- ✅ Optional (non-blocking fallback)
- ⚠️ **Problem:** Blocking fetch on governance center load
- **Action:** Wrap in try/catch with 1s timeout + optional

**MITIGATION:**
```typescript
// Current issue: fetch may hang if Ollama missing
// FIX: Add timeout + error boundary
try {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 1000);
  await fetch('http://127.0.0.1:11434/api/tags', { signal: controller.signal });
} catch (e) {
  // Graceful: Ollama unavailable, will use fallback
}
```

---

#### 3. **Gemini/OpenAI/Anthropic Status Checks** (same file, lines 76-95)

```typescript
const loadGeminiStatus = useCallback(async () => {
  const response = await governanceService.getGeminiStatus();
  // ...
```

**Network Endpoints:**
- Gemini: `https://generativelanguage.googleapis.com/v1/models`
- OpenAI: `https://api.openai.com/v1/models`
- Anthropic: `https://api.anthropic.com/v1/models` (if supported)

**Risk Level:** 🔴 **HIGH** (external network)
- ❌ External HTTPS (requires internet)
- ❌ API key required (secrets in config)
- ⚠️ No timeout visible in hook
- **Action:** **Gate behind explicit opt-in** + NetworkGuard

**MITIGATION:**
```typescript
// Only call if HYBRID/ONLINE mode explicitly enabled
if (autonomyMode !== 'OFFLINE') {
  await loadGeminiStatus(); // guarded
}
```

---

### Backend (Rust)

#### 1. **Ollama Provider** (src-tauri/src/ollama.rs)

```rust
const OLLAMA_BASE_URL: &str = "http://127.0.0.1:11434";

// Uses reqwest::Client for HTTP calls
use reqwest::{Client, StatusCode};
```

**Network Endpoint:** `http://127.0.0.1:11434/api/generate`  
**Risk Level:** 🟡 **MEDIUM**
- ✅ Localhost only
- ✅ Optional feature (graceful missing)
- ⚠️ Timeout handling required
- **Action:** Ensure timeout + fallback implemented

---

#### 2. **Gemini Provider** (src-tauri/src/gemini_provider_refactor.rs)

```rust
pub enum GeminiEndpoint {
    Api,
    // Maps to: https://generativelanguage.googleapis.com/v1/models/...
}
```

**Network Endpoint:** `https://generativelanguage.googleapis.com`  
**Risk Level:** 🔴 **CRITICAL**
- ❌ External HTTPS
- ❌ Requires API key
- ⚠️ **No visibility on gating** in refactor file
- **Action:** **MUST gate behind NetworkGuard + explicit provider selection**

---

#### 3. **Unified Memory Summarizer** (src-tauri/src/engines/unified_memory/summarizer.rs)

```rust
let client = reqwest::Client::new();

// Comments mention: Gemini, Ollama, Claude for summarization
// Provider: "Use fast model (qwen2.5:latest or gemini-1.5-flash)"
```

**Network Potential:**
- Ollama: `http://127.0.0.1:11434` ✅ (local)
- Gemini: `https://generativelanguage.googleapis.com` ❌ (external)
- Claude: `https://api.anthropic.com` ❌ (external)

**Risk Level:** 🔴 **CRITICAL**
- ⚠️ **ISSUE:** Code mentions Gemini/Claude without visible gating
- **Action:** **Verify this code is gated by AutonomyMode**

---

#### 4. **Chat Commands** (src-tauri/src/api/chat_commands.rs)

```rust
use reqwest::Client;
// Backend chat orchestration
```

**Network Intent:** Unknown (needs code review)  
**Risk Level:** 🔆 **TBD** (needs inspection)

**Action:** Review `chat_commands.rs` for network surface

---

### Security Module (src-tauri/src/ai/security.rs)

```rust
const SECURITY_ALLOWLIST: &[&str] = &[
    "https://generativelanguage.googleapis.com",   // Gemini
    "http://localhost:11434",                       // Ollama
    "http://127.0.0.1:11434",
];

pub fn validate_endpoint(endpoint: &str) -> Result<(), SecurityError> {
    // Validates only allowlisted endpoints can be called
}
```

**Assessment:** ✅ **GOOD**
- Endpoint validation is present
- Whitelist approach is correct
- ⚠️ **But:** Gemini is allowlisted (external)

---

## 🎯 NETWORK SURFACE SUMMARY BY AUTONOMY MODE

### OFFLINE Mode (Zero Network)

```
SHOULD:
- ✅ No fetches to external endpoints
- ✅ No reqwest calls to internet
- ✅ Tauri IPC only (local)
- ✅ OfflineFallbackEngine responses

MUST NOT:
- ❌ Attempt http://localhost:11434 (even local)
- ❌ Attempt external Gemini/OpenAI/Anthropic
- ❌ DNS queries
- ❌ TCP SYN to non-localhost
```

**Proof Required:**
- NetworkGuard logs: `network_attempted=false`
- strace/tcpdump: Zero network syscalls
- 30+ prompts → All responses offline

---

### LOCAL_LLM Mode (Ollama Optional)

```
ALLOWED:
- ✅ http://127.0.0.1:11434 (Ollama if available)
- ✅ Graceful timeout (not blocking)
- ✅ Fallback to OFFLINE if unavailable
```

**Proof Required:**
- ~5 prompts test Ollama availability
- If present: use it
- If absent: seamless fallback to OFFLINE

---

### HYBRID Mode (Gemini/OpenAI with Fallback)

```
ALLOWED:
- ✅ http://127.0.0.1:11434 (Ollama first)
- ✅ Gemini/OpenAI if API key present
- ✅ Fallback to OFFLINE if network unavailable
```

**Proof Required:**
- Explicit API key check
- Timeout per provider (~5s)
- Fallback to LOCAL_LLM → OFFLINE on failure

---

### ONLINE_AUGMENTED (Any Provider)

```
ALLOWED:
- ✅ All providers (Gemini, OpenAI, Anthropic, Ollama)
- ✅ No fallback required but recommended
```

---

## 🔧 CURRENT ISSUES & FIXES

### Issue #1: Gemini Status Check May Block

**Location:** `src/features/governance-center/hooks/useGovernance.ts:76-95`

**Problem:**
```typescript
const loadGeminiStatus = useCallback(async () => {
  const response = await governanceService.getGeminiStatus();
  // ❌ No timeout, may hang if network unavailable
```

**Fix:**
```typescript
const loadGeminiStatus = useCallback(async () => {
  if (autonomyMode === 'OFFLINE') return; // Skip entirely
  
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 3000);
    const response = await governanceService.getGeminiStatus({ signal: controller.signal });
    clearTimeout(timeoutId);
    // Update state
  } catch (e) {
    // Graceful: provider unavailable
  }
}, [autonomyMode]);
```

---

### Issue #2: Summarizer May Not Be Gated

**Location:** `src-tauri/src/engines/unified_memory/summarizer.rs`

**Problem:**
```rust
// Code mentions Gemini for summarization
// No visible check: if autonomy_mode == OFFLINE, skip_ai_call()
```

**Fix:**
```rust
// Gate by AutonomyMode
match autonomy_mode {
    AutonomyMode::Offline => {
        // Use heuristic summarizer (no AI)
        summarize_heuristic(entries)
    },
    AutonomyMode::LocalLlm => {
        // Try Ollama only
        summarize_ollama(entries).await
    },
    AutonomyMode::Hybrid | AutonomyMode::OnlineAugmented => {
        // Try all providers with fallback
        summarize_ai(entries).await
    }
}
```

---

### Issue #3: Chat Service Fallback Not Explicit

**Location:** `src/services/api/chat.ts`

**Problem:**
```typescript
async sendMessageStream(...) {
  // ❌ No explicit check: if provider fails, what happens?
  // ❌ No logging of: "Falling back to OFFLINE"
}
```

**Fix:**
```typescript
async sendMessageStream(...) {
  try {
    // Try selected provider
    const response = await this.tryProvider(selectedProvider);
    return response;
  } catch (e) {
    logger.info('Provider failed, falling back to OFFLINE', { provider: selectedProvider, error: e.message });
    return this.tryOfflineFallback(); // Explicit fallback
  }
}
```

---

## ✅ ACTIONS REQUIRED (PHASE 0.2)

### Priority 1 (Blocking GATE)

- [ ] **Add NetworkGuard service** to track `network_attempted` metric
- [ ] **Test OFFLINE mode:** 30 prompts → 30 responses without network
- [ ] **Validate OfflineFallbackEngine** produces non-empty results
- [ ] **Gate Gemini/OpenAI/Anthropic** behind explicit `autonomyMode` check
- [ ] **Add timeout to Ollama/Gemini/OpenAI** checks (max 3-5s)

### Priority 2 (Hardening)

- [ ] **Explicit fallback logging** in ChatService
- [ ] **Summarizer audit:** verify AutonomyMode gating
- [ ] **Network error handling:** no "timeout" → no hang, graceful fallback
- [ ] **Proof generation:** logs + metrics for offline validation

### Priority 3 (Documentation)

- [ ] **docs/autonomy/NETWORK_GUARD.md** — Implementation guide
- [ ] **docs/autonomy/OFFLINE_PROOF.md** — Validation checklist

---

## 📋 NETWORK SURFACE INVENTORY

| Service | Endpoint | Type | Risk | Gating | Timeout |
|---------|----------|------|------|--------|---------|
| **Ollama** | `http://127.0.0.1:11434` | Local | 🟡 Medium | Optional | 1-3s |
| **Gemini** | `https://generativelanguage.googleapis.com` | External | 🔴 High | ⚠️ TBD | ❌ None |
| **OpenAI** | `https://api.openai.com` | External | 🔴 High | ⚠️ TBD | ❌ None |
| **Anthropic** | `https://api.anthropic.com` | External | 🔴 High | ⚠️ TBD | ❌ None |

---

## 🎯 GATE_P0 VALIDATION CHECKLIST

✅ = All pass  
🔄 = In progress  
❌ = Fails

- [🔄] TITANE responds without ANY provider (30 prompts test)
- [❌] Zero network attempted in OFFLINE mode
- [🔄] NetworkGuard metrics prove offline operation
- [❌] Chat service has explicit offline path
- [❌] Ollama/Gemini checks have timeouts + fallback
- [🔄] Tests prove OfflineFallbackEngine works

**Current Status:** 🔄 **PHASE 0 IN PROGRESS**

---

**Next:** Launch PHASE 1 (Types + Contracts) once GATE_P0 passes.
