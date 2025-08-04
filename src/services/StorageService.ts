import AsyncStorage from '@react-native-async-storage/async-storage';
import { Alarm, SpotifyAuthTokens, AppState } from '../types';

const STORAGE_KEYS = {
  ALARMS: '@music_alarm_alarms',
  SPOTIFY_TOKENS: '@music_alarm_spotify_tokens',
  APP_STATE: '@music_alarm_app_state',
} as const;

class StorageService {
  async getAlarms(): Promise<Alarm[]> {
    try {
      const alarmsJson = await AsyncStorage.getItem(STORAGE_KEYS.ALARMS);
      if (!alarmsJson) return [];
      
      const alarms = JSON.parse(alarmsJson);
      return alarms.map((alarm: any) => ({
        ...alarm,
        createdAt: new Date(alarm.createdAt),
        updatedAt: new Date(alarm.updatedAt),
      }));
    } catch (error) {
      console.error('Error loading alarms:', error);
      return [];
    }
  }

  async saveAlarms(alarms: Alarm[]): Promise<void> {
    try {
      const alarmsJson = JSON.stringify(alarms);
      await AsyncStorage.setItem(STORAGE_KEYS.ALARMS, alarmsJson);
    } catch (error) {
      console.error('Error saving alarms:', error);
      throw error;
    }
  }

  async addAlarm(alarm: Alarm): Promise<void> {
    const alarms = await this.getAlarms();
    alarms.push(alarm);
    await this.saveAlarms(alarms);
  }

  async updateAlarm(updatedAlarm: Alarm): Promise<void> {
    const alarms = await this.getAlarms();
    const index = alarms.findIndex(alarm => alarm.id === updatedAlarm.id);
    if (index !== -1) {
      alarms[index] = updatedAlarm;
      await this.saveAlarms(alarms);
    }
  }

  async deleteAlarm(alarmId: string): Promise<void> {
    const alarms = await this.getAlarms();
    const filteredAlarms = alarms.filter(alarm => alarm.id !== alarmId);
    await this.saveAlarms(filteredAlarms);
  }

  async getSpotifyTokens(): Promise<SpotifyAuthTokens | null> {
    try {
      const tokensJson = await AsyncStorage.getItem(STORAGE_KEYS.SPOTIFY_TOKENS);
      if (!tokensJson) return null;
      
      return JSON.parse(tokensJson);
    } catch (error) {
      console.error('Error loading Spotify tokens:', error);
      return null;
    }
  }

  async saveSpotifyTokens(tokens: SpotifyAuthTokens): Promise<void> {
    try {
      const tokensJson = JSON.stringify(tokens);
      await AsyncStorage.setItem(STORAGE_KEYS.SPOTIFY_TOKENS, tokensJson);
    } catch (error) {
      console.error('Error saving Spotify tokens:', error);
      throw error;
    }
  }

  async clearSpotifyTokens(): Promise<void> {
    try {
      await AsyncStorage.removeItem(STORAGE_KEYS.SPOTIFY_TOKENS);
    } catch (error) {
      console.error('Error clearing Spotify tokens:', error);
      throw error;
    }
  }

  async getAppState(): Promise<Partial<AppState>> {
    try {
      const stateJson = await AsyncStorage.getItem(STORAGE_KEYS.APP_STATE);
      if (!stateJson) return {};
      
      return JSON.parse(stateJson);
    } catch (error) {
      console.error('Error loading app state:', error);
      return {};
    }
  }

  async saveAppState(state: Partial<AppState>): Promise<void> {
    try {
      const stateJson = JSON.stringify(state);
      await AsyncStorage.setItem(STORAGE_KEYS.APP_STATE, stateJson);
    } catch (error) {
      console.error('Error saving app state:', error);
      throw error;
    }
  }

  async clearAllData(): Promise<void> {
    try {
      await AsyncStorage.multiRemove([
        STORAGE_KEYS.ALARMS,
        STORAGE_KEYS.SPOTIFY_TOKENS,
        STORAGE_KEYS.APP_STATE,
      ]);
    } catch (error) {
      console.error('Error clearing all data:', error);
      throw error;
    }
  }
}

export const storageService = new StorageService();