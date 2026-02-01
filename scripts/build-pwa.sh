#!/bin/bash

# TITANE∞ LITE v27.3.0 — PWA Build & Deploy Script
# Purpose: Build web version optimized for PWA deployment

set -euo pipefail

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  🚀 TITANE∞ LITE v27.3.0 — PWA Build & Package           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Verify dependencies
echo -e "${BLUE}[1/6] Verifying dependencies...${NC}"
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found"
    exit 1
fi
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm not found. Installing..."
    npm install -g pnpm
fi
echo -e "${GREEN}✅ Dependencies OK${NC}\n"

# Step 2: Clean previous build
echo -e "${BLUE}[2/6] Cleaning previous build...${NC}"
rm -rf dist/
echo -e "${GREEN}✅ Cleaned${NC}\n"

# Step 3: Build web version
echo -e "${BLUE}[3/6] Building PWA (web version)...${NC}"
pnpm run build:vite
echo -e "${GREEN}✅ Build complete${NC}\n"

# Step 4: Verify build
echo -e "${BLUE}[4/6] Verifying build artifacts...${NC}"
if [ ! -f "dist/index.html" ]; then
    echo "❌ Build failed: index.html not found"
    exit 1
fi
if [ ! -f "dist/manifest.json" ]; then
    echo "❌ Build failed: manifest.json not found"
    exit 1
fi
if [ ! -f "dist/sw.js" ]; then
    echo "❌ Build failed: sw.js (Service Worker) not found"
    exit 1
fi
echo -e "${GREEN}✅ All artifacts present${NC}\n"

# Step 5: Generate build stats
echo -e "${BLUE}[5/6] Computing build statistics...${NC}"
DIST_SIZE=$(du -sh dist/ | cut -f1)
JS_SIZE=$(find dist -name "*.js" -type f | xargs du -c | tail -1 | cut -f1)
CSS_SIZE=$(find dist -name "*.css" -type f | xargs du -c | tail -1 | cut -f1)

echo "📊 Build Statistics:"
echo "  Total size: $DIST_SIZE"
echo "  JS assets: ${JS_SIZE:-0}"
echo "  CSS assets: ${CSS_SIZE:-0}"
echo ""

# Step 6: Generate deployment checklist
echo -e "${BLUE}[6/6] Generating deployment resources...${NC}"

cat > dist/DEPLOYMENT_INFO.txt << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║     TITANE∞ LITE v27.3.0 — PWA Deployment Ready               ║
╚════════════════════════════════════════════════════════════════╝

📦 DEPLOYMENT OPTIONS

A) Vercel (Recommended - Free, CDN global)
   $ npm i -g vercel
   $ vercel --prod --dir dist/
   → https://titane-lite.vercel.app

B) Netlify (Free, Easy)
   $ npm i -g netlify-cli
   $ netlify deploy --prod --dir dist/
   → https://titane-lite.netlify.app

C) GitHub Pages (Free)
   $ npx gh-pages -d dist/
   → https://username.github.io/titane-lite

D) Self-Hosted (Your Server)
   Upload dist/* to /var/www/titane/
   Configure HTTPS + gzip compression

🔧 PRE-DEPLOYMENT CHECKLIST

✅ Manifest validation:
   curl https://your-domain/manifest.json | jq .

✅ Service Worker check:
   curl -I https://your-domain/sw.js

✅ HTTPS requirement:
   PWA requires HTTPS (except localhost)

✅ Icons/Screenshots:
   /vite.svg is placeholder
   Replace with real brand assets

📱 MOBILE INSTALLATION

Android (Chrome):
  1. Visit https://your-domain
  2. Tap ⋮ menu → "Install app"
  3. Confirm

iOS (Safari):
  1. Visit https://your-domain
  2. Tap Share → "Add to Home Screen"
  3. Choose name → Add

🧪 LOCAL TESTING

python3 -m http.server 8000
Open: http://localhost:8000

DevTools:
  - Application → Manifest
  - Application → Service Workers
  - Lighthouse → PWA audit

📖 DOCUMENTATION

See: PWA_DEPLOYMENT_GUIDE.md
  - Detailed setup instructions
  - Troubleshooting guide
  - Performance optimization

🚀 NEXT STEPS

1. Choose deployment platform (Vercel recommended)
2. Follow platform-specific setup
3. Enable HTTPS
4. Update manifest.json with real icons
5. Share PWA link with users

─────────────────────────────────────────────────────────────────

Questions? See PWA_DEPLOYMENT_GUIDE.md

Version: v27.3.0
Date: 1 Feb 2026
Status: ✅ Ready for Deployment
EOF

echo -e "${GREEN}✅ Deployment info generated${NC}\n"

# Final summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║            🎉 PWA BUILD COMPLETE                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📍 Build location: ./dist/"
echo "📍 Total size: $DIST_SIZE"
echo ""
echo "📖 Next: Read dist/DEPLOYMENT_INFO.txt"
echo "   Or: See PWA_DEPLOYMENT_GUIDE.md for full instructions"
echo ""
echo "🚀 Deploy to Vercel (recommended):"
echo "   $ vercel --prod --dir dist/"
echo ""
