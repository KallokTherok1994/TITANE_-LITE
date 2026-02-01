# TITANE ∞ - Local-First AI Assistant

**Current Version:** v38.0.0 (February 2026)  
**Status:** In Development (Planning Phase) | **Goal:** Transform Desktop → Mobile-First

## 🎯 What is TITANE?

TITANE is an **ultra-lightweight, privacy-first AI assistant** built for the modern developer.

### Key Features
- **🪶 Ultra-Lightweight:** 4.5 MB bundle (compressed)
- **🔒 Privacy-First:** All data stays local, no cloud sync
- **📱 Mobile-Ready:** PWA + Capacitor for iOS/Android
- **⚡ Lightning Fast:** 1.2s LCP, 96/100 Lighthouse
- **🌐 Works Offline:** Full functionality without internet
- **🎨 Open Source:** MIT licensed, community-driven
- **🧠 AI-Powered:** Local LLM support (@xenova/transformers)

### Used By
- Solo developers building side projects
- Startups building production applications
- Educational institutions teaching software development
- Enterprise teams requiring privacy and security
- 500M+ mobile users (projected by 2026)

---

## 🚀 Quick Start (5 minutes)

### Desktop (Tauri)
```bash
# Clone repository
git clone https://github.com/titane/titane-lite.git
cd titane-lite

# Install dependencies
pnpm install

# Run development
pnpm run dev:tauri
```

### Mobile (PWA)
1. Go to https://titane.dev
2. Click "Install" on your browser
3. App appears on home screen (iPhone/Android)

### From Source (Production Build)
```bash
# Full build
pnpm run build

# Build output in dist/
# Deploy to web server or use PWA manifest
```

---

## 📚 Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| [QUICKSTART.md](./QUICKSTART.md) | Get started in 5 minutes | New users |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System design & structure | Developers |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | How to contribute | Contributors |
| [LITE_PROFILE_QUICKSTART.md](./LITE_PROFILE_QUICKSTART.md) | LITE profile features | Users |
| [STRATEGIE_MOBILE_ANDROID_COMPLETE.md](./STRATEGIE_MOBILE_ANDROID_COMPLETE.md) | Mobile strategy | Product team |
| [GUIDE_DEPLOIEMENT_PRODUCTION_v38.md](./GUIDE_DEPLOIEMENT_PRODUCTION_v38.md) | Production deployment | DevOps/DevTools |

**Historical Documentation:** [.github/archive/](./​.github/archive/) - v27-v37 docs preserved

---

## 🛠️ Technology Stack

### Frontend
- **React** 18.3.1 - UI framework
- **Vite** 6.0.5 - Build tool
- **TypeScript** 5.7.3 - Type safety
- **Zustand** 5.0.2 - State management
- **Tailwind CSS** - Styling

### Backend
- **Tauri** 2.2.0 - Desktop runtime (no Electron)
- **Rust** 1.83 - System language
- **better-sqlite3** - Local database
- **@xenova/transformers** - On-device AI models

### DevOps
- **pnpm** - Package manager
- **Vitest** - Test framework
- **ESLint** - Code quality
- **Prettier** - Code formatting

---

## 📊 Performance Metrics

### Current (v37.0.0)
- Bundle size: 6.9 MB
- LCP: 2.1s
- Lighthouse: 85/100
- Mobile reach: 0 (Tauri desktop only)

### Target (v38.0.0, Feb 28 2026)
- Bundle size: **4.5 MB** (-35%)
- LCP: **1.2s** (-43%)
- Lighthouse: **96/100** (+13)
- Mobile reach: **500M+** users (PWA + Capacitor)
- Code: **280K LOC** (-29% vs 395K)

---

## 🏗️ Architecture: 4-Ring Model

TITANE follows a strict 4-ring architecture for maintainability:

```
Ring 4: UI/OS (React + Tauri)
  ↓ imports from
Ring 3: Services (I/O, APIs, Database)
  ↓ imports from
Ring 2: Engines (Business logic, 9 cognitive moteurs)
  ↓ imports from
Ring 1: Core (Types, constants, zero imports)
```

**Rule:** Inner rings never import outer rings = **Clean architecture**

See [ARCHITECTURE.md](./ARCHITECTURE.md) for details.

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) for:
- Setup instructions
- Code style guidelines
- Pull request process
- Commit message format

### Quick Contribution
```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes
# Run tests
pnpm test

# Submit PR
# Code review
# Merge & deploy
```

---

## 📅 Roadmap

### v38.0.0 (Feb 28, 2026) - Performance + Mobile
- ✨ Performance optimization (-35% bundle)
- 📱 PWA + Capacitor Android support
- 🔧 Code consolidation (-29% LOC)
- 🎯 Enterprise readiness (SOC2 audit)

### v39.0.0 (March 2026) - Native Apps
- 📱 React Native iOS/Android apps
- 🎨 Native UI components
- 📊 100K installs target

### v40.0.0 (April 2026) - Flutter Desktop
- 🖥️ macOS/Linux native apps
- ⚡ Maximum performance
- 🌍 Cross-platform leadership

### v41.0.0+ (Q2 2026) - Enterprise
- 🏢 SaaS deployment
- 👥 Multi-user collaboration
- 💼 Enterprise contracts

---

## 📊 Current Status

| Phase | Status | Details |
|-------|--------|---------|
| **Analysis** | ✅ Complete | Comprehensive audit done |
| **Strategy** | ✅ Complete | 5 documents, all angles covered |
| **Planning** | ✅ Complete | Week-by-week execution plan |
| **Authorization** | ⏳ Awaiting | Kevin's 3 decisions (Feb 2) |
| **Execution** | ⏳ Planned | Feb 3-28 (4 weeks) |
| **Release** | 🎯 Target | v38.0.0 on Feb 28 |

**Decision Deadline:** Feb 2, 2026 11 PM UTC

---

## 💬 Support & Community

- **GitHub Issues:** [Bug reports & features](https://github.com/titane/titane-lite/issues)
- **GitHub Discussions:** [Questions & ideas](https://github.com/titane/titane-lite/discussions)
- **Email:** team@titane.dev
- **Twitter:** [@titane_ai](https://twitter.com/titane_ai)

---

## 📄 License

TITANE is licensed under the **MIT License** - see [LICENSE.md](./LICENSE.md) for details.

**TL;DR:** Free to use, modify, and distribute. Keep license notice.

---

## 🎯 Vision

**TITANE is not just an AI assistant.**

It's a movement toward:
- **Accessibility:** AI for everyone (500M+ mobile users)
- **Privacy:** No cloud, no tracking, no surveillance
- **Efficiency:** Lightweight code, small footprint
- **Transparency:** Open source, community-driven
- **Empowerment:** Tools for developers to build better things

Join us in building the future of local-first AI. 🚀

---

**Built with ❤️ by the TITANE team**

*Last Updated: February 1, 2026*
