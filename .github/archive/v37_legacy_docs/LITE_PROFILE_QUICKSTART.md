# Quick Start - TITANE Lite Profile System

**⏱️ Temps estimé:** 5-10 minutes pour un déploiement local  
**📦 Prérequis:** Git, pnpm, Tauri, bash

## 🚀 30 Secondes Setup

### Option 1: Déploiement Local (Recommandé pour Dev)

```bash
# 1. Générer configuration
./scripts/setup-lite-sync.sh lite /tmp/titane-sync

# 2. Activer les variables d'environnement
source .env.lite-lite

# 3. Lancer l'application
pnpm run dev:tauri
```

**Résultat:** TITANE démarre en mode lite avec sync activé

### Option 2: Docker Compose (Multi-Instance)

```bash
# 1. Lancer les deux instances
docker-compose up -d

# 2. Vérifier la santé
./scripts/verify-lite-sync.sh

# 3. Voir les logs
docker-compose logs -f
```

**Résultat:** Lite et Full instances partagent les données

---

## 📋 Configuration Rapide

### Mode Ultra-Lite (< 2GB RAM)

```bash
export TITANE_LITE_PROFILE=ultra_lite
export TITANE_LITE_SYNC_OUTBOX_DIR=~/.titane/sync/outbox
pnpm run dev:tauri
```

### Mode Lite (2-4GB RAM)

```bash
export TITANE_LITE_PROFILE=lite
export TITANE_LITE_SYNC_OUTBOX_DIR=/mnt/shared/sync/outbox
pnpm run dev:tauri
```

### Mode Full (> 4GB RAM)

```bash
export TITANE_LITE_PROFILE=full
export TITANE_LITE_SYNC_IMPORT_DIR=/mnt/shared/sync/import
pnpm run dev:tauri
```

---

## 🔧 Variables d'Environnement Principales

```bash
# Sélectionner profil (ultra_lite, lite, balanced, full)
TITANE_LITE_PROFILE=lite

# Pour instances Lite (export)
TITANE_LITE_SYNC_ENABLED=true
TITANE_LITE_SYNC_INTERVAL_SEC=900

# Pour instances Full (import)
TITANE_LITE_SYNC_IMPORT_ENABLED=true
TITANE_LITE_SYNC_IMPORT_MODE=merge
```

**Voir:** `LITE_PROFILE_SETUP.md` pour la liste complète

---

## 📁 Structure Répertoires

```bash
# Créer répertoire partagé
mkdir -p /mnt/titane-sync/{outbox,import}

# Monter NFS (optionnel)
sudo mount -t nfs server:/export/sync /mnt/titane-sync

# Vérifier accès
ls -la /mnt/titane-sync/
```

---

## ✅ Validation Rapide

```bash
# 1. Vérifier configuration
env | grep TITANE_LITE

# 2. Vérifier santé du système
./scripts/verify-lite-sync.sh /mnt/titane-sync

# 3. Vérifier fichiers
ls -lh /mnt/titane-sync/outbox/
ls -lh /mnt/titane-sync/import/
```

---

## 🧪 Tests Rapides

```bash
# Tests unitaires (TypeScript)
pnpm run test -- liteProfile

# Tests unitaires (Rust)
cargo test runtime_config_tests

# Tests E2E (Playwright)
pnpm run test:e2e
```

---

## 📊 Monitoring

### En Temps Réel

```bash
# Lite instance (export)
watch -n 5 'ls -lh ~/.titane/sync/outbox/'

# Full instance (import)
watch -n 5 'ls -lh /mnt/titane-sync/import/ | tail -5'

# Tail logs
tail -f ~/.titane/logs/app.log | grep -i sync
```

### Via API

```bash
# Runtime config
curl http://localhost:3000/api/runtime-config | jq .

# Memory state
curl http://localhost:3000/api/memory-state | jq .

# Performance stats
curl http://localhost:3000/api/performance | jq .
```

---

## 🐛 Troubleshooting Rapide

| Problème | Solution |
|----------|----------|
| Profil ne s'applique pas | `env \| grep TITANE_LITE && pnpm run dev:tauri` |
| Sync n'exporte pas | `chmod 755 /mnt/titane-sync && verify-lite-sync.sh` |
| Sync n'importe pas | Vérifier fichiers `.tar.gz` dans import dir |
| RAM dépassée | `TITANE_LITE_PROFILE=ultra_lite` |
| FPS trop bas | `TITANE_LITE_PROFILE=balanced` |

**Aide détaillée:** Voir `LITE_PROFILE_SETUP.md` section Troubleshooting

---

## 📚 Prochaines Étapes

### Débutant
1. ✅ Lancer quick start local
2. → Lire `LITE_PROFILE_SETUP.md`
3. → Configurer partage NFS/Samba

### Intermédiaire
1. ✅ Multi-instance Docker setup
2. → Modifier `docker-compose.yml`
3. → Déployer en production

### Avancé
1. ✅ Kubernetes deployment
2. → Configurer PVCs et ConfigMaps
3. → Monitoring + alerting

---

## 🔗 Ressources

| Ressource | Lien |
|-----------|------|
| Documentation complète | `LITE_PROFILE_SETUP.md` |
| Résumé implémentation | `LITE_PROFILE_IMPLEMENTATION_SUMMARY.md` |
| Setup automation | `./scripts/setup-lite-sync.sh` |
| Health check | `./scripts/verify-lite-sync.sh` |
| Source code | `/src/utils/liteProfile.ts` |

---

## 💡 Pro Tips

1. **Benchmarking:** Exécuter avec chaque profil et comparer metrics
2. **Debugging:** Ajouter `-v` à verify script: `./scripts/verify-lite-sync.sh -v`
3. **Monitoring:** Faire `watch` sur les répertoires de sync
4. **Backup:** Copier manuellement `.tar.gz` pour test d'import
5. **Network:** Tester latence: `ping -c 3 nfs-server`

---

## 🆘 Support Rapide

### Logs
```bash
# App logs
cat ~/.titane/logs/app.log

# Sync export logs
grep "sync" ~/.titane/logs/app.log | tail -20

# Sync import logs
grep "import" ~/.titane/logs/app.log | tail -20

# Rust/Tauri backend
RUST_LOG=debug pnpm run dev:tauri
```

### Debug API
```bash
# Frontend config
console.log(window.__TITANE_RUNTIME_CONFIG__)

# Backend config
curl http://localhost:11453/api/runtime-config

# Health status
curl http://localhost:11453/api/health
```

---

## 🎯 Checklist Déploiement

- [ ] ✅ Variables d'environnement configurées
- [ ] ✅ Répertoires de sync créés
- [ ] ✅ Permissions correctes (755)
- [ ] ✅ Montage NFS/SMB fonctionnel
- [ ] ✅ Espace disque suffisant (> 1GB)
- [ ] ✅ Tests passent (`pnpm run test`)
- [ ] ✅ Sync fonctionne manuellement
- [ ] ✅ Monitoring activé
- [ ] ✅ Backups sauvegardés
- [ ] ✅ Prêt pour production! 🚀

---

**Version:** 1.0  
**Dernière mise à jour:** 31 janvier 2026  
**Support:** Voir `LITE_PROFILE_SETUP.md` section Support
