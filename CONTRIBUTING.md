# Contributing to TITANE

Thank you for your interest in contributing to TITANE! This guide will help you contribute effectively.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Architecture Guidelines](#architecture-guidelines)
5. [Code Standards](#code-standards)
6. [Testing Requirements](#testing-requirements)
7. [Commit Conventions](#commit-conventions)
8. [Pull Request Process](#pull-request-process)
9. [Common Workflows](#common-workflows)
10. [FAQ](#faq)

---

## Code of Conduct

- **Respectful:** Treat all contributors with respect
- **Inclusive:** Welcome people of all backgrounds
- **Constructive:** Focus on code quality, not personal criticism
- **Safe:** Report harassment to team@titane.dev

---

## Getting Started

### 1. Fork & Clone
```bash
# Fork on GitHub, then:
git clone https://github.com/YOUR_USERNAME/titane-lite.git
cd titane-lite

# Add upstream for sync
git remote add upstream https://github.com/titane/titane-lite.git
```

### 2. Create Feature Branch
```bash
# Update main first
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feat/your-feature-name
```

**Branch naming conventions:**
- `feat/` - New feature
- `fix/` - Bug fix
- `docs/` - Documentation
- `refactor/` - Code refactor
- `perf/` - Performance
- `test/` - Tests
- `chore/` - Build/tooling

### 3. Set Up Development Environment
See [QUICKSTART.md](./QUICKSTART.md) for initial setup.

---

## Development Setup

### Quick Start
```bash
pnpm install
pnpm run dev:tauri    # or pnpm run dev for web
```

### Before Every Session
```bash
# Update dependencies
pnpm install

# Run tests to ensure no breakage
pnpm run test

# Check code quality
pnpm run lint
```

### Recommended IDE Setup

**VS Code:**
```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.enablePromptUseWorkspaceTsdk": true
}
```

**Extensions:**
- ESLint
- Prettier
- Rust-analyzer
- TypeScript Vue Plugin
- Tailwind CSS IntelliSense

---

## Architecture Guidelines

TITANE uses a **4-Ring Architecture** for clean dependencies:

### Ring 1: Core (Types)
- **Location:** `src/types/`
- **Rule:** Zero imports allowed
- **Purpose:** TypeScript interfaces, shared constants
- **Example:**
  ```typescript
  export interface Message {
    id: string;
    content: string;
    role: 'user' | 'assistant';
    timestamp: Date;
  }
  ```

### Ring 2: Engines (9 Moteurs)
- **Location:** `src/engines/`
- **Rule:** Import Ring 1 only
- **Engines:**
  1. `message-engine.ts` - Message logic
  2. `chat-engine.ts` - Chat management
  3. `memory-engine.ts` - Memory/storage
  4. `ai-engine.ts` - AI integration
  5. `performance-engine.ts` - Optimization
  6. `sync-engine.ts` - Synchronization
  7. `security-engine.ts` - Encryption
  8. `offline-engine.ts` - Offline mode
  9. `telemetry-engine.ts` - Metrics

### Ring 3: Services (I/O)
- **Location:** `src/services/`
- **Rule:** Import Rings 1-2 only
- **Services:** API, database, file system

### Ring 4: UI/OS (React)
- **Location:** `src/components/`, `src/pages/`
- **Rule:** Unrestricted imports allowed
- **Purpose:** UI rendering, event handling

**CRITICAL RULE:** ⚠️ **Inner rings NEVER import outer rings** ⚠️

---

## Code Standards

### TypeScript Strict Mode
```typescript
// ✅ GOOD - explicit types
function addNumbers(a: number, b: number): number {
  return a + b;
}

// ❌ BAD - implicit any
function addNumbers(a, b) {
  return a + b;
}
```

### React Best Practices

**Functional Components:**
```typescript
// ✅ GOOD
const MessageList: React.FC<{ messages: Message[] }> = ({ messages }) => {
  return (
    <div>
      {messages.map(msg => (
        <MessageItem key={msg.id} message={msg} />
      ))}
    </div>
  );
};

// ❌ BAD - Class components (unless necessary)
class MessageList extends React.Component {
  // ...
}
```

**Hooks Usage:**
```typescript
// ✅ GOOD - custom hook
const useMessages = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  // ...
  return { messages, addMessage };
};

// ❌ BAD - logic in component
const MyComponent = () => {
  const [messages, setMessages] = useState([]);
  // 20 lines of logic...
};
```

### Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Components | PascalCase | `MessageList.tsx` |
| Functions | camelCase | `getMessages()` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRIES = 3` |
| Types | PascalCase | `interface Message {}` |
| Private vars | _camelCase | `_internalState` |
| Booleans | is/has prefix | `isLoading`, `hasError` |

### Imports Organization

```typescript
// 1. React & React-like
import React, { useState } from 'react';
import { useAtom } from 'jotai';

// 2. External libraries
import axios from 'axios';
import dayjs from 'dayjs';

// 3. Type imports
import type { Message, Chat } from '../types';

// 4. Internal modules (Ring 1)
import { CONSTANTS } from '../types/constants';

// 5. Internal services (Ring 2)
import { messageEngine } from '../engines';

// 6. Components
import { MessageItem } from './MessageItem';

// 7. Styles
import styles from './styles.module.css';
```

### Error Handling

```typescript
// ✅ GOOD - comprehensive error handling
async function fetchMessages(chatId: string): Promise<Message[]> {
  try {
    const response = await api.get(`/chats/${chatId}/messages`);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error(`API Error: ${error.response?.status}`);
      // Handle specific status codes
    } else {
      console.error('Unknown error:', error);
    }
    throw new Error('Failed to fetch messages');
  }
}

// ❌ BAD - no error handling
async function fetchMessages(chatId: string) {
  return await api.get(`/chats/${chatId}/messages`);
}
```

---

## Testing Requirements

### Unit Tests (Jest)
```bash
# Run all tests
pnpm run test

# Watch mode (while developing)
pnpm run test:watch

# Coverage report
pnpm run test:coverage
```

**Minimum coverage targets:**
- Statements: 80%
- Branches: 75%
- Functions: 80%
- Lines: 80%

**Test example:**
```typescript
describe('messageEngine', () => {
  it('should format message correctly', () => {
    const msg = messageEngine.format({
      content: 'Hello',
      role: 'user'
    });
    expect(msg).toContain('Hello');
  });

  it('should handle empty content', () => {
    expect(() => {
      messageEngine.format({ content: '', role: 'user' });
    }).toThrow('Content cannot be empty');
  });
});
```

### E2E Tests (Playwright)
```bash
# Run E2E tests
pnpm run test:e2e

# Headed mode (see browser)
pnpm run test:e2e -- --headed
```

### Type Checking
```bash
# Check TypeScript
pnpm run typecheck

# IDE will highlight errors in real-time
```

### Linting & Formatting

```bash
# Check for errors
pnpm run lint

# Fix auto-fixable errors
pnpm run lint:fix

# Format code
pnpm run format

# Full validation (pre-commit)
pnpm run validate
```

### Before Submitting PR

```bash
# Run everything
pnpm run test
pnpm run typecheck
pnpm run lint:fix
pnpm run format

# Verify no breakage
pnpm run build
```

---

## Commit Conventions

We follow **Conventional Commits** for clear commit history.

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting (no code change)
- `refactor:` Code restructure (no behavior change)
- `perf:` Performance improvement
- `test:` Test changes
- `chore:` Build/tooling

### Examples

**Good commits:**
```
feat(chat): add message retry logic

- Implement exponential backoff
- Add max retry count (3)
- Emit retry events for UI

Fixes #123
```

```
fix(memory): prevent duplicate messages in cache

The deduplication check was comparing object references
instead of message IDs. Fixed by comparing IDs.

Closes #456
```

```
docs: update contributing guide for v38
```

**Bad commits:**
```
❌ Fixed stuff
❌ updated code
❌ WIP: trying something
❌ asdf
```

---

## Pull Request Process

### 1. Create PR with Description

**PR Title:** Use conventional commit format
```
feat(chat): add message retry logic
```

**PR Description Template:**
```markdown
## Description
What does this PR do?

## Motivation
Why is this change needed?

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation

## Testing
How to test this?

## Checklist
- [ ] Tests added/updated
- [ ] Docs updated
- [ ] Lint passes
- [ ] Build succeeds
- [ ] No console errors
```

### 2. Ensure Checks Pass

All these must pass:
- ✅ TypeScript compilation
- ✅ ESLint checks
- ✅ Tests pass
- ✅ Build succeeds
- ✅ No console warnings/errors

### 3. Code Review

- Expect feedback
- Be open to suggestions
- Ask questions if unclear
- Address all comments

### 4. Approval & Merge

- Minimum 1 approval required
- CI must pass
- No conflicts with main
- Maintainer will merge

---

## Common Workflows

### Sync with Upstream
```bash
git fetch upstream
git rebase upstream/main
git push origin your-branch -f
```

### Squash Commits
```bash
# Before pushing
git rebase -i HEAD~3  # Last 3 commits

# In editor:
# pick <first>
# squash <second>
# squash <third>

git push origin your-branch -f
```

### Add Files to Last Commit
```bash
git add .
git commit --amend --no-edit
git push origin your-branch -f
```

### Debug in Development
```bash
# Desktop
# Press F12 to open DevTools

# Web
# Press F12 or right-click → Inspect

# Add breakpoints
# Or use console.log()
```

---

## FAQ

### "Tests failed in CI but pass locally"
- Node version mismatch: Use `nvm use` or match .nvmrc
- Dependency issue: Delete `pnpm-lock.yaml`, run `pnpm install` again
- Environment variable: Check `.env.example`

### "Merge conflicts in pnpm-lock.yaml"
```bash
# Don't manually edit!
rm pnpm-lock.yaml
pnpm install
```

### "How long for review?"
- Typically 24-48 hours
- Small PRs reviewed faster
- We're all volunteers ❤️

### "Can I add a new dependency?"
- First open an issue to discuss
- Check ARCHITECTURE.md for Ring compatibility
- Update package.json and pnpm-lock.yaml
- Include justification in PR

### "How do I report a security issue?"
- Don't open a public issue
- Email security@titane.dev
- Include reproduction steps

---

## Resources

- 🏗️ [ARCHITECTURE.md](./ARCHITECTURE.md) - System design
- 📖 [README.md](./README.md) - Project overview
- 🚀 [QUICKSTART.md](./QUICKSTART.md) - Get running fast
- 📚 [API Reference](./API_REFERENCE.md) - Detailed APIs

---

## Questions?

- 💬 GitHub Discussions
- 📧 team@titane.dev
- 🐛 GitHub Issues

**Thank you for contributing to TITANE! 🙏**

*Together we build the future of AI assistants.*
