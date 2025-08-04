import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import { Platform } from 'react-native';
import { Alarm, RepeatDay } from '../types';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

class NotificationService {
  private permissionGranted = false;

  async initialize(): Promise<boolean> {
    if (!Device.isDevice) {
      console.warn('Must use physical device for notifications');
      return false;
    }

    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== 'granted') {
      const { status } = await Notifications.requestPermissionsAsync();
      finalStatus = status;
    }

    if (finalStatus !== 'granted') {
      console.warn('Notification permission not granted');
      return false;
    }

    this.permissionGranted = true;

    if (Platform.OS === 'ios') {
      await this.setupIOSCategories();
    }

    return true;
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
    if (!this.permissionGranted) {
      throw new Error('Notification permission not granted');
    }

    const notificationIds: string[] = [];
    const [hours, minutes] = alarm.time.split(':').map(Number);

    if (alarm.repeatDays.length === 0) {
      const notificationId = await this.scheduleOneTimeAlarm(alarm, hours, minutes);
      notificationIds.push(notificationId);
    } else {
      for (const day of alarm.repeatDays) {
        const notificationId = await this.scheduleRepeatingAlarm(alarm, day, hours, minutes);
        notificationIds.push(notificationId);
      }
    }

    return notificationIds;
  }

  private async scheduleOneTimeAlarm(alarm: Alarm, hours: number, minutes: number): Promise<string> {
    const now = new Date();
    const alarmTime = new Date();
    alarmTime.setHours(hours, minutes, 0, 0);

    if (alarmTime <= now) {
      alarmTime.setDate(alarmTime.getDate() + 1);
    }

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

    return notificationId;
  }

  private async scheduleRepeatingAlarm(
    alarm: Alarm, 
    day: RepeatDay, 
    hours: number, 
    minutes: number
  ): Promise<string> {
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