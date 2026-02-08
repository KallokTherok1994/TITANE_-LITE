# Phase 5: Analyse des Échecs Vitest — v27.4.1

**Date**: 2026-02-07  
**Baseline**: 50 fichiers échoués / 169 total (353 tests échoués / 3144 total)  
**Pass Rate**: 90.3%

---

## Problèmes Identifiés

### 1. Backend Tauri Indisponible (Criticité: 🔴 HIGH)

**Impact**: ~40 fichiers de test échouent avec `health_check` errors

**Symptômes**:
```
[Security] ✗ Response validation failed: Response is null or undefined
secureInvoke("health_check") failed: Response validation failed
Error rate: 100.00% (8/8 requests)
```

**Fichiers Affectés**:
- `src/__tests__/features/voice/VoiceControl.test.tsx` (8/8 tests failed)
- `src/__tests__/hooks/useResponsive.test.tsx` (2/7 tests failed)
- Tous les composants utilisant `HybridTTSService.checkTauriAvailable()`
- Services appelant `chatEngine.commands.healthCheck()`

**Cause Racine**:
Les tests Vitest s'exécutent dans un environnement Node.js/jsdom sans backend Tauri actif. Les appels `@tauri-apps/api/core.invoke()` échouent car aucun IPC bridge n'est disponible.

**Solutions Proposées**:

#### Solution A: Mock Global Tauri API (Recommandé ✅)
```typescript
// tests/setup/tauri-mock.ts
import { vi } from 'vitest';

// Mock @tauri-apps/api/core
vi.mock('@tauri-apps/api/core', () => ({
  invoke: vi.fn((cmd: string, args?: unknown) => {
    // Mock health_check
    if (cmd === 'health_check') {
      return Promise.resolve({ status: 'ok', timestamp: Date.now() });
    }
    // Mock other commands
    if (cmd === 'generate_response') {
      return Promise.resolve({
        content: 'Mock response',
        conversationId: args?.conversationId || 'test-convo',
        messageId: 'mock-id',
        frenchMasteryApplied: false,
        latencyMs: 50,
      });
    }
    return Promise.reject(new Error(`Unmocked Tauri command: ${cmd}`));
  }),
}));

// Mock @tauri-apps/api/event
vi.mock('@tauri-apps/api/event', () => ({
  listen: vi.fn(() => Promise.resolve(() => {})),
  emit: vi.fn(() => Promise.resolve()),
}));
```

**Intégration dans vitest.config.ts**:
```typescript
export default defineConfig({
  test: {
    setupFiles: ['./tests/setup/tauri-mock.ts'],
    environment: 'jsdom',
    // ...
  },
});
```

**Avantages**:
- ✅ Résout 40+ fichiers d'un coup
- ✅ Zéro modification du code source
- ✅ Mock centralisé et maintenable
- ✅ Tests s'exécutent sans backend Tauri

**Inconvénients**:
- ⚠️ Ne teste pas l'IPC réel (couvert par E2E WDIO)
- ⚠️ Nécessite ajout de réponses mock pour chaque commande

#### Solution B: Environment Variable Check
```typescript
// src/services/tauri/chatEngine.commands.ts
function isTauriAvailable(): boolean {
  return typeof window !== 'undefined' && 
         '__TAURI_INTERNALS__' in window &&
         import.meta.env.MODE !== 'test';
}

export async function healthCheck(): Promise<HealthCheckResponse> {
  if (!isTauriAvailable()) {
    // Retourner mock en mode test
    return { status: 'ok', timestamp: Date.now() };
  }
  return await invokeCommand<HealthCheckResponse>('health_check');
}
```

**Avantages**:
- ✅ Code de production peut détecter environnement de test
- ✅ Pas de dépendance à Vitest mock system

**Inconvénients**:
- ❌ Modifie code de production pour needs de test
- ❌ Chaque commande doit implémenter check
- ❌ Augmente complexité du code source

---

### 2. Voice Control Tests (Criticité: 🟡 MEDIUM)

**Impact**: 7 tests échoués dans `VoiceControl.test.tsx`

**Symptômes**:
- Tests timeout (voice button, listening state, recording)
- Composant dépend de `HybridTTSService` qui appelle `healthCheck()`

**Solution**: Résolu par Solution A (mock Tauri API)

---

### 3. Responsive Hook Tests (Criticité: 🟢 LOW)

**Impact**: 2 tests échoués dans `useResponsive.test.tsx`

**Tests Échoués**:
- `should update on window resize`
- `should cleanup...` (nom tronqué)

**Cause**: Probablement lié à timing issues dans jsdom window resize events

**Solution**:
```typescript
// Dans le test
it('should update on window resize', async () => {
  const { result } = renderHook(() => useResponsive());
  
  act(() => {
    window.innerWidth = 768;
    window.dispatchEvent(new Event('resize'));
  });
  
  // Attendre que le debounce/throttle se termine
  await waitFor(() => {
    expect(result.current.breakpoint).toBe('md');
  }, { timeout: 1000 });
});
```

---

## Recommandations d'Implémentation

### Phase 5.1: Mock Tauri API (Priorité 1)

**Fichiers à Créer**:
1. `tests/setup/tauri-mock.ts` — Mock global pour @tauri-apps/api
2. `tests/setup/tauri-responses.ts` — Réponses mock typées pour chaque commande

**Commandes à Mocker**:
```typescript
const MOCK_RESPONSES = {
  health_check: { status: 'ok', timestamp: Date.now() },
  generate_response: (args) => ({
    content: `Mock response to: ${args.message}`,
    conversationId: args.conversationId,
    messageId: `mock-${Date.now()}`,
    frenchMasteryApplied: false,
    latencyMs: 50,
  }),
  stream_response: (args) => ({
    /* mock stream data */
  }),
  speak_text: { success: true, duration: 1000 },
  save_memory: { success: true },
  load_memory: { conversations: [] },
  reset_memory: { success: true },
};
```

**Tests Concernés**: ~40 fichiers (résout 80% des échecs)

### Phase 5.2: Fixer Responsive Tests (Priorité 2)

**Fichier**: `src/__tests__/hooks/useResponsive.test.tsx`

**Changements**:
- Ajouter `waitFor()` pour timing issues
- Mock `window.matchMedia` si nécessaire
- Augmenter timeout pour resize events

**Tests Concernés**: 2 tests

### Phase 5.3: Validation (Priorité 3)

**Commande**: 
```bash
pnpm test 2>&1 | tee reports/vitest_after_phase5.log
```

**Objectif**: Pass rate ≥95% (cible: 160+/169 fichiers)

---

## Métriques Cibles Post-Phase 5

| Métrique | Avant | Cible | Delta |
|----------|-------|-------|-------|
| Fichiers PASS | 117/169 | 160/169 | +43 |
| Tests PASS | 2760/3144 | 3000/3144 | +240 |
| Pass Rate | 90.3% | 95.4% | +5.1% |
| Durée | 2341s | <2000s | -15% |

---

## Notes d'Implémentation

**Attention**: 
- Ne PAS modifier code source de production pour fixer tests
- Les mocks doivent être limités à `tests/setup/`
- Les tests E2E WDIO valideront l'IPC réel (pas de mock)

**Compatibilité**:
- Cette approche est standard (Tauri docs recommande mocking pour unit tests)
- Vitest supporte vi.mock() nativement
- Zéro impact sur bundle de production

**Validation**:
- Les tests doivent passer avec `NODE_ENV=test`
- Les tests doivent détecter regressions dans logique frontend
- Les tests NE doivent PAS valider IPC correctness (rôle de E2E)
