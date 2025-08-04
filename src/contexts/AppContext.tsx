import React, { createContext, useContext, useReducer, useEffect, ReactNode } from 'react';
import { Alarm, AppState, CreateAlarmInput, UpdateAlarmInput } from '../types';
import { storageService } from '../services/StorageService';
import { notificationService } from '../services/NotificationService';
import { spotifyService } from '../services/SpotifyService';

interface AppContextType {
  state: AppState;
  actions: {
    loadInitialData: () => Promise<void>;
    createAlarm: (input: CreateAlarmInput) => Promise<void>;
    updateAlarm: (input: UpdateAlarmInput) => Promise<void>;
    deleteAlarm: (alarmId: string) => Promise<void>;
    toggleAlarm: (alarmId: string) => Promise<void>;
    authenticateSpotify: () => Promise<boolean>;
    disconnectSpotify: () => Promise<void>;
    initializeNotifications: () => Promise<void>;
  };
}

type AppAction =
  | { type: 'SET_ALARMS'; payload: Alarm[] }
  | { type: 'ADD_ALARM'; payload: Alarm }
  | { type: 'UPDATE_ALARM'; payload: Alarm }
  | { type: 'DELETE_ALARM'; payload: string }
  | { type: 'SET_SPOTIFY_CONNECTION'; payload: boolean }
  | { type: 'SET_NOTIFICATIONS_ENABLED'; payload: boolean }
  | { type: 'SET_LOADING'; payload: boolean };

const initialState: AppState = {
  alarms: [],
  isSpotifyConnected: false,
  notificationsEnabled: false,
};

function appReducer(state: AppState, action: AppAction): AppState {
  switch (action.type) {
    case 'SET_ALARMS':
      return { ...state, alarms: action.payload };
    case 'ADD_ALARM':
      return { ...state, alarms: [...state.alarms, action.payload] };
    case 'UPDATE_ALARM':
      return {
        ...state,
        alarms: state.alarms.map(alarm =>
          alarm.id === action.payload.id ? action.payload : alarm
        ),
      };
    case 'DELETE_ALARM':
      return {
        ...state,
        alarms: state.alarms.filter(alarm => alarm.id !== action.payload),
      };
    case 'SET_SPOTIFY_CONNECTION':
      return { ...state, isSpotifyConnected: action.payload };
    case 'SET_NOTIFICATIONS_ENABLED':
      return { ...state, notificationsEnabled: action.payload };
    default:
      return state;
  }
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export function useApp(): AppContextType {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within AppProvider');
  }
  return context;
}

interface AppProviderProps {
  children: ReactNode;
}

export function AppProvider({ children }: AppProviderProps) {
  const [state, dispatch] = useReducer(appReducer, initialState);

  const generateAlarmId = (): string => {
    return Date.now().toString() + Math.random().toString(36).substr(2, 9);
  };

  const actions = {
    loadInitialData: async () => {
      try {
        const alarms = await storageService.getAlarms();
        dispatch({ type: 'SET_ALARMS', payload: alarms });

        await spotifyService.initialize();
        dispatch({ type: 'SET_SPOTIFY_CONNECTION', payload: spotifyService.isAuthenticated() });

        const notificationsEnabled = await notificationService.initialize();
        dispatch({ type: 'SET_NOTIFICATIONS_ENABLED', payload: notificationsEnabled });
      } catch (error) {
        console.error('Error loading initial data:', error);
      }
    },

    createAlarm: async (input: CreateAlarmInput) => {
      try {
        const alarm: Alarm = {
          id: generateAlarmId(),
          time: input.time,
          label: input.label,
          isEnabled: true,
          repeatDays: input.repeatDays,
          spotifyTrack: input.spotifyTrack,
          snoozeMinutes: input.snoozeMinutes || 9,
          createdAt: new Date(),
          updatedAt: new Date(),
        };

        await storageService.addAlarm(alarm);
        
        if (state.notificationsEnabled) {
          await notificationService.scheduleAlarm(alarm);
        }

        dispatch({ type: 'ADD_ALARM', payload: alarm });
      } catch (error) {
        console.error('Error creating alarm:', error);
        throw error;
      }
    },

    updateAlarm: async (input: UpdateAlarmInput) => {
      try {
        const existingAlarm = state.alarms.find(alarm => alarm.id === input.id);
        if (!existingAlarm) {
          throw new Error('Alarm not found');
        }

        const updatedAlarm: Alarm = {
          ...existingAlarm,
          ...input,
          updatedAt: new Date(),
        };

        await storageService.updateAlarm(updatedAlarm);
        
        // Cancel existing notifications and reschedule if enabled
        if (state.notificationsEnabled) {
          // Note: In a real app, you'd need to store notification IDs with each alarm
          await notificationService.scheduleAlarm(updatedAlarm);
        }

        dispatch({ type: 'UPDATE_ALARM', payload: updatedAlarm });
      } catch (error) {
        console.error('Error updating alarm:', error);
        throw error;
      }
    },

    deleteAlarm: async (alarmId: string) => {
      try {
        await storageService.deleteAlarm(alarmId);
        
        // Cancel notifications for this alarm
        if (state.notificationsEnabled) {
          // Note: In a real app, you'd need to store and cancel specific notification IDs
        }

        dispatch({ type: 'DELETE_ALARM', payload: alarmId });
      } catch (error) {
        console.error('Error deleting alarm:', error);
        throw error;
      }
    },

    toggleAlarm: async (alarmId: string) => {
      try {
        const alarm = state.alarms.find(a => a.id === alarmId);
        if (!alarm) return;

        const updatedAlarm = { ...alarm, isEnabled: !alarm.isEnabled, updatedAt: new Date() };
        await storageService.updateAlarm(updatedAlarm);

        if (updatedAlarm.isEnabled && state.notificationsEnabled) {
          await notificationService.scheduleAlarm(updatedAlarm);
        }

        dispatch({ type: 'UPDATE_ALARM', payload: updatedAlarm });
      } catch (error) {
        console.error('Error toggling alarm:', error);
        throw error;
      }
    },

    authenticateSpotify: async (): Promise<boolean> => {
      try {
        const success = await spotifyService.authenticate();
        dispatch({ type: 'SET_SPOTIFY_CONNECTION', payload: success });
        return success;
      } catch (error) {
        console.error('Error authenticating with Spotify:', error);
        return false;
      }
    },

    disconnectSpotify: async () => {
      try {
        await spotifyService.disconnect();
        dispatch({ type: 'SET_SPOTIFY_CONNECTION', payload: false });
      } catch (error) {
        console.error('Error disconnecting from Spotify:', error);
      }
    },

    initializeNotifications: async () => {
      try {
        const enabled = await notificationService.initialize();
        dispatch({ type: 'SET_NOTIFICATIONS_ENABLED', payload: enabled });
      } catch (error) {
        console.error('Error initializing notifications:', error);
      }
    },
  };

  useEffect(() => {
    actions.loadInitialData();
  }, []);

  return (
    <AppContext.Provider value={{ state, actions }}>
      {children}
    </AppContext.Provider>
  );
}