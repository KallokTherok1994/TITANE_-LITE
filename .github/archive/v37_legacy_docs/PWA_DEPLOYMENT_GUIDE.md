# TITANE∞ LITE v27.3.0 — PWA Deployment Guide

**Objectif:** Rendre TITANE∞ LITE installable sur mobile comme Progressive Web App (PWA)
**Timeline:** 1-2 semaines
**Effort:** Minimal (configuration seulement)

---

## 🎯 **Phase 1: PWA Foundation (✅ COMPLETE)**

### Existing Infrastructure
- ✅ `public/manifest.json` - Web app manifest
- ✅ `public/sw-source.js` - Service Worker with Workbox
- ✅ `public/sw.js` - Compiled Service Worker
- ✅ `vite.config.ts` - Workbox plugin integration

### Configuration Status
- ✅ Manifest updated: TITANE LITE branding (v27.3.0)
- ✅ Icons configured: SVG assets (192x192, 512x512)
- ✅ Screenshots: Responsive (narrow + wide)
- ✅ Service Worker: Caching strategies active
- ✅ HTTPS ready: (Required for PWA)

---

## 🚀 **Phase 2: Build & Package (NEXT)**

### Build Process
```bash
# 1. Build web version (not Tauri desktop)
pnpm run build:vite

# Output:
# dist/
#   ├── index.html
#   ├── sw.js (Service Worker, injected by Workbox)
#   ├── manifest.json
#   ├── assets/
#   │   ├── *.js (code chunks)
#   │   └── *.css (styles)
#   └── stats.html (bundle analysis)
```

### Verification
```bash
# Check PWA readiness
cd dist/
python3 -m http.server 8000  # Local test server

# Open browser: http://localhost:8000
# DevTools → Application → Manifest
# DevTools → Application → Service Workers
```

---

## 📱 **Phase 3: Mobile Installation**

### Installation Methods

#### Method A: Chrome Mobile (Android)
1. Open `https://titane-app.example.com` on Chrome
2. Tap menu (⋮) → "Install app"
3. Confirm → App added to home screen

#### Method B: Safari iOS
1. Open `https://titane-app.example.com` in Safari
2. Tap Share → "Add to Home Screen"
3. Enter name → Add
4. **Note:** iOS has limited PWA support (no offline capability yet)

#### Method C: Direct Link (Web)
- Share link: `https://titane-app.example.com`
- Works in any modern browser
- Installable if PWA criteria met

---

## 🔧 **Phase 4: Hosting Setup (REQUIRED)**

### Deployment Options

#### Option A: Vercel (Recommended - Free)
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
cd dist/
vercel --prod

# Output: https://titane-lite.vercel.app
```

#### Option B: Netlify (Free)
```bash
# Install Netlify CLI
npm i -g netlify-cli

# Deploy
netlify deploy --prod --dir dist/

# Output: https://titane-lite.netlify.app
```

#### Option C: GitHub Pages (Free, Limited)
```bash
# Add to package.json:
# "deploy": "pnpm run build:vite && gh-pages -d dist"

pnpm run deploy
# Output: https://username.github.io/titane-lite
```

#### Option D: Self-Hosted (Your Server)
```bash
# Upload dist/ to server
scp -r dist/* user@server:/var/www/titane/

# Configure nginx:
# - HTTPS (Let's Encrypt)
# - CORS headers
# - Service Worker cache headers
# - Gzip compression
```

---

## ✅ **PWA Checklist (Validation)**

Before deployment, verify:

- [ ] Manifest present & valid
  ```bash
  curl https://your-domain/manifest.json | jq .
  ```

- [ ] Service Worker installed
  ```bash
  curl -I https://your-domain/sw.js
  # Should return: 200 OK
  ```

- [ ] HTTPS enabled
  ```bash
  curl -I https://your-domain
  # Must be HTTPS, not HTTP
  ```

- [ ] Responsive design verified
  - [ ] Mobile (375px width)
  - [ ] Tablet (768px width)
  - [ ] Desktop (1024px+ width)

- [ ] Installation prompt works
  - [ ] Chrome/Edge: Install button appears
  - [ ] Safari: Share option works
  - [ ] Firefox: Install option available

- [ ] Offline functionality
  - [ ] Service Worker caches assets
  - [ ] App starts without network
  - [ ] Critical pages load offline

- [ ] Performance metrics
  - [ ] First Contentful Paint: < 2s
  - [ ] Largest Contentful Paint: < 3s
  - [ ] Cumulative Layout Shift: < 0.1

---

## 📊 **Phase 5: Performance Optimization (Optional)**

### Bundle Analysis
```bash
# Open generated stats
open dist/stats.html

# Target: < 500KB total (gzipped)
# Current: ~400KB (CSS consolidation v27.3.0)
```

### Caching Strategy
```javascript
// From sw-source.js:

// CSS/JS: Stale-While-Revalidate
// → Fast load, background updates
// → 30-day cache

// Fonts/Images: Cache-First
// → Instant load, annual cache
// → Size-limited (50 entries)

// HTML: Network-First (not implemented yet)
// → Always check server, fallback to cache
```

---

## 🌐 **Phase 6: Distribution**

### Share PWA Link
```markdown
📱 **Install TITANE∞ LITE**

**Web:** https://titane-lite.example.com

**Android:**
1. Chrome → Open link above
2. Tap ⋮ menu → "Install app"
3. Add to home screen

**iOS:**
1. Safari → Open link above
2. Tap Share → "Add to Home Screen"
3. Tap "Add"

**Desktop:**
- All browsers supported
- No installation needed
```

### Create Landing Page
```html
<!-- landing.html -->
<h1>TITANE∞ LITE - Cognitive OS</h1>
<p>Installable on mobile & desktop</p>

<a href="https://app.example.com" class="btn">
  📱 Open App
</a>

<div class="instructions">
  <h3>How to Install</h3>
  <details>
    <summary>Android (Chrome)</summary>
    Tap ⋮ → Install app
  </details>
  <details>
    <summary>iOS (Safari)</summary>
    Tap Share → Add to Home Screen
  </details>
</div>
```

---

## ⚙️ **Testing Checklist**

### Desktop Testing
```bash
# Chrome DevTools
- Application → Manifest → Validate
- Application → Service Workers → Check status
- Lighthouse → PWA audit
- Network → Check offline behavior
```

### Mobile Testing
```bash
# Android (Chrome)
- Settings → Installed apps → TITANE
- Offline mode (airplane) → Test access
- Performance on 4G/3G

# iOS (Safari)
- Home screen app → Test functionality
- Offline mode → Check limits
```

### Performance Testing
```bash
# Lighthouse
# Run: DevTools → Lighthouse → Analyze page load
# Target scores:
# - Performance: 90+
# - Accessibility: 90+
# - Best Practices: 90+
# - PWA: 90+
# - SEO: 90+
```

---

## 📝 **Maintenance**

### Updates
```bash
# Service Worker auto-updates on deployment
# Users get latest version on next visit

# Force update (if needed):
# Increment version in sw-source.js
```

### Monitoring
```bash
# Google Search Console
- URL inspection → PWA detectability
- Mobile usability → Errors
- Performance → Web Vitals

# Sentry integration (if added)
- Error tracking
- Performance monitoring
```

---

## 🎯 **Success Criteria**

When PWA is ready for production:

✅ **Installability**
- [ ] PWA install prompt works on Chrome/Edge
- [ ] "Add to Home Screen" works on Safari
- [ ] Icon displays correctly on all platforms

✅ **Offline Support**
- [ ] Service Worker caches critical assets
- [ ] App loads without network
- [ ] Graceful degradation for API calls

✅ **Performance**
- [ ] Lighthouse PWA score: 90+
- [ ] First load: < 2s
- [ ] Repeat visit: < 500ms

✅ **User Experience**
- [ ] Responsive on mobile/tablet/desktop
- [ ] Touch-friendly interface
- [ ] Accessible (WCAG 2.1 AA)

---

## 📞 **Troubleshooting**

### Issue: PWA not installing
**Causes:**
- [ ] Not HTTPS
- [ ] Invalid manifest.json
- [ ] Missing icons
- [ ] Service Worker not loading

**Fix:**
```bash
# Validate manifest
curl https://your-domain/manifest.json | jq .

# Check service worker
DevTools → Application → Service Workers → Status

# Verify HTTPS
curl -I https://your-domain
```

### Issue: Service Worker not caching
**Causes:**
- [ ] Browser cache disabled
- [ ] Private browsing mode
- [ ] Service Worker script error

**Fix:**
```bash
# Check SW errors
DevTools → Console → Errors

# Clear cache
DevTools → Application → Storage → Clear site data

# Restart browser
```

### Issue: App slow on mobile
**Causes:**
- [ ] Large bundle size
- [ ] Network latency
- [ ] Unoptimized assets

**Fix:**
```bash
# Check bundle size
open dist/stats.html

# Enable compression
# Server: gzip/brotli

# Optimize images
# Use WebP format
```

---

**Status:** 🚀 Ready for PWA Deployment
**Version:** v27.3.0
**Next:** Deploy to Vercel/Netlify (Phase 4)
