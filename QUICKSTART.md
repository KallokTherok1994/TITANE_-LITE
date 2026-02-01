# Quick Start - TITANE (5 minutes)

**Goal:** Get TITANE running on your machine in under 5 minutes.

---

## Prerequisites

- **Node.js:** 18.19.0 or higher (LTS)
- **Rust:** 1.83.0 or higher (for desktop)
- **pnpm:** 9.0.0+ (`npm install -g pnpm`)
- **Git:** 2.40.0 or higher

**Check versions:**
```bash
node --version    # v18.19.0+
pnpm --version    # 9.0.0+
rustc --version   # 1.83.0+
```

---

## Step 1: Clone Repository (1 min)

```bash
git clone https://github.com/titane/titane-lite.git
cd titane-lite
```

---

## Step 2: Install Dependencies (2 min)

```bash
pnpm install
```

This installs:
- React, Vite, TypeScript (frontend)
- Tauri, Rust (desktop runtime)
- All development tools

**Note:** First install may take 2-3 minutes.

---

## Step 3: Run Development (1 min)

### Option A: Desktop (Tauri)
```bash
pnpm run dev:tauri
```

Desktop app opens automatically:
- 🖥️ Native window
- 🔥 Hot reload on code changes
- 🐛 Developer tools available

### Option B: Web (Vite)
```bash
pnpm run dev
```

Opens in browser:
- 🌐 http://localhost:5173
- 🔥 Instant refresh
- 📱 Mobile preview

---

## Step 4: Try It Out (1 min)

Once app opens:

1. **Type a question:**
   ```
   What is the capital of France?
   ```

2. **Press Enter** → AI responds

3. **Create conversation:**
   - Click "New Chat"
   - Start asking questions
   - Responses saved locally

4. **Test offline:**
   - Disable WiFi/connection
   - App still works! ✨

---

## Common Commands

```bash
# Development
pnpm run dev:tauri          # Desktop dev mode
pnpm run dev                # Web dev mode

# Testing
pnpm run test               # Run all tests
pnpm run test --ui          # Test UI dashboard
pnpm run test:coverage      # Coverage report

# Code Quality
pnpm run lint               # Check for errors
pnpm run lint:fix           # Fix auto-fixable
pnpm run format             # Format code

# Production
pnpm run build              # Full build
pnpm run build:tauri        # Desktop only
pnpm run build:web          # Web only

# Type Checking
pnpm run typecheck          # TypeScript check
pnpm run tsc                # Compiler check
```

---

## Troubleshooting

### "pnpm install" fails
```bash
# Clear cache
pnpm store prune
pnpm install
```

### Tauri window won't open
```bash
# Rebuild Rust
cd src-tauri
cargo clean
cargo build
cd ..
pnpm run dev:tauri
```

### Port 5173 already in use
```bash
# Use different port
pnpm run dev -- --port 3000
```

### WebSocket connection error
This is normal on first start. Reload the page:
- Web: F5
- Desktop: Cmd+R (Mac) or Ctrl+R (Windows/Linux)

---

## Next Steps

After Quick Start:

1. **Read Documentation:**
   - [README.md](./README.md) - Full overview
   - [ARCHITECTURE.md](./ARCHITECTURE.md) - System design
   - [CONTRIBUTING.md](./CONTRIBUTING.md) - How to contribute

2. **Explore Code:**
   - `src/` - Frontend React code
   - `src-tauri/` - Desktop backend (Rust)
   - `src/types/` - TypeScript interfaces
   - `src/engines/` - Business logic

3. **Join Community:**
   - GitHub Issues - Report bugs
   - GitHub Discussions - Ask questions
   - Contribute code - Make PRs

---

## Pro Tips

### Enable Developer Tools
```bash
# In development
F12 or Cmd+Option+I (Mac)
```

### Hot Module Replacement (HMR)
- Changes apply instantly
- No full reload needed
- Perfect for iterating

### Local AI Model
TITANE can use local LLMs:
```bash
# Install Ollama (https://ollama.ai)
ollama pull llama2
# TITANE automatically detects
```

### Dark Mode
Click moon icon (top right) to toggle themes

---

## Performance Check

Once running, verify performance:

```bash
# Open DevTools (F12)
# Go to Lighthouse tab
# Run audit
# Target: 95+ score ✅
```

Current targets (v38.0.0):
- LCP (Largest Contentful Paint): < 1.2s
- TTI (Time to Interactive): < 1.8s
- CLS (Cumulative Layout Shift): < 0.01
- Lighthouse: 96/100

---

## Need Help?

- 📖 [Full Documentation](./README.md)
- 🏗️ [Architecture Guide](./ARCHITECTURE.md)
- 🤝 [Contributing Guide](./CONTRIBUTING.md)
- 💬 [GitHub Discussions](https://github.com/titane/titane-lite/discussions)
- 📧 team@titane.dev

---

**You're all set! Happy coding! 🚀**

*Built with ❤️ by the TITANE team*
