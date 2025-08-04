export interface Alarm {
  id: string;
  time: string; // HH:MM format
  label: string;
  isEnabled: boolean;
  repeatDays: RepeatDay[];
  spotifyTrack?: SpotifyTrack;
  snoozeMinutes: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface SpotifyTrack {
  id: string;
  name: string;
  artist: string;
  album: string;
  previewUrl?: string;
  uri: string;
  imageUrl?: string;
}

export interface SpotifyPlaylist {
  id: string;
  name: string;
  imageUrl?: string;
  trackCount: number;
}

export interface SpotifyAuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
}

export type RepeatDay = 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday' | 'sunday';

export interface NotificationAction {
  identifier: string;
  buttonTitle: string;
  options?: {
    opensAppToForeground?: boolean;
  };
}

export interface AlarmNotification {
  identifier: string;
  title: string;
  body: string;
  sound: string;
  categoryIdentifier: string;
}

export interface AppState {
  alarms: Alarm[];
  spotifyTokens?: SpotifyAuthTokens;
  isSpotifyConnected: boolean;
  notificationsEnabled: boolean;
}

export interface CreateAlarmInput {
  time: string;
  label: string;
  repeatDays: RepeatDay[];
  spotifyTrack?: SpotifyTrack;
  snoozeMinutes?: number;
}

export interface UpdateAlarmInput extends Partial<CreateAlarmInput> {
  id: string;
  isEnabled?: boolean;
}