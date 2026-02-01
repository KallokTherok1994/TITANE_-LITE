# Instructions Directory - Developer Guidelines

This directory contains comprehensive development and operational guidelines for TITANE.

---

## 📋 Files Overview

### **titane.instructions.md**
**Purpose:** Core coding standards and development rules  
**For:** All developers and contributors  
**Contains:**
- Architecture constraints (4-ring model enforcement)
- Code quality standards
- Dependency management rules
- Testing requirements
- Security guidelines
- Deployment constraints
- TITANE philosophy and constraints

**When to use:**
- Before writing code
- During code review
- When making architectural decisions
- Conflict resolution on standards

---

### **README.md** (This File)
**Purpose:** Navigation guide for instructions directory  
**For:** New developers and contributors  
**Contains:**
- Overview of all instruction files
- Quick access guide
- File relationships
- How to use this directory

---

## 🔄 File Relationships

```
titane.instructions.md (Core Rules)
├── Enforces 4-ring architecture
├── Defines code standards
├── Sets dependency policies
├── Requires testing
└── Governs deployments

↓ Used by:

CONTRIBUTING.md (How to contribute)
ARCHITECTURE.md (System design)
QUICKSTART.md (Getting started)
```

---

## 🚀 Quick Access Guide

### I want to...

**...start developing**
1. Read [QUICKSTART.md](../../QUICKSTART.md)
2. Review [ARCHITECTURE.md](../../ARCHITECTURE.md)
3. Check [titane.instructions.md](./titane.instructions.md)

**...contribute code**
1. Follow [CONTRIBUTING.md](../../CONTRIBUTING.md)
2. Understand [ARCHITECTURE.md](../../ARCHITECTURE.md)
3. Follow rules in [titane.instructions.md](./titane.instructions.md)

**...understand architecture**
1. Read [ARCHITECTURE.md](../../ARCHITECTURE.md)
2. Review 4-ring model in [titane.instructions.md](./titane.instructions.md)
3. Check code examples in source

**...deploy to production**
1. Review [titane.instructions.md](./titane.instructions.md) deployment section
2. Check [README.md](../../README.md) for deployment guide
3. Follow checklist in your PR

**...fix a bug**
1. Check [titane.instructions.md](./titane.instructions.md) for constraints
2. Follow [CONTRIBUTING.md](../../CONTRIBUTING.md) workflow
3. Run tests before PR

---

## 📚 Learning Path

### Beginner Developer
```
1. QUICKSTART.md          (5 min)   → Get running
2. README.md              (10 min)  → Understand project
3. ARCHITECTURE.md        (15 min)  → Learn design
4. titane.instructions.md (20 min)  → Know rules
5. CONTRIBUTING.md        (15 min)  → Contribution process
```

### Experienced Developer
```
1. ARCHITECTURE.md        (15 min)  → System design
2. titane.instructions.md (15 min)  → Rules & constraints
3. CONTRIBUTING.md        (10 min)  → Process
4. Source code            (varies)  → Implementation
```

### DevOps/Release Manager
```
1. titane.instructions.md (20 min)  → Deployment rules
2. README.md              (10 min)  → Project overview
3. CHANGELOG.md           (10 min)  → Version history
4. CI/CD workflows        (varies)  → Automation
```

---

## 🔐 Critical Rules (From titane.instructions.md)

### Architecture Constraint
The **4-ring model is non-negotiable:**
- Ring 1 (Core): Zero imports
- Ring 2 (Engines): Import Ring 1 only
- Ring 3 (Services): Import Rings 1-2 only
- Ring 4 (UI/OS): Unrestricted imports

❌ **Inner rings NEVER import outer rings**

### Dependency Policy
- ✅ Check existing dependencies first
- ✅ Verify compatibility with project version
- ✅ Update lock files
- ❌ Never add duplicate dependencies
- ❌ Never conflict with existing versions

### Code Quality
- ✅ TypeScript strict mode required
- ✅ 80%+ test coverage required
- ✅ ESLint pass required
- ✅ No `any` types allowed
- ✅ JSDoc comments for public APIs

### Security
- ❌ Never hardcode secrets
- ✅ Use environment variables
- ✅ Sanitize user input
- ✅ Follow OWASP Top 10

### Deployment
- ❌ Never deploy without approval
- ✅ 100% tests passing required
- ✅ Code review approved
- ✅ CHANGELOG updated

---

## 📞 Getting Help

**Questions about rules?**
→ Check [titane.instructions.md](./titane.instructions.md)

**Questions about architecture?**
→ Check [ARCHITECTURE.md](../../ARCHITECTURE.md)

**Questions about contributing?**
→ Check [CONTRIBUTING.md](../../CONTRIBUTING.md)

**Questions about setup?**
→ Check [QUICKSTART.md](../../QUICKSTART.md)

**Still stuck?**
→ Open an issue on GitHub

---

## 🔗 External References

- [README.md](../../README.md) - Main project documentation
- [QUICKSTART.md](../../QUICKSTART.md) - Quick start guide
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines
- [ARCHITECTURE.md](../../ARCHITECTURE.md) - System design
- [API_REFERENCE.md](../../API_REFERENCE.md) - API documentation
- [CHANGELOG.md](../../CHANGELOG.md) - Version history

---

## 📅 Version History

| Version | Date | Changes |
|---------|------|---------|
| v38.0.0 | 2026-02-01 | Instructions reorganized, v38 guidelines added |
| v37.x | 2025-2026 | Legacy versions (see .github/archive/) |

---

## ✅ Checklist for New Contributors

Before starting work:
- [ ] Read QUICKSTART.md
- [ ] Review ARCHITECTURE.md
- [ ] Understand 4-ring model
- [ ] Check titane.instructions.md rules
- [ ] Read CONTRIBUTING.md
- [ ] Ask questions if unclear

Before committing:
- [ ] All tests pass
- [ ] ESLint passes
- [ ] TypeScript strict passes
- [ ] No `any` types
- [ ] Documentation updated
- [ ] CHANGELOG updated
- [ ] Commit message follows convention

Before pushing:
- [ ] Code reviewed
- [ ] All tests passing
- [ ] No console errors
- [ ] Deployment checklist complete

---

## 🎯 Success Metrics

You're doing well when:
- ✅ Your code follows 4-ring model
- ✅ All tests pass
- ✅ Code review approved
- ✅ No security warnings
- ✅ Documentation updated
- ✅ Team is happy

You need help when:
- ❌ Unsure about architecture
- ❌ Tests failing
- ❌ Code review has comments
- ❌ Security scanner reports issues
- ❌ Confused about guidelines

---

**TITANE Development Guidelines v38.0.0**

*Clean code. Professional standards. Ready for production.*

Built with ❤️ by GitHub Copilot + Kevin Thibault
