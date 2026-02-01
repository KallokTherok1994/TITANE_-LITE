/**
 * TITANE_LITE v19.2.0 — Proprietary License
 * © 2025 Humain Total / Kevin Thibault / TITANE Team. All rights reserved.
 */

import { useState, useEffect, useCallback } from 'react';
import {
  type TTSSettings,
  type AudioDevice,
  type AudioConfiguration,
  type AudioTestResult,
  type MicrophoneTestResult,
  type VoiceProfile,
} from '../types';
import { audioService } from '../services/audioService';
import { isLiteMode } from '@/utils/liteProfile';

interface UseAudioReturn {
  // State
  config: AudioConfiguration;
  outputDevices: AudioDevice[];
  inputDevices: AudioDevice[];
  availableVoices: VoiceProfile[];
  isLoading: boolean;
  isTesting: boolean;
  testResult: AudioTestResult | MicrophoneTestResult | null;

  // TTS Actions
  updateTTSSettings: (settings: Partial<TTSSettings>) => Promise<void>;
  speak: (text: string) => Promise<void>;
  stopSpeaking: () => void;

  // Device Actions
  setOutputDevice: (deviceId: string) => Promise<void>;
  setInputDevice: (deviceId: string) => Promise<void>;
  setVolume: (volume: number) => Promise<void>;
  setMicGain: (gain: number) => Promise<void>;

  // Test Actions
  testSpeaker: (text?: string) => Promise<AudioTestResult>;
  testMicrophone: () => Promise<MicrophoneTestResult>;

  // Refresh
  refreshDevices: () => Promise<void>;

  // v24.7 - Extended controls
  setBalance: (balance: number) => Promise<void>;
  setInputOption: (
    option: 'noiseSuppression' | 'echoCancellation' | 'autoGainControl',
    value: boolean
  ) => Promise<void>;
}

export function useAudio(): UseAudioReturn {
  const liteMode = isLiteMode();
  const [config, setConfig] = useState<AudioConfiguration>(audioService.getConfig());
  const [outputDevices, setOutputDevices] = useState<AudioDevice[]>([]);
  const [inputDevices, setInputDevices] = useState<AudioDevice[]>([]);
  const [availableVoices, setAvailableVoices] = useState<VoiceProfile[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isTesting, setIsTesting] = useState(false);
  const [testResult, setTestResult] = useState<
    AudioTestResult | MicrophoneTestResult | null
  >(null);

  // Load initial data
  useEffect(() => {
    if (liteMode) {
      setIsLoading(false);
      return;
    }
    const loadData = async () => {
      setIsLoading(true);
      try {
        const [outputs, inputs] = await Promise.all([
          audioService.getOutputDevices(),
          audioService.getInputDevices(),
        ]);
        setOutputDevices(outputs);
        setInputDevices(inputs);
        const voices = await audioService.getAvailableVoices();
        setAvailableVoices(voices);
      } catch (error) {
        console.error('Failed to load audio devices:', error);
      } finally {
        setIsLoading(false);
      }
    };
    loadData();
  }, [liteMode]);

  // TTS Settings
  const updateTTSSettings = useCallback(async (settings: Partial<TTSSettings>) => {
    if (liteMode) return;
    await audioService.updateTTSSettings(settings);
    setConfig(audioService.getConfig());
  }, [liteMode]);

  // Speaking
  const speak = useCallback(async (text: string) => {
    if (liteMode) return;
    await audioService.speak(text);
  }, [liteMode]);

  const stopSpeaking = useCallback(() => {
    if (liteMode) return;
    audioService.stop();
  }, [liteMode]);

  // Device selection
  const setOutputDevice = useCallback(async (deviceId: string) => {
    if (liteMode) return;
    await audioService.setOutputDevice(deviceId);
    setConfig(audioService.getConfig());
  }, [liteMode]);

  const setInputDevice = useCallback(async (deviceId: string) => {
    if (liteMode) return;
    await audioService.setInputDevice(deviceId);
    setConfig(audioService.getConfig());
  }, [liteMode]);

  // Volume controls
  const setVolume = useCallback(async (volume: number) => {
    if (liteMode) return;
    await audioService.updateOutputSettings({ volume });
    setConfig(audioService.getConfig());
  }, [liteMode]);

  const setMicGain = useCallback(async (gain: number) => {
    if (liteMode) return;
    await audioService.updateInputSettings({ gain });
    setConfig(audioService.getConfig());
  }, [liteMode]);

  // Tests
  const testSpeaker = useCallback(async (text?: string): Promise<AudioTestResult> => {
    if (liteMode) {
      return {
        success: false,
        latencyMs: 0,
        qualityScore: 0,
        errorMessage: 'Audio disabled in lite profile',
      };
    }
    setIsTesting(true);
    setTestResult(null);
    try {
      const result = await audioService.testSpeaker(text);
      setTestResult(result);
      return result;
    } finally {
      setIsTesting(false);
    }
  }, [liteMode]);

  const testMicrophone = useCallback(async (): Promise<MicrophoneTestResult> => {
    if (liteMode) {
      return {
        success: false,
        peakLevel: 0,
        noiseFloor: 0,
        signalToNoise: 0,
        errorMessage: 'Audio disabled in lite profile',
      };
    }
    console.log('[useAudio] testMicrophone starting...');
    setIsTesting(true);
    setTestResult(null);
    try {
      const result = await audioService.testMicrophone();
      console.log('[useAudio] testMicrophone result:', result);
      setTestResult(result);
      return result;
    } catch (error) {
      console.error('[useAudio] testMicrophone error:', error);
      const errorResult: MicrophoneTestResult = {
        success: false,
        peakLevel: 0,
        noiseFloor: 0,
        signalToNoise: 0,
        errorMessage: error instanceof Error ? error.message : String(error),
      };
      setTestResult(errorResult);
      return errorResult;
    } finally {
      setIsTesting(false);
    }
  }, [liteMode]);

  // Refresh devices
  const refreshDevices = useCallback(async () => {
    if (liteMode) return;
    setIsLoading(true);
    try {
      const [outputs, inputs] = await Promise.all([
        audioService.getOutputDevices(),
        audioService.getInputDevices(),
      ]);
      setOutputDevices(outputs);
      setInputDevices(inputs);
      const voices = await audioService.getAvailableVoices();
      setAvailableVoices(voices);
    } finally {
      setIsLoading(false);
    }
  }, [liteMode]);

  // v24.7 - Balance control
  const setBalance = useCallback(async (balance: number) => {
    if (liteMode) return;
    await audioService.updateOutputSettings({ balance });
    setConfig(audioService.getConfig());
  }, [liteMode]);

  // v24.7 - Input processing options
  const setInputOption = useCallback(
    async (
      option: 'noiseSuppression' | 'echoCancellation' | 'autoGainControl',
      value: boolean
    ) => {
      if (liteMode) return;
      await audioService.updateInputSettings({ [option]: value });
      setConfig(audioService.getConfig());
    },
    [liteMode]
  );

  return {
    config,
    outputDevices,
    inputDevices,
    availableVoices,
    isLoading,
    isTesting,
    testResult,
    updateTTSSettings,
    speak,
    stopSpeaking,
    setOutputDevice,
    setInputDevice,
    setVolume,
    setMicGain,
    testSpeaker,
    testMicrophone,
    refreshDevices,
    setBalance,
    setInputOption,
  };
}
