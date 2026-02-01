# TITANE Architecture Documentation

**Version:** 38.0.0 | **Last Updated:** February 1, 2026

---

## Overview: 4-Ring Architecture Model

TITANE follows a strictly enforced **4-ring architecture** pattern to maintain code clarity, testability, and maintainability as the codebase grows.

```
┌─────────────────────────────────────────┐
│   RING 4: UI/OS Layer (React + Tauri)   │
│  Unrestricted access to all rings ↓    │
├─────────────────────────────────────────┤
│   RING 3: Services (I/O Orchestration)  │
│  Import: Rings 1-2 only ↓              │
├─────────────────────────────────────────┤
│   RING 2: Engines (Business Logic)      │
│  9 Cognitive Moteurs ↓                 │
│  Import: Ring 1 only ↓                 │
├─────────────────────────────────────────┤
│   RING 1: Core (Types & Constants)      │
│  Zero external imports ↓               │
│  Shared across system ↓               │
└─────────────────────────────────────────┘
```

### Key Rule
**Inner rings can NEVER import outer rings.**

This prevents circular dependencies and maintains clean code flow.

---

## Ring 1: Core (Zero Imports)

### Purpose
Foundation types, constants, and interfaces shared across the entire system.

### Contains
- TypeScript interfaces (`.types.ts`)
- Constants (`DEFAULTS.ts`, `ERRORS.ts`)
- Enums (all shared enums)
- Utility types
- String literals and configs

### Example Files
```
src/types/
├─ chat.types.ts          (Chat message types)
├─ user.types.ts          (User profile types)
├─ engine.types.ts        (Engine interface specs)
└─ index.ts               (Barrel export)

src/constants/
├─ DEFAULT_MODELS.ts
├─ ERROR_MESSAGES.ts
├─ FEATURE_FLAGS.ts
└─ index.ts
```

### Rules
✅ Only TypeScript types/interfaces  
✅ No imports from other rings  
✅ Can be imported by all rings  
❌ No business logic  
❌ No external dependencies  
❌ No React components  

---

## Ring 2: Engines (Business Logic)

### Purpose
9 cognitive "moteurs" implementing TITANE's AI and reasoning capabilities.

### The 9 Moteurs
```
1. ChatEngine          - Message processing & routing
2. ReasoningEngine     - Logical deduction
3. MemoryEngine        - Context & history management
4. CreativityEngine    - Creative generation
5. AnalysisEngine      - Data analysis & patterns
6. PlanningEngine      - Task planning & execution
7. OptimizationEngine  - Performance tuning
8. SecurityEngine      - Privacy & safety
9. IntegrationEngine   - Multi-source synthesis
```

### File Structure
```
src/engines/
├─ ChatEngine.ts
├─ ReasoningEngine.ts
├─ MemoryEngine.ts
├─ CreativityEngine.ts
├─ AnalysisEngine.ts
├─ PlanningEngine.ts
├─ OptimizationEngine.ts
├─ SecurityEngine.ts
├─ IntegrationEngine.ts
└─ index.ts (barrel export)
```

### Rules
✅ Import Ring 1 (types/constants)  
✅ Pure functions where possible  
✅ Export well-defined interfaces  
✅ No React dependencies  
✅ Fully testable in isolation  
❌ No Service imports  
❌ No UI components  
❌ No direct database access  

### Example (ChatEngine)
```typescript
// src/engines/ChatEngine.ts
import type { Message, ConversationContext } from '@/types';

export class ChatEngine {
  async processMessage(
    text: string,
    context: ConversationContext
  ): Promise<Message> {
    // Process message using only Ring 1 types
    // No Ring 3/4 dependencies
  }
}
```

---

## Ring 3: Services (I/O Orchestration)

### Purpose
Manages I/O operations: database, APIs, external services, file system.

### Contains
```
src/services/
├─ chat/
│  ├─ ChatKernel.ts           (Unified chat processing)
│  ├─ ConversationStore.ts    (Persistence)
│  └─ index.ts
│
├─ ai/
│  ├─ AIKernel.ts             (Model routing)
│  ├─ TransformersAdapter.ts  (LLM integration)
│  └─ index.ts
│
├─ storage/
│  ├─ LocalStorageService.ts
│  ├─ IndexedDBService.ts
│  └─ index.ts
│
├─ memory/
│  ├─ MemoryManager.ts        (Context management)
│  ├─ ConversationHistory.ts
│  └─ index.ts
│
└─ unified/
   ├─ OrchestrationService.ts (Coordinates all engines)
   └─ index.ts
```

### Rules
✅ Import Rings 1-2 (types + engines)  
✅ Handle all I/O operations  
✅ Abstract storage implementation  
✅ Error handling & retries  
❌ No React components  
❌ No UI logic  
❌ Don't bypass engines  

### Example (ChatKernel)
```typescript
// src/services/chat/ChatKernel.ts
import { ChatEngine } from '@/engines';
import type { Message, ConversationContext } from '@/types';

export class ChatKernel {
  private engine = new ChatEngine();
  
  async processAndStore(text: string): Promise<Message> {
    const message = await this.engine.processMessage(text);
    await this.store(message);  // Persist
    return message;
  }
}
```

---

## Ring 4: UI/OS (React + Tauri)

### Purpose
User interface and operating system integration (desktop/mobile).

### Contains
```
src/components/
├─ chat/
│  ├─ ChatWindow.tsx
│  ├─ MessageCell.tsx
│  ├─ ChatBubble.tsx
│  └─ index.ts
│
├─ dashboard/
│  ├─ Dashboard.tsx
│  ├─ Widgets/
│  └─ index.ts
│
└─ settings/
   ├─ SettingsPanel.tsx
   └─ index.ts

src/hooks/
├─ useChat.ts
├─ useMemory.ts
├─ useSettings.ts
└─ index.ts

src-tauri/
├─ src/
│  ├─ main.rs
│  ├─ menu.rs
│  └─ commands/
└─ Cargo.toml
```

### Rules
✅ Can import all rings (1-3)  
✅ React components & hooks  
✅ Tauri backend integration  
✅ UI state management  
✅ Event handling  

### Example (ChatWindow.tsx)
```typescript
// src/components/chat/ChatWindow.tsx
import { ChatKernel } from '@/services';
import type { Message } from '@/types';
import { useChat } from '@/hooks';

export function ChatWindow() {
  const { messages, sendMessage } = useChat();
  
  return (
    <div className="chat-window">
      {messages.map(msg => (
        <MessageCell key={msg.id} message={msg} />
      ))}
    </div>
  );
}
```

---

## Technology Stack

### Frontend
| Library | Version | Purpose |
|---------|---------|---------|
| React | 18.3.1 | UI framework |
| Vite | 6.0.5 | Build tool |
| TypeScript | 5.7.3 | Type safety |
| Zustand | 5.0.2 | State management |
| Tailwind CSS | 3.3.0 | Styling |

### Backend (Desktop)
| Library | Version | Purpose |
|---------|---------|---------|
| Tauri | 2.2.0 | Desktop runtime |
| Rust | 1.83 | System language |
| better-sqlite3 | Latest | Local database |
| serde | Latest | Serialization |

### AI/ML
| Library | Version | Purpose |
|---------|---------|---------|
| @xenova/transformers | 2.17.2 | On-device models |
| ONNX Runtime | Latest | Model inference |

### Development
| Tool | Version | Purpose |
|------|---------|---------|
| pnpm | 9.0+ | Package manager |
| Vitest | 4.0+ | Testing |
| ESLint | 8.0+ | Linting |
| Prettier | 3.0+ | Formatting |

---

## File Structure

```
titane-lite/
├─ src/                          (TypeScript frontend)
│  ├─ types/                     (Ring 1: Interfaces)
│  ├─ constants/                 (Ring 1: Shared constants)
│  ├─ engines/                   (Ring 2: 9 Moteurs)
│  ├─ services/                  (Ring 3: I/O orchestration)
│  ├─ components/                (Ring 4: React UI)
│  ├─ hooks/                     (Ring 4: Custom hooks)
│  ├─ utils/                     (Helpers, Ring 1)
│  ├─ App.tsx                    (Entry point)
│  ├─ main.tsx                   (React entry)
│  └─ index.css                  (Global styles)
│
├─ src-tauri/                    (Rust backend)
│  ├─ src/
│  │  ├─ main.rs                 (Tauri entry)
│  │  ├─ menu.rs
│  │  └─ commands/               (IPC commands)
│  ├─ Cargo.toml
│  └─ tauri.conf.json            (Config)
│
├─ public/                       (Static assets)
├─ .github/
│  ├─ archive/                   (v27-v37 legacy)
│  ├─ workflows/                 (CI/CD)
│  ├─ instructions/              (Code guidelines)
│  └─ copilot-instructions.md
│
├─ package.json                  (npm config)
├─ pnpm-lock.yaml               (Dependency lock)
├─ tsconfig.json                (TypeScript config)
├─ vite.config.ts               (Vite config)
├─ eslint.config.js             (Linting)
├─ README.md                    (Main docs)
├─ ARCHITECTURE.md              (This file)
├─ CONTRIBUTING.md              (Dev guide)
└─ LICENSE.md                   (MIT License)
```

---

## Design Patterns

### 1. **Kernel Pattern** (Ring 2→Ring 3)
Consolidates related engines into a single service entry point.

```typescript
export class ChatKernel {
  constructor(
    private chatEngine: ChatEngine,
    private memoryEngine: MemoryEngine
  ) {}
  
  async processMessage(text: string): Promise<Message> {
    return this.chatEngine.process(text);
  }
}
```

### 2. **Factory Pattern** (Components)
Creates component variants from a template.

```typescript
export const MessageCellFactory = {
  text: (props) => <MessageCell variant="text" {...props} />,
  code: (props) => <MessageCell variant="code" {...props} />,
  image: (props) => <MessageCell variant="image" {...props} />,
};
```

### 3. **Adapter Pattern** (Services)
Adapts external APIs to internal interfaces.

```typescript
export class TransformersAdapter {
  async loadModel(modelId: string) {
    // Adapt @xenova API to our interface
  }
}
```

### 4. **Observer Pattern** (State)
Zustand stores for reactive updates.

```typescript
export const useChatStore = create((set) => ({
  messages: [],
  addMessage: (msg) => set(state => ({
    messages: [...state.messages, msg]
  }))
}));
```

---

## Code Quality Standards

### TypeScript
- ✅ `strict: true` in tsconfig.json
- ✅ No `any` types allowed
- ✅ All functions typed
- ✅ Interface over implementation

### Testing
- ✅ Engines: 100% unit test coverage
- ✅ Services: 80%+ coverage
- ✅ Components: Integration tests
- ✅ E2E: Critical user flows

### Performance
- ✅ Code splitting by route
- ✅ Lazy load heavy components
- ✅ Bundle budget: < 5 MB
- ✅ LCP target: < 1.5s

### Security
- ✅ Input sanitization
- ✅ SQL injection prevention
- ✅ XSS protection
- ✅ CORS policy enforcement

---

## Validation Checklist

Before any PR merge, ensure:

- [ ] Code follows 4-ring architecture
- [ ] No inner→outer ring imports
- [ ] TypeScript strict mode passes
- [ ] ESLint: zero errors
- [ ] Tests: 100% for engines, 80%+ overall
- [ ] No `any` types
- [ ] Commit message follows convention
- [ ] Documentation updated

---

## Architecture Evolution

### v38.0.0 (Current)
- 4-ring model established
- 9 engines consolidated
- Services kernelized
- Performance optimized

### v39.0.0+
- Plugin system (extensible)
- Custom engine support
- Community contributions
- Advanced middleware

---

## Questions & Support

- GitHub Issues: [Report architecture problems](https://github.com/titane/titane-lite/issues)
- Architecture Discussion: [#architecture channel](https://github.com/titane/titane-lite/discussions)
- Code Review: Follow PR process in CONTRIBUTING.md

---

**Built with clarity, tested with rigor, scaled with confidence.**

*Last Updated: February 1, 2026*
