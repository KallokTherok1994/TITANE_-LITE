/**
 * TITANE∞ LITE - Environment utilities
 * © 2025 TITANE Team. All rights reserved.
 *
 * Utilitaires pour détecter et gérer les modes d'exécution
 */

/**
 * Vérifie si l'application fonctionne en mode "lite"
 * 
 * Le mode lite désactive les fonctionnalités non essentielles pour
 * réduire la consommation de ressources (CPU, RAM) tout en préservant
 * 100% des fonctionnalités de chat IA et de mémoire.
 * 
 * Activation:
 * - Via env var: TITANE_LITE_MINIMAL=1
 * - Via env var: TITANE_LITE_PROFILE=ultra_lite ou lite
 * 
 * @returns true si le mode lite est activé
 */
export function isLiteMode(): boolean {
  // Check env vars via import.meta.env (Vite) ou process.env (Node)
  const envVars = typeof import.meta !== 'undefined' && import.meta.env
    ? import.meta.env
    : typeof process !== 'undefined' && process.env
    ? process.env
    : {};

  // Check TITANE_LITE_MINIMAL flag
  if (envVars.TITANE_LITE_MINIMAL === '1' || envVars.TITANE_LITE_MINIMAL === 'true') {
    return true;
  }

  // Check TITANE_LITE_PROFILE
  const profile = envVars.TITANE_LITE_PROFILE;
  if (profile === 'ultra_lite' || profile === 'lite') {
    return true;
  }

  return false;
}

/**
 * Récupère le profil TITANE LITE actuel
 * 
 * @returns Le profil actuel ou null si non défini
 */
export function getLiteProfile(): string | null {
  const envVars = typeof import.meta !== 'undefined' && import.meta.env
    ? import.meta.env
    : typeof process !== 'undefined' && process.env
    ? process.env
    : {};

  return envVars.TITANE_LITE_PROFILE || null;
}

/**
 * Vérifie si le mode debug est activé
 * 
 * En mode debug, tous les logs sont affichés.
 * Sinon, seuls les logs importants (INFO/WARN/ERROR) sont affichés.
 * 
 * @returns true si le mode debug est activé
 */
export function isDebugMode(): boolean {
  const envVars = typeof import.meta !== 'undefined' && import.meta.env
    ? import.meta.env
    : typeof process !== 'undefined' && process.env
    ? process.env
    : {};

  // Active debug si explicitement demandé
  if (envVars.TITANE_DEBUG === '1' || envVars.TITANE_DEBUG === 'true') {
    return true;
  }

  // Désactive debug en mode lite (sauf si explicitement activé)
  if (isLiteMode() && !envVars.TITANE_DEBUG) {
    return false;
  }

  // En développement, debug activé par défaut (sauf en lite mode)
  return envVars.NODE_ENV !== 'production';
}
