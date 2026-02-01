# ⚡ TITANE v38.0.0 - Quick Reference Guide

**For busy developers who need info fast!**

---

## 🎯 Commands Reference

### Development
```bash
pnpm run dev:tauri      # Start dev server
pnpm run build          # Build for production
pnpm run test           # Run tests
pnpm run lint           # Run linter
pnpm run type-check     # Check TypeScript
```

### Deployment
```bash
pnpm run deploy:prod    # Deploy to production
pnpm run deploy:staging # Deploy to staging
git tag v38.x.x         # Create release tag
```

---

## 📋 Checklists

### Before Committing
- [ ] Tests passing: `pnpm run test`
- [ ] No lint errors: `pnpm run lint`
- [ ] No TypeScript errors: `pnpm run type-check`
- [ ] Code formatted
- [ ] Comments added
- [ ] PR template filled

### Before Deploying
- [ ] All tests passing
- [ ] Git status clean
- [ ] Tag exists: `git tag -l v38.0.0`
- [ ] Monitoring ready
- [ ] Team notified
- [ ] Backup verified

### After Deploying
- [ ] Health check OK
- [ ] Metrics normal
- [ ] Logs clean
- [ ] Users confirmed
- [ ] Team updated

---

## 🏗️ Architecture Quick Ref

### 4-Ring Model
```
Ring 3 (Presentation)     ← UI Components
    ↓ imports from
Ring 2 (Application)      ← Features & Services  
    ↓ imports from
Ring 1 (Domain)           ← Business Logic
    ↓ imports from
Ring 0 (Core)             ← Types & Utilities
```

**KEY RULE:** Inner rings NEVER import outer rings ✅

---

## 📁 File Structure

```
titane/
├── src/                  # Source code
│   ├── ring0/           # Core utilities
│   ├── ring1/           # Domain logic
│   ├── ring2/           # Features
│   └── ring3/           # UI components
├── tests/               # Test files
├── .github/
│   ├── archive/         # Historical files
│   ├── instructions/    # Guidelines
│   └── workflows/       # CI/CD
├── docs/                # Documentation
└── config files
```

---

## 🔐 Key Files

| File | Purpose |
|------|---------|
| [README.md](README.md) | Project overview |
| [QUICKSTART.md](QUICKSTART.md) | 5-min setup |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System design |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Deployment |
| [FAQ.md](FAQ.md) | Q&A |

---

## ⚠️ Critical Rules

1. **4-Ring Model** - Non-negotiable
2. **0 Breaking Changes** - Backward compatible always
3. **Tests First** - 100% critical tests required
4. **No Secrets** - Use .env files
5. **Lint Clean** - 0 errors always

---

## 🆘 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Dev won't start | Kill ports 4000, 8080; `rm -rf node_modules` |
| Tests fail | `pnpm run test:watch` for debug |
| Build errors | `pnpm run type-check` for details |
| Git issues | `git status`, verify clean state |

---

## 📞 Get Help

- **Questions?** See [FAQ.md](FAQ.md)
- **How to contribute?** See [CONTRIBUTING.md](CONTRIBUTING.md)
- **Architecture?** See [ARCHITECTURE.md](ARCHITECTURE.md)
- **Deployment?** See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

**Need more?** Check full documentation in README.md

