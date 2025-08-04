import React, { useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Provider as PaperProvider } from 'react-native-paper';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import * as Notifications from 'expo-notifications';
import { AppProvider } from './src/contexts/AppContext';
import AlarmsScreen from './src/screens/AlarmsScreen';
import CreateAlarmScreen from './src/screens/CreateAlarmScreen';
import SettingsScreen from './src/screens/SettingsScreen';
import { theme } from './src/utils/theme';
import { notificationService } from './src/services/NotificationService';
import Icon from 'react-native-vector-icons/MaterialIcons';

const Tab = createBottomTabNavigator();

function AppContent() {
  useEffect(() => {
    // Handle notification responses (snooze/dismiss actions)
    const subscription = notificationService.addNotificationResponseListener((response) => {
      const { actionIdentifier, notification } = response;
      const alarmId = notification.request.content.data?.alarmId;
      
      if (alarmId) {
        if (actionIdentifier === 'snooze') {
          notificationService.snoozeAlarm(alarmId);
        } else if (actionIdentifier === 'dismiss') {
          // Alarm is automatically dismissed when user taps dismiss
          console.log('Alarm dismissed:', alarmId);
        }
      }
    });

    return () => subscription.remove();
  }, []);

  return (
    <NavigationContainer>
      <StatusBar style="auto" />
      <Tab.Navigator
        screenOptions={({ route }) => ({
          tabBarIcon: ({ focused, color, size }) => {
            let iconName: string;

            if (route.name === 'Alarms') {
              iconName = 'alarm';
            } else if (route.name === 'Add Alarm') {
              iconName = 'add-alarm';
            } else if (route.name === 'Settings') {
              iconName = 'settings';
            } else {
              iconName = 'help';
            }

            return <Icon name={iconName} size={size} color={color} />;
          },
          tabBarActiveTintColor: theme.colors.primary,
          tabBarInactiveTintColor: 'gray',
          headerStyle: {
            backgroundColor: theme.colors.primary,
          },
          headerTintColor: theme.colors.onPrimary,
        })}
      >
        <Tab.Screen name="Alarms" component={AlarmsScreen} />
        <Tab.Screen name="Add Alarm" component={CreateAlarmScreen} />
        <Tab.Screen name="Settings" component={SettingsScreen} />
      </Tab.Navigator>
    </NavigationContainer>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <PaperProvider theme={theme}>
        <AppProvider>
          <AppContent />
        </AppProvider>
      </PaperProvider>
    </SafeAreaProvider>
  );
}