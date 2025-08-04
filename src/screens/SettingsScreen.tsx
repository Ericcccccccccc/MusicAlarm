import React from 'react';
import { View, StyleSheet, ScrollView, Alert } from 'react-native';
import { Text, Card, Button, List, Switch } from 'react-native-paper';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useApp } from '../contexts/AppContext';

export default function SettingsScreen() {
  const { state, actions } = useApp();

  const handleSpotifyConnect = async () => {
    if (state.isSpotifyConnected) {
      Alert.alert(
        'Disconnect Spotify',
        'Are you sure you want to disconnect from Spotify?',
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'Disconnect',
            style: 'destructive',
            onPress: () => actions.disconnectSpotify(),
          },
        ]
      );
    } else {
      try {
        const success = await actions.authenticateSpotify();
        if (!success) {
          Alert.alert('Error', 'Failed to connect to Spotify. Please try again.');
        }
      } catch (error) {
        Alert.alert('Error', 'Failed to connect to Spotify. Please check your internet connection.');
      }
    }
  };

  const handleNotificationPermissions = async () => {
    try {
      await actions.initializeNotifications();
    } catch (error) {
      Alert.alert('Error', 'Failed to initialize notifications. Please check your settings.');
    }
  };

  const handleClearAllData = () => {
    Alert.alert(
      'Clear All Data',
      'This will delete all alarms and settings. This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete All',
          style: 'destructive',
          onPress: async () => {
            try {
              // Delete all alarms first
              for (const alarm of state.alarms) {
                await actions.deleteAlarm(alarm.id);
              }
              // Disconnect Spotify
              await actions.disconnectSpotify();
              Alert.alert('Success', 'All data has been cleared.');
            } catch (error) {
              Alert.alert('Error', 'Failed to clear all data.');
            }
          },
        },
      ]
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Spotify Settings */}
        <Card style={styles.card}>
          <Card.Content>
            <Text variant="titleMedium" style={styles.sectionTitle}>
              Spotify Integration
            </Text>
            
            <List.Item
              title="Spotify Account"
              description={
                state.isSpotifyConnected 
                  ? 'Connected - You can select music for alarms'
                  : 'Not connected - Connect to select music for alarms'
              }
              left={(props) => <List.Icon {...props} icon="spotify" />}
              right={() => (
                <Button
                  mode={state.isSpotifyConnected ? 'outlined' : 'contained'}
                  onPress={handleSpotifyConnect}
                  compact
                >
                  {state.isSpotifyConnected ? 'Disconnect' : 'Connect'}
                </Button>
              )}
            />

            {state.isSpotifyConnected && (
              <Text variant="bodySmall" style={styles.infoText}>
                ℹ️ You can now search and select Spotify tracks for your alarms.
                Note: A Spotify Premium subscription is required to play full tracks.
              </Text>
            )}
          </Card.Content>
        </Card>

        {/* Notifications Settings */}
        <Card style={styles.card}>
          <Card.Content>
            <Text variant="titleMedium" style={styles.sectionTitle}>
              Notifications
            </Text>
            
            <List.Item
              title="Notification Permissions"
              description={
                state.notificationsEnabled
                  ? 'Enabled - Alarms will trigger notifications'
                  : 'Disabled - Alarms will not work properly'
              }
              left={(props) => <List.Icon {...props} icon="bell" />}
              right={() => (
                <Switch
                  value={state.notificationsEnabled}
                  onValueChange={handleNotificationPermissions}
                />
              )}
            />

            <Text variant="bodySmall" style={styles.infoText}>
              ℹ️ Notification permissions are required for alarms to work.
              If disabled, please enable notifications in your device settings.
            </Text>
          </Card.Content>
        </Card>

        {/* App Information */}
        <Card style={styles.card}>
          <Card.Content>
            <Text variant="titleMedium" style={styles.sectionTitle}>
              App Information
            </Text>
            
            <List.Item
              title="Active Alarms"
              description={`${state.alarms.filter(alarm => alarm.isEnabled).length} enabled, ${state.alarms.length} total`}
              left={(props) => <List.Icon {...props} icon="alarm" />}
            />

            <List.Item
              title="Version"
              description="1.0.0"
              left={(props) => <List.Icon {...props} icon="information" />}
            />
          </Card.Content>
        </Card>

        {/* Usage Instructions */}
        <Card style={styles.card}>
          <Card.Content>
            <Text variant="titleMedium" style={styles.sectionTitle}>
              How to Use
            </Text>
            
            <View style={styles.instructionsContainer}>
              <Text variant="bodyMedium" style={styles.instruction}>
                1. Create alarms with custom times and labels
              </Text>
              <Text variant="bodyMedium" style={styles.instruction}>
                2. Set repeat schedules (daily, weekdays, custom days)
              </Text>
              <Text variant="bodyMedium" style={styles.instruction}>
                3. Connect Spotify to wake up to your favorite songs
              </Text>
              <Text variant="bodyMedium" style={styles.instruction}>
                4. Use snooze and dismiss actions when alarms trigger
              </Text>
              <Text variant="bodyMedium" style={styles.instruction}>
                5. Enable/disable alarms as needed
              </Text>
            </View>
          </Card.Content>
        </Card>

        {/* Important Notes */}
        <Card style={styles.card}>
          <Card.Content>
            <Text variant="titleMedium" style={styles.sectionTitle}>
              Important Notes
            </Text>
            
            <View style={styles.notesContainer}>
              <Text variant="bodySmall" style={styles.note}>
                ⚠️ Keep the app running in the background for alarms to work properly
              </Text>
              <Text variant="bodySmall" style={styles.note}>
                ⚠️ Spotify Premium is required to play full tracks during alarms
              </Text>
              <Text variant="bodySmall" style={styles.note}>
                ⚠️ Ensure your device's Do Not Disturb settings allow alarm notifications
              </Text>
            </View>
          </Card.Content>
        </Card>

        {/* Danger Zone */}
        <Card style={[styles.card, styles.dangerCard]}>
          <Card.Content>
            <Text variant="titleMedium" style={[styles.sectionTitle, styles.dangerTitle]}>
              Danger Zone
            </Text>
            
            <Button
              mode="outlined"
              onPress={handleClearAllData}
              style={styles.dangerButton}
              textColor="#d32f2f"
            >
              Clear All Data
            </Button>
            
            <Text variant="bodySmall" style={styles.dangerNote}>
              This will delete all alarms and disconnect Spotify. This action cannot be undone.
            </Text>
          </Card.Content>
        </Card>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  content: {
    flex: 1,
    padding: 16,
  },
  card: {
    marginBottom: 16,
    elevation: 2,
  },
  sectionTitle: {
    marginBottom: 12,
    fontWeight: 'bold',
  },
  infoText: {
    marginTop: 8,
    opacity: 0.7,
    lineHeight: 18,
  },
  instructionsContainer: {
    marginTop: 8,
  },
  instruction: {
    marginBottom: 8,
    lineHeight: 20,
  },
  notesContainer: {
    marginTop: 8,
  },
  note: {
    marginBottom: 8,
    opacity: 0.8,
    lineHeight: 18,
  },
  dangerCard: {
    borderColor: '#ffcdd2',
    borderWidth: 1,
  },
  dangerTitle: {
    color: '#d32f2f',
  },
  dangerButton: {
    borderColor: '#d32f2f',
    marginBottom: 8,
  },
  dangerNote: {
    color: '#d32f2f',
    opacity: 0.8,
  },
});