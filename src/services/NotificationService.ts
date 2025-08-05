import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';
import { Alarm, RepeatDay } from '../types';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

class NotificationService {
  private permissionGranted = false;
  private isExpoGo = false;

  async initialize(): Promise<boolean> {
    try {
      // Check if running in Expo Go
      const Constants = require('expo-constants');
      this.isExpoGo = Constants.executionEnvironment === 'standalone' ? false : true;
      
      if (this.isExpoGo) {
        console.warn('Running in Expo Go - notifications have limitations. Use development build for full functionality.');
      }

      if (!Device.isDevice) {
        console.warn('Must use physical device for notifications');
        return false;
      }

      const { status: existingStatus } = await Notifications.getPermissionsAsync();
      let finalStatus = existingStatus;

      if (existingStatus !== 'granted') {
        try {
          const { status } = await Notifications.requestPermissionsAsync();
          finalStatus = status;
        } catch (error) {
          console.warn('Failed to request notification permissions:', error);
          return false;
        }
      }

      if (finalStatus !== 'granted') {
        console.warn('Notification permission not granted');
        return false;
      }

      this.permissionGranted = true;

      if (Platform.OS === 'ios') {
        try {
          await this.setupIOSCategories();
        } catch (error) {
          console.warn('Failed to setup iOS notification categories:', error);
        }
      }

      return true;
    } catch (error) {
      console.error('Error initializing notifications:', error);
      return false;
    }
  }

  private async setupIOSCategories(): Promise<void> {
    await Notifications.setNotificationCategoryAsync('alarm', [
      {
        identifier: 'snooze',
        buttonTitle: 'Snooze',
        options: {
          opensAppToForeground: false,
        },
      },
      {
        identifier: 'dismiss',
        buttonTitle: 'Dismiss',
        options: {
          opensAppToForeground: false,
        },
      },
    ]);
  }

  async scheduleAlarm(alarm: Alarm): Promise<string[]> {
    console.log('🔔 Scheduling alarm:', alarm);
    console.log('Permission granted:', this.permissionGranted);
    console.log('Is Expo Go:', this.isExpoGo);
    
    if (!this.permissionGranted) {
      console.warn('Cannot schedule alarm: notification permission not granted');
      return [];
    }

    if (this.isExpoGo) {
      console.warn('Scheduling notifications in Expo Go has limitations. For full functionality, use a development build.');
    }

    try {
      const notificationIds: string[] = [];
      const [hours, minutes] = alarm.time.split(':').map(Number);
      console.log('Parsed time:', { hours, minutes });

      if (alarm.repeatDays.length === 0) {
        console.log('Scheduling one-time alarm');
        const notificationId = await this.scheduleOneTimeAlarm(alarm, hours, minutes);
        if (notificationId) {
          notificationIds.push(notificationId);
          console.log('One-time alarm scheduled with ID:', notificationId);
        }
      } else {
        console.log('Scheduling repeating alarms for days:', alarm.repeatDays);
        for (const day of alarm.repeatDays) {
          const notificationId = await this.scheduleRepeatingAlarm(alarm, day, hours, minutes);
          if (notificationId) {
            notificationIds.push(notificationId);
            console.log(`Repeating alarm scheduled for ${day} with ID:`, notificationId);
          }
        }
      }

      console.log('Total notifications scheduled:', notificationIds.length);
      
      // Log all scheduled notifications
      const allScheduled = await this.getAllScheduledNotifications();
      console.log('All scheduled notifications:', allScheduled.length);
      allScheduled.forEach(notif => {
        console.log('Scheduled:', notif.identifier, 'trigger:', notif.trigger);
      });

      // If running in Expo Go and no notifications are scheduled, this confirms the limitation
      if (this.isExpoGo && allScheduled.length === 0 && notificationIds.length > 0) {
        console.error('🚨 EXPO GO LIMITATION: Notifications were scheduled but disappeared. This is a known Expo Go limitation.');
        console.error('💡 SOLUTION: Use a development build for reliable notifications.');
      }

      return notificationIds;
    } catch (error) {
      console.error('Error scheduling alarm:', error);
      return [];
    }
  }

  private async scheduleOneTimeAlarm(alarm: Alarm, hours: number, minutes: number): Promise<string | null> {
    try {
      const now = new Date();
      const alarmTime = new Date();
      alarmTime.setHours(hours, minutes, 0, 0);

      console.log('Current time:', now.toISOString());
      console.log('Initial alarm time:', alarmTime.toISOString());

      if (alarmTime <= now) {
        alarmTime.setDate(alarmTime.getDate() + 1);
        console.log('Alarm time was in past, moved to next day:', alarmTime.toISOString());
      }

      console.log('Final alarm time:', alarmTime.toISOString());
      console.log('Time until alarm (minutes):', (alarmTime.getTime() - now.getTime()) / (1000 * 60));

      const notificationId = await Notifications.scheduleNotificationAsync({
        content: {
          title: 'Alarm',
          body: alarm.label || 'Wake up!',
          sound: 'default',
          categoryIdentifier: 'alarm',
          data: {
            alarmId: alarm.id,
            spotifyTrack: alarm.spotifyTrack,
          },
        },
        trigger: {
          date: alarmTime,
        },
      });

      console.log('Notification scheduled successfully with ID:', notificationId);
      return notificationId;
    } catch (error) {
      console.error('Error scheduling one-time alarm:', error);
      return null;
    }
  }

  private async scheduleRepeatingAlarm(
    alarm: Alarm, 
    day: RepeatDay, 
    hours: number, 
    minutes: number
  ): Promise<string | null> {
    try {
      const weekdayMap: Record<RepeatDay, number> = {
        sunday: 1,
        monday: 2,
        tuesday: 3,
        wednesday: 4,
        thursday: 5,
        friday: 6,
        saturday: 7,
      };

      const notificationId = await Notifications.scheduleNotificationAsync({
        content: {
          title: 'Alarm',
          body: alarm.label || 'Wake up!',
          sound: 'default',
          categoryIdentifier: 'alarm',
          data: {
            alarmId: alarm.id,
            spotifyTrack: alarm.spotifyTrack,
          },
        },
        trigger: {
          weekday: weekdayMap[day],
          hour: hours,
          minute: minutes,
          repeats: true,
        },
      });

      return notificationId;
    } catch (error) {
      console.error('Error scheduling repeating alarm:', error);
      return null;
    }
  }

  async cancelAlarm(notificationIds: string[]): Promise<void> {
    await Notifications.cancelScheduledNotificationsAsync(notificationIds);
  }

  async cancelAllAlarms(): Promise<void> {
    await Notifications.cancelAllScheduledNotificationsAsync();
  }

  async getAllScheduledNotifications(): Promise<Notifications.NotificationRequest[]> {
    return await Notifications.getAllScheduledNotificationsAsync();
  }

  async scheduleTestNotification(): Promise<string | null> {
    console.log('🧪 Scheduling test notification in 5 seconds...');
    try {
      const testTime = new Date();
      testTime.setSeconds(testTime.getSeconds() + 5);
      
      const notificationId = await Notifications.scheduleNotificationAsync({
        content: {
          title: 'Test Notification',
          body: 'This is a test to see if notifications work in Expo Go',
          sound: 'default',
        },
        trigger: {
          date: testTime,
        },
      });

      console.log('Test notification scheduled with ID:', notificationId);
      
      // Check if it's actually scheduled
      setTimeout(async () => {
        const scheduled = await this.getAllScheduledNotifications();
        console.log('Test: Scheduled notifications count:', scheduled.length);
      }, 1000);

      return notificationId;
    } catch (error) {
      console.error('Failed to schedule test notification:', error);
      return null;
    }
  }

  async snoozeAlarm(alarmId: string, snoozeMinutes: number = 9): Promise<void> {
    const snoozeTime = new Date();
    snoozeTime.setMinutes(snoozeTime.getMinutes() + snoozeMinutes);

    await Notifications.scheduleNotificationAsync({
      content: {
        title: 'Alarm (Snoozed)',
        body: 'Wake up!',
        sound: 'default',
        categoryIdentifier: 'alarm',
        data: {
          alarmId,
          isSnoozed: true,
        },
      },
      trigger: {
        date: snoozeTime,
      },
    });
  }

  addNotificationResponseListener(
    listener: (response: Notifications.NotificationResponse) => void
  ): Notifications.Subscription {
    return Notifications.addNotificationResponseReceivedListener(listener);
  }

  addNotificationReceivedListener(
    listener: (notification: Notifications.Notification) => void
  ): Notifications.Subscription {
    return Notifications.addNotificationReceivedListener(listener);
  }
}

export const notificationService = new NotificationService();