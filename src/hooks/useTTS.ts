/**
 * TITANE_LITE v19.2.0 — Proprietary License
 * © 2025 Humain Total / Kevin Thibault / TITANE Team. All rights reserved.
 */

/**
 * ═══════════════════════════════════════════════════════════════════
 *   TITANE∞ v19.2 — USE TTS HOOK
 *   Hook React simple pour synthèse vocale
 * ═══════════════════════════════════════════════════════════════════
 */

import { useState, useCallback } from 'react';
import { audioService } from '@/features/audio-center/services/audioService';
import { isLiteMode } from '@/utils/liteProfile';

interface UseTTSReturn {
  speak: (text: string) => Promise<void>;
  stop: () => void;
  isSpeaking: boolean;
}

export function useTTS(): UseTTSReturn {
  const [isSpeaking, setIsSpeaking] = useState(false);
  const liteMode = isLiteMode();

  const speak = useCallback(async (text: string) => {
    if (liteMode) return;
    if (!text.trim()) return;

    setIsSpeaking(true);
    try {
      await audioService.speak(text);
    } catch (error) {
      console.error('TTS error:', error);
    } finally {
      setIsSpeaking(false);
    }
  }, [liteMode]);

  const stop = useCallback(() => {
    if (liteMode) return;
    audioService.stop();
    setIsSpeaking(false);
  }, [liteMode]);

  return { speak, stop, isSpeaking: liteMode ? false : isSpeaking };
}

export default useTTS;
