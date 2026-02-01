╔══════════════════════════════════════════════════════════════════════════════╗
║         🚨 DÉPENDANCES SYSTÈME MANQUANTES - TITANE_LITE v12            ║
╚══════════════════════════════════════════════════════════════════════════════╝

**ERREUR DÉTECTÉE** : Linking failed - WebKit2GTK libraries manquantes

```
error: unable to find library -lwebkit2gtk-4.1
error: unable to find library -ljavascriptcoregtk-4.1
```

══════════════════════════════════════════════════════════════════════════════
📦  SOLUTION : INSTALLER DÉPENDANCES TAURI V2
══════════════════════════════════════════════════════════════════════════════

**Pour Pop!_OS / Ubuntu / Debian** :

```bash
sudo apt-get update
sudo apt-get install -y \
    libwebkit2gtk-4.1-dev \
    libjavascriptcoregtk-4.1-dev \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    patchelf
```

**Alternative si webkit2gtk-4.1 non disponible** :

```bash
# Essayer webkit2gtk-4.0
sudo apt-get install -y libwebkit2gtk-4.0-dev
```

══════════════════════════════════════════════════════════════════════════════
🔧  APRÈS INSTALLATION
══════════════════════════════════════════════════════════════════════════════

```bash
cd /home/titane_os/Documents/TITANE_NEWGEN/TITANE_LITE/src-tauri
source $HOME/.cargo/env
cargo clean  # Nettoyage cache build
cargo build --release
```

══════════════════════════════════════════════════════════════════════════════
📋  DÉPENDANCES TAURI V2 COMPLÈTES (Référence)
══════════════════════════════════════════════════════════════════════════════

**Ubuntu/Debian/Pop!_OS** :
```bash
sudo apt update
sudo apt install -y \
    build-essential \
    curl \
    wget \
    file \
    libssl-dev \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    libwebkit2gtk-4.1-dev \
    libjavascriptcoregtk-4.1-dev \
    patchelf
```

**Fedora** :
```bash
sudo dnf install -y \
    webkit2gtk4.1-devel \
    openssl-devel \
    gtk3-devel \
    libappindicator-gtk3-devel \
    librsvg2-devel
```

**Arch Linux** :
```bash
sudo pacman -Syu
sudo pacman -S --needed \
    webkit2gtk-4.1 \
    gtk3 \
    libappindicator-gtk3 \
    librsvg \
    openssl
```

══════════════════════════════════════════════════════════════════════════════
✅  VÉRIFICATION POST-INSTALLATION
══════════════════════════════════════════════════════════════════════════════

```bash
# Vérifier installation WebKit
pkg-config --modversion webkit2gtk-4.1

# Vérifier GTK
pkg-config --modversion gtk+-3.0

# Si tout est OK, relancer build
cd /home/titane_os/Documents/TITANE_NEWGEN/TITANE_LITE/src-tauri
cargo build --release
```

══════════════════════════════════════════════════════════════════════════════
📊  STATUT ACTUEL
══════════════════════════════════════════════════════════════════════════════

✅ Rust toolchain      : INSTALLÉ (cargo 1.91.1, rustc 1.91.1)
✅ Node.js/NPM         : INSTALLÉ (Node v24.11.1, npm 11.6.2)
✅ Frontend build      : ✅ PRÉSENT (dist/)
✅ Backend compilation : ⚠️ 72 warnings (non-bloquants)
❌ Backend linking     : ❌ ÉCHEC (WebKit2GTK manquant)

**ACTION REQUISE** : Installer libwebkit2gtk-4.1-dev

══════════════════════════════════════════════════════════════════════════════
