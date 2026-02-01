# TITANE∞ LITE v27.3.0 — HMR Validation Checklist

**Purpose:** Verify that cascading HMR reloads have been eliminated.
**Target:** CSS edit workflow (theme-tokens.css changes)
**Expected Result:** Single HMR update per edit, NO cascading reloads

---

## ✅ Phase 1: Setup (5 min)

```bash
# 1. Verify current version
cd /home/titane/Documents/TITANE_LITE
grep '"version"' package.json  # Should show "27.3.0"

# 2. Ensure working tree is clean
git status --short  # Should return empty or (nothing)

# 3. Check that critical.css is deleted
ls -la src/styles/critical.css  # Should return "No such file"
```

---

## ✅ Phase 2: Start Dev Server (3 min)

```bash
# Terminal 1: Launch dev server
pnpm run dev:tauri:no-ollama

# Expected output:
# [0.0s] Using Vite config: vite.config.ts
# ✔ Built in XXXms
# ➜  Local:   http://127.0.0.1:5173/

# WAIT FOR: "ready in XXXms" message
```

---

## ✅ Phase 3: Monitor HMR (Requires 2nd terminal)

```bash
# Terminal 2: Watch Vite logs in real-time
cd /home/titane/Documents/TITANE_LITE

# Create a log capture (follow HMR events)
# You can use VS Code's "Log Output" panel or:
tail -f /tmp/vite-hmr.log 2>/dev/null &

# Or use grep to filter HMR updates:
# (Keep this in mind when you edit files)
```

---

## ✅ Phase 4: Trigger HMR Test (2 min)

### Test A: CSS Variable Edit (EXPECTED: 1-3 updates)

**Action:**
1. Open `src/styles/theme-tokens.css`
2. Find any CSS variable (e.g., `--titanium-color-primary: ...`)
3. Change the value slightly (add/remove 1 character)
4. **SAVE** the file

**Monitor:** Look at the Vite dev server output or browser console
- ✅ **PASS:** Single `hmr update /src/index.css` message
- ✅ **PASS:** Page reloads once, smoothly
- ❌ **FAIL:** Multiple `hmr update` messages repeated (cascade detected)
- ❌ **FAIL:** Page flickers multiple times

### Test B: Multiple CSS Edits in Rapid Succession (EXPECTED: Batched update)

**Action:**
1. Open `src/styles/theme-tokens.css`
2. Make 3-4 quick edits in different CSS variables
3. **SAVE** the file
4. Make changes to file again while first edit is being processed

**Monitor:** Vite output
- ✅ **PASS:** Updates are batched (may see 2-3 HMR messages max)
- ✅ **PASS:** No 20+ simultaneous updates
- ✅ **PASS:** Single page reload at end

### Test C: Combined CSS + Component Edit (EXPECTED: Separate updates)

**Action:**
1. Edit `src/styles/theme-tokens.css` (CSS edit)
2. Edit `src/App.tsx` (React component edit)
3. **SAVE** both files (or alternately)

**Monitor:** Vite output
- ✅ **PASS:** CSS update → 1-3 HMR messages
- ✅ **PASS:** Component update → Page reload
- ✅ **PASS:** No cascading loops in either case

---

## 📊 SUCCESS CRITERIA

### Before v27.3.0 (BROKEN):
```
[vite] (client) hmr update /src/index.css
[vite] (client) hmr update /src/index.css
[vite] (client) hmr update /src/index.css
... (repeated 30+ times in 2 seconds)
[vite] (client) page reload ...
[vite] (client) page reload ...  ← Multiple reloads
```

### After v27.3.0 (FIXED):
```
[vite] (client) hmr update /src/index.css
[vite] (client) page reload ...  ← Single reload, smooth
```

---

## 🎯 Result Recording

### Template to Document Results:

```markdown
## v27.3.0 HMR Validation — RESULTS

| Test | Action | Updates | Reloads | Status |
|------|--------|---------|---------|--------|
| A    | CSS variable edit | 1-3 | 1 | ✅ PASS / ❌ FAIL |
| B    | Rapid multi-edit | 2-4 | 1 | ✅ PASS / ❌ FAIL |
| C    | CSS + Component | 1-3 + 1 | 2 | ✅ PASS / ❌ FAIL |

**Overall:** ✅ PRODUCTION READY / ❌ NEEDS INVESTIGATION

**Notes:** [Add observations, unexpected behavior, etc.]
```

---

## 🔍 Troubleshooting

### Issue: Still seeing 20+ HMR updates per edit

**Possible causes:**
1. Vite cache not cleared
   ```bash
   rm -rf node_modules/.vite
   pnpm run dev:tauri:no-ollama  # Restart
   ```

2. Critical.css somehow still being imported
   ```bash
   grep -r "critical\.css" src/ index.html  # Should return 0 matches
   ```

3. Tauri build artifacts in watch path
   ```bash
   # Check vite.config.ts: watch.ignored should include:
   # **/src-tauri/target/**
   # **/src-tauri/**/out/tauri-codegen-assets/**
   ```

### Issue: HMR working but feels sluggy (500ms throttle active)

**Expected:** This is normal. The 500ms throttle prevents cascades.
**To adjust:** Edit `src/main.tsx` line ~13:
```typescript
const HMR_THROTTLE_MS = 500;  // ← Change this value (in milliseconds)
```
Decrease to ~200-300ms for snappier response (trade-off: cascade risk increases slightly).

---

## 📝 Validation Approval

After running all tests and confirming ✅ PASS on all 3 test cases:

```bash
# Record approval
echo "✅ v27.3.0 HMR Validation PASSED — Ready for production" > VALIDATION_COMPLETE_v27.3.0.txt
git add VALIDATION_COMPLETE_v27.3.0.txt
git commit -m "docs(validation): v27.3.0 HMR cascade fixes verified"
git push origin MAIN
```

---

## 📞 Support

If issues persist after validation:
1. Check [MIGRATION_HMR_v27.3.0.md](./MIGRATION_HMR_v27.3.0.md) for technical details
2. Review git changes: `git show 88a1e694`
3. Verify vite.config.ts awaitWriteFinish settings
4. Check src/main.tsx HMR throttle logic

---

**Version:** v27.3.0
**Last Updated:** 1 Feb 2026
**Status:** Ready for Testing
