# PHASE 3 — ASSIMILATION GOVERNANCE

**Date**: 2026-02-07  
**Version**: v27.4.1  
**Phase**: 3/8 (Post Phases 1-2)  
**Objectif**: Valider que chaque appel provider externe crée assets locaux (Skills/Corpus/Tests)

---

## 📋 RAPPEL LOI #7 — Assimilation Mandatory

**Loi Constitutionnelle #7** (selon ULTRA SUPER PROMPT) :

> Every external API call MUST produce ≥1 local asset (skill/corpus/test)  
> - Providers are optional accelerators never required  
> - Captured external responses → local skills (assimilation)  
> - Debt tracking: if online without capture → technical debt increment

**Garanties Requises** :
- ✅ Chaque appel Gemini/OpenAI/Claude → skill artifact créé
- ✅ Skill artifact validé avant enregistrement (reject si tests fail)
- ✅ Prochaine requête similaire → utilise skill (offline, zero network)
- ✅ Debt tracking : compteur si appel online sans capture

**Bénéfices** :
- Amélioration continue offline capability
- Déterminisme progressif (skills > LLM probabiliste)
- Réduction coûts API (re-use au lieu de re-query)

---

## 🔍 AUDIT ACTUEL — Systèmes d'Assimilation Découverts

### Système 1 : AssimilationService (Ring 3) ✅

**Fichier** : `src/services/cognitive/AssimilationService.ts` (451 lignes)

**Architecture** :
```typescript
export class AssimilationService {
  private static instance: AssimilationService | null = null;
  private skillsCreated: number = 0;
  private skillsRejected: number = 0;
  private learningHistory: SkillArtifact[] = [];
  
  static getInstance(): AssimilationService;
  
  async assimilateResponse(
    originalPrompt: string,
    response: ChatResult,
    provider: string,
    confidence: number = 0.8
  ): Promise<SkillArtifact | null>;
}
```

**Flow Détaillé** :
```
1. VALIDATE INPUT
   ├─ Check response.ok === true
   ├─ Check content non-empty
   └─ Skip if error response
   
2. EXTRACT INTENT & DOMAIN
   ├─ Intent: explanation_request | help_request | retrieval_request | generation_request | general_inquiry
   └─ Domain: memory | system | learning | offline | general
   
3. GENERATE SELF-TEST CASES
   ├─ Create test variations of prompt
   ├─ Expected output = original response
   └─ Test cases = Array<{ input, expectedOutput }>
   
4. VALIDATE WITH LOCAL TESTS
   ├─ Run tests offline
   ├─ Measure similarity score (expected vs. actual)
   └─ Reject if < threshold (anti-cognitive debt)
   
5. CREATE SKILL ARTIFACT
   ├─ Generate skillId = `${intent}_${domain}_${timestamp}`
   ├─ Artifact = { id, intent, domain, originalQuestion, response, provider, confidence, testCases, testsPassed, testsFailed }
   └─ Save metadata
   
6. REGISTER IN SKILL REGISTRY
   ├─ Call getSkillRegistry().register(artifact)
   ├─ Increment skillsCreated counter
   └─ Add to learningHistory
```

**Méthodes Auxiliaires** :
```typescript
private extractIntent(prompt: string): string
  // Heuristic: keywords → intent category
  
private extractDomain(prompt: string): string
  // Heuristic: keywords → domain category
  
private generateTestCases(prompt, response): TestCase[]
  // Create ~3-5 test variations
  
private async validateSkillArtifact(testCases, response): ValidationResult
  // Run tests, measure pass/fail
  
private generateSkillId(intent, domain): string
  // Format: ${intent}_${domain}_${timestamp}
```

**Metrics Tracked** :
```typescript
export interface AssimilationMetrics {
  totalAttempts: number;       // assimilateResponse calls
  successfulSkills: number;    // skills created
  rejectedSkills: number;      // tests failed
  avgTestsPassed: number;      // quality metric
  learningRate: number;        // success / attempts
  datasetSize: number;         // total artifacts
}
```

**Status** : ✅ **SERVICE COMPLET** — Singleton, tests validation, metrics tracking

---

### Système 2 : AssimilationEngine (Ring 2-3) ✅

**Fichier** : `src/engines/assimilation/AssimilationEngine.ts` (751 lignes)

**Architecture** :
```typescript
export class AssimilationEngine {
  private config: AssimilationEngineConfig;
  private session: AssimilationSession;
  private skillEngine = initializeSkillEngine();
  
  // STEP 1: Record online response
  record(prompt, response, provider, modelVersion?): AssimilationRecord;
  
  // STEP 2: Compile Record → Skill/Corpus
  async compile(recordId): Promise<CompilationResult>;
  
  // STEP 3: Test offline reproduction
  async test(compilation): Promise<TestResult>;
  
  // STEP 4: Approve (user or auto)
  async approve(compilationId, userNotes?, userScore?): Promise<void>;
  
  // STEP 5: Rollback if quality degrades
  async rollback(sessionIdOrVersion): Promise<void>;
}
```

**Configuration** :
```typescript
interface AssimilationEngineConfig {
  enabled: boolean;
  autoApprove: boolean;              // Auto si quality high
  similarityThreshold: number;        // Min 0.75 (offline similarity)
  qualityThreshold: number;           // Min 0.90 (quality preservation)
  maxRecordsPerSession: number;       // Default 100
  recordMetadataDepth: 'basic' | 'detailed' | 'comprehensive';
  testBeforeApproval: boolean;        // Default true
}
```

**Session Tracking** :
```typescript
interface AssimilationSession {
  sessionId: string;
  startedAt: number;
  totalRecorded: number;
  totalCompiled: number;
  totalTested: number;
  totalApproved: number;
  records: AssimilationRecord[];
  compilations: CompilationResult[];
  tests: TestResult[];
  active: boolean;
  rollbackVersion?: string;
}
```

**Record Metadata** :
```typescript
interface AssimilationRecord {
  id: string;
  recordedAt: number;
  provider: 'gemini' | 'openai' | 'anthropic' | 'ollama';
  modelVersion?: string;
  prompt: string;
  response: string;
  
  // Quality assessment
  quality: {
    tokenCount: number;
    coherence: number;       // 0-1 (grammar, logic)
    relevance: number;       // 0-1 (answered question?)
    novelty: number;         // 0-1 (new info vs cached)
  };
  
  // Approval workflow
  userApproved: boolean;
  approvalNotes?: string;
  approvalScore?: number;    // 0-1 user rating
}
```

**Compilation Types** :
```typescript
interface CompilationResult {
  id: string;
  recordId: string;
  type: 'skill' | 'corpus' | 'fact';
  
  // Generated artifacts
  skill?: SkillArtifact;
  corpusEntry?: CorpusEntry;
  
  // Quality metrics
  quality: {
    offlineReproducibility: number;  // Can offline reproduce?
    similarityScore: number;          // Cosine similarity
    confidenceScore: number;          // Overall confidence
  };
  
  status: 'draft' | 'testing' | 'approved' | 'rejected' | 'rolled_back';
  errors?: string[];
}
```

**Test Result** :
```typescript
interface TestResult {
  compilationId: string;
  prompt: string;
  
  // Original
  originalResponse: string;
  originalProvider: string;
  originalQuality: number;
  
  // Offline reproduction
  offlineResponse: string;
  offlineLatencyMs: number;
  
  // Comparison
  similarityScore: number;        // Cosine similarity
  qualityPreserved: boolean;      // ≥ 90% original quality?
  requiresApproval: boolean;      // User review needed?
  
  passed: boolean;
  testedAt: number;
}
```

**Status** : ✅ **ENGINE COMPLET** — Pipeline complet (Record → Compile → Test → Approve → Rollback)

---

## 🚨 PROBLÈME CRITIQUE — Assimilation NON ACTIVÉE ❌

### Audit d'Intégration

**Recherche** : `assimilateResponse(` | `record(` dans codebase

**Résultats** : 3 matches

1. **`AssimilationService.ts` ligne 432** (test mock) :
```typescript
const service = getAssimilationService();
// Test example only (not production call)
```

2. **`ProviderRouter_Ring3.ts` ligne 528** (commentaire) :
```typescript
// Line 528 (in route() method comments):
'Online → offline learning (via AssimilationService)',
```

**AUCUN APPEL PRODUCTION TROUVÉ** ❌

---

### Test d'Intégration Manquant

**Code Actuel** (`ProviderRouter_Ring3.ts`) :
```typescript
async route(request: ChatRequest): Promise<ChatResult> {
  // Strategy selection
  const strategy = StrategySelector.decide(understanding, plan);
  
  // Execute strategy
  let result: ChatResult;
  switch (strategy.type) {
    case 'skill':
      result = await this.skillEngine.execute(strategy.skillId);
      break;
    case 'retrieval':
      result = await this.retrievalEngine.search(strategy.query);
      break;
    case 'llm':
      result = await this.providerClient.query(request);
      // ❌ MANQUE: assimilationService.assimilateResponse() call
      break;
    // ...
  }
  
  return ResponseComposer.composeResponse(result, understanding, plan);
}
```

**Code Attendu** :
```typescript
case 'llm':
  result = await this.providerClient.query(request);
  
  // ✅ ASSIMILATION APRÈS REQUÊTE ONLINE
  if (result.ok) {
    const assimilationService = getAssimilationService();
    await assimilationService.assimilateResponse(
      request.message,
      result,
      result.metadata.providerUsed,
      result.metadata.confidenceScore
    );
  }
  break;
```

---

## 📊 ANALYSE IMPACT

### Situation Actuelle ❌

**Flow Réel** :
```
User Message
  ↓
ProviderRouter.route()
  ↓
Online Provider (Gemini/OpenAI)
  ↓
ChatResult returned
  ↓
Response displayed
  ❌ NO ASSIMILATION
  ❌ NO SKILL CREATED
  ❌ NEXT SAME QUERY → ONLINE AGAIN
```

**Metrics Réelles** :
- ✅ Services existent (AssimilationService + AssimilationEngine)
- ❌ `skillsCreated = 0` (jamais appelé)
- ❌ `learningHistory = []` (vide)
- ❌ `totalRecorded = 0` (aucun record)

---

### Situation Requise ✅

**Flow Attendu** :
```
User Message
  ↓
ProviderRouter.route()
  ↓
Online Provider (Gemini/OpenAI)
  ↓
ChatResult returned
  ↓
✅ AssimilationService.assimilateResponse()
  ├─ Validate response
  ├─ Generate test cases
  ├─ Run offline tests
  ├─ Create SkillArtifact (if tests pass)
  └─ Register in SkillRegistry
  ↓
Response displayed
  
NEXT SAME QUERY:
  ↓
ProviderRouter.route()
  ↓
✅ SkillEngine.execute() (offline, instant)
  ↓
ChatResult returned (OFFLINE)
```

**Metrics Attendues** :
- Day 1: 50 queries → 30 skills created (60% assimilation rate)
- Day 7: 200 queries → 80% offline (skills + retrieval)
- Day 30: 95% offline (comprehensive skill coverage)

---

## 🔧 PLAN D'IMPLÉMENTATION PHASE 3

### Étape 3.1: Activer Assimilation dans ProviderRouter ✅

**Modifier** : `src/services/ai/ProviderRouter_Ring3.ts`

```typescript
import { getAssimilationService } from '@/services/cognitive/AssimilationService';

export class ProviderRouter {
  private assimilationService = getAssimilationService();
  
  async route(request: ChatRequest): Promise<ChatResult> {
    // ... strategy selection ...
    
    let result: ChatResult;
    let usedOnlineProvider = false;
    let onlineProvider: string | null = null;
    
    switch (strategy.type) {
      case 'skill':
        result = await this.skillEngine.execute(strategy.skillId, request);
        break;
        
      case 'retrieval':
        result = await this.retrievalEngine.search(strategy.query);
        break;
        
      case 'template':
        result = await this.templateEngine.render(strategy.templateId, request);
        break;
        
      case 'local_llm':
        result = await this.ollamaClient.query(request);
        break;
        
      case 'online':
        // ✅ Mark as online provider usage
        usedOnlineProvider = true;
        onlineProvider = strategy.provider;
        
        result = await this.providerClient.query(request);
        break;
        
      case 'mua':
        result = this.generateMinimumUsefulAnswer(understanding, plan);
        break;
    }
    
    // ═════════════════════════════════════════════════════════════
    // ✅ ASSIMILATION: Capture online response → create skill
    // ═════════════════════════════════════════════════════════════
    if (usedOnlineProvider && result.ok) {
      // Async fire-and-forget (don't block response)
      this.assimilationService.assimilateResponse(
        request.message,
        result,
        onlineProvider || 'unknown',
        result.metadata?.confidenceScore || 0.8
      ).catch(error => {
        console.warn('[ProviderRouter] Assimilation failed (non-blocking):', error);
      });
    }
    
    return ResponseComposer.composeResponse(result, understanding, plan);
  }
}
```

**Avantages** :
- ✅ Non-blocking (fire-and-forget)
- ✅ Error non-fatal (warn only)
- ✅ Activé seulement si online provider
- ✅ Passe confidence score metadata

---

### Étape 3.2: Debt Tracking (Compteur Appels Sans Capture) 🔧

**Créer** : `src/services/cognitive/TechnicalDebtTracker.ts`

```typescript
export interface TechnicalDebt {
  totalOnlineCalls: number;
  capturedCalls: number;
  uncapturedCalls: number;      // Debt
  captureRate: number;           // %
  debt: {
    skillsNotCreated: number;    // Should have been created
    corpusNotEnriched: number;   // Could enrich corpus
    testsNotValidated: number;   // Could have tests
  };
}

export class TechnicalDebtTracker {
  private debt: TechnicalDebt = {
    totalOnlineCalls: 0,
    capturedCalls: 0,
    uncapturedCalls: 0,
    captureRate: 0,
    debt: {
      skillsNotCreated: 0,
      corpusNotEnriched: 0,
      testsNotValidated: 0,
    }
  };
  
  recordOnlineCall(): void {
    this.debt.totalOnlineCalls++;
  }
  
  recordCapture(type: 'skill' | 'corpus' | 'test'): void {
    this.debt.capturedCalls++;
    this.updateDebt();
  }
  
  recordSkipCapture(reason: string): void {
    this.debt.uncapturedCalls++;
    this.debt.debt.skillsNotCreated++;
    console.warn(`[TechnicalDebt] ⚠️ Online call not captured: ${reason}`);
    this.updateDebt();
  }
  
  private updateDebt(): void {
    if (this.debt.totalOnlineCalls > 0) {
      this.debt.captureRate = 
        this.debt.capturedCalls / this.debt.totalOnlineCalls;
    }
  }
  
  getMetrics(): TechnicalDebt {
    return { ...this.debt };
  }
  
  reset(): void {
    this.debt = {
      totalOnlineCalls: 0,
      capturedCalls: 0,
      uncapturedCalls: 0,
      captureRate: 0,
      debt: {
        skillsNotCreated: 0,
        corpusNotEnriched: 0,
        testsNotValidated: 0,
      }
    };
  }
}
```

**Usage** :
```typescript
// In ProviderRouter
if (usedOnlineProvider) {
  debtTracker.recordOnlineCall();
  
  if (result.ok) {
    try {
      await assimilationService.assimilateResponse(...);
      debtTracker.recordCapture('skill');
    } catch (error) {
      debtTracker.recordSkipCapture(`assimilation_failed: ${error}`);
    }
  } else {
    debtTracker.recordSkipCapture('response_not_ok');
  }
}
```

---

### Étape 3.3: Dashboard Assimilation (Optionnel) 📊

**Créer** : `src/components/admin/AssimilationDashboard.tsx`

```typescript
export function AssimilationDashboard() {
  const [metrics, setMetrics] = useState<AssimilationMetrics | null>(null);
  
  useEffect(() => {
    const service = getAssimilationService();
    setMetrics(service.getMetrics());
  }, []);
  
  return (
    <div className="assimilation-dashboard">
      <h2>📚 Assimilation Status</h2>
      
      <div className="metrics-grid">
        <MetricCard 
          title="Skills Created" 
          value={metrics?.successfulSkills} 
          total={metrics?.totalAttempts}
        />
        
        <MetricCard 
          title="Capture Rate" 
          value={`${(metrics?.learningRate * 100).toFixed(1)}%`}
        />
        
        <MetricCard 
          title="Dataset Size" 
          value={metrics?.datasetSize}
        />
      </div>
      
      <div className="history">
        <h3>Recent Assimilations</h3>
        {/* Afficher learningHistory */}
      </div>
    </div>
  );
}
```

---

## 🎯 GATE_3 — CRITÈRES DE VALIDATION

### Critère 1: Every Online Call → Assimilation Attempt ✅

**Test** :
1. Envoyer 10 requêtes nécessitant provider online
2. Vérifier `assimilationService.getMetrics().totalAttempts === 10`

**Validation** :
```typescript
const metrics = getAssimilationService().getMetrics();
assert.equal(metrics.totalAttempts, 10, 'All online calls attempted assimilation');
```

---

### Critère 2: Validation Tests Pass → Skill Created ✅

**Test** :
1. Assimilation tentée
2. Si tests passed → skill créé
3. Si tests failed → skill rejected

**Validation** :
```typescript
const metrics = getAssimilationService().getMetrics();
assert.ok(metrics.successfulSkills > 0, 'At least 1 skill created');
assert.ok(metrics.successfulSkills + metrics.rejectedSkills === metrics.totalAttempts);
```

---

### Critère 3: Next Similar Query → Use Skill (Offline) ✅

**Test** :
1. Query "What is photosynthesis?" → Online → Skill created
2. Query "What is photosynthesis?" again
3. Router should use skill (offline, <50ms)

**Validation** :
```typescript
const result1 = await router.route({ message: 'What is photosynthesis?' });
assert.equal(result1.metadata.providerUsed, 'gemini'); // Online

// Wait for assimilation
await sleep(100);

const result2 = await router.route({ message: 'What is photosynthesis?' });
assert.equal(result2.metadata.strategy, 'skill'); // Offline!
assert.ok(result2.metadata.generationTimeMs < 50); // Fast
```

---

### Critère 4: Debt Tracking Functional ✅

**Test** :
1. Send 10 online queries
2. 8 successful assimilations
3. 2 failed (tests rejected)

**Validation** :
```typescript
const debt = debtTracker.getMetrics();
assert.equal(debt.totalOnlineCalls, 10);
assert.equal(debt.capturedCalls, 8);
assert.equal(debt.uncapturedCalls, 2);
assert.equal(debt.captureRate, 0.8); // 80%
```

---

### Critère 5: Manual Approval Workflow (Optionnel) ⚠️

**Test** :
1. Config: `autoApprove: false`
2. Assimilation creates draft skill
3. User reviews + approves
4. Skill moves to approved state

**Validation** :
```typescript
const engine = new AssimilationEngine({ autoApprove: false });
const record = engine.record('prompt', 'response', 'gemini');
const compilation = await engine.compile(record.id);
assert.equal(compilation.status, 'draft'); // Not auto-approved

await engine.approve(compilation.id, 'Looks good', 0.9);
assert.equal(compilation.status, 'approved');
```

---

## 🚦 DÉCISION GATE_3

### Status : ❌ **FAIL (Implementation Missing)**

**Raison** :
Assimilation systems complets mais **non activés** dans production flows.

**Violations Critiques** ❌ :
1. `assimilateResponse()` jamais appelé production
2. `skillsCreated = 0` (services dormant)
3. Online calls sans capture → zero learning
4. Debt tracking absent
5. Re-query même question → online again (no offline learning)

**Éléments Validés** ✅ :
1. AssimilationService complet avec tests validation
2. AssimilationEngine avec pipeline (Record → Compile → Test → Approve)
3. Quality gates (similarityThreshold, qualityThreshold)
4. Rollback capability
5. Metric tracking infrastructure

---

## 📝 ACTIONS REQUISES POUR GATE_3 PASS

### Actions Bloquantes (Phase 3.1) 🔴

1. **Activer assimilation dans ProviderRouter** :
   - Ajouter appel `assimilationService.assimilateResponse()` après chaque réponse online
   - Mode fire-and-forget (non-blocking)

2. **Tests d'intégration** :
   - Test: online call → skill créé
   - Test: re-query → skill utilisé (offline)

### Actions Recommandées (Phase 3.2) 🟡

3. **Debt tracking** :
   - Créer `TechnicalDebtTracker`
   - Enregistrer capture rate

4. **Dashboard assimilation** :
   - Afficher metrics (skills créés, capture rate)
   - Optionnel mais utile pour observability

---

## 📊 RÉSUMÉ PHASE 3

**Ce qui existe** ✅ :
- AssimilationService complet (tests + validation)
- AssimilationEngine (Record → Compile → Test → Approve)
- Quality gates anti-cognitive-debt
- Metrics tracking infrastructure

**Ce qui manque** ❌ :
- Activation dans ProviderRouter
- Appel automatique post-online-query
- Debt tracking compteur
- Tests E2E assimilation

**Impact Global** :
- 🔴 **VIOLATION LOI #7** — Assimilation non activée
- 🔴 **ZERO LEARNING ACTUEL** — Skills créés = 0
- 🔴 **RE-QUERY MÊME PROMPT** → Online à chaque fois (waste API quota)
- 🟡 **POTENTIAL ÉNORME** — Infrastructure complète mais dormante

**Prochaine Étape** :
- **Phase 4** (Parallèle) : UI Chat Watchdog
- **OU Phase 3.1** (Implementation) : Activer assimilation production

---

**Document Version**: v1.0  
**Status**: GATE_3 FAIL (assimilation non activée)  
**Prochaine Phase**: Phase 4 (UI Watchdog) OU Phase 3.1 (Activer assimilation)
