import React, { useState, useEffect } from 'react';
import { View, StyleSheet, ScrollView, Alert } from 'react-native';
import { 
  Text, 
  Button, 
  TextInput, 
  Switch, 
  Card, 
  Chip,
  Surface,
  IconButton
} from 'react-native-paper';
import { SafeAreaView } from 'react-native-safe-area-context';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useApp } from '../contexts/AppContext';
import { RepeatDay, SpotifyTrack, Alarm } from '../types';
import SpotifyTrackSelector from '../components/SpotifyTrackSelector';

const DAYS: { key: RepeatDay; label: string }[] = [
  { key: 'sunday', label: 'Sun' },
  { key: 'monday', label: 'Mon' },
  { key: 'tuesday', label: 'Tue' },
  { key: 'wednesday', label: 'Wed' },
  { key: 'thursday', label: 'Thu' },
  { key: 'friday', label: 'Fri' },
  { key: 'saturday', label: 'Sat' },
];

export default function CreateAlarmScreen({ navigation, route }: any) {
  const { actions } = useApp();
  const editingAlarm: Alarm | undefined = route?.params?.alarm;
  const isEditing = !!editingAlarm;

  const [time, setTime] = useState(new Date());
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [label, setLabel] = useState('');
  const [repeatDays, setRepeatDays] = useState<RepeatDay[]>([]);
  const [selectedTrack, setSelectedTrack] = useState<SpotifyTrack | undefined>();
  const [showSpotifySelector, setShowSpotifySelector] = useState(false);
  const [snoozeMinutes, setSnoozeMinutes] = useState(9);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (editingAlarm) {
      const [hours, minutes] = editingAlarm.time.split(':').map(Number);
      const editTime = new Date();
      editTime.setHours(hours, minutes, 0, 0);
      setTime(editTime);
      setLabel(editingAlarm.label);
      setRepeatDays(editingAlarm.repeatDays);
      setSelectedTrack(editingAlarm.spotifyTrack);
      setSnoozeMinutes(editingAlarm.snoozeMinutes);
    }
  }, [editingAlarm]);

  const handleTimeChange = (event: any, selectedTime?: Date) => {
    setShowTimePicker(false);
    if (selectedTime) {
      setTime(selectedTime);
    }
  };

  const toggleRepeatDay = (day: RepeatDay) => {
    setRepeatDays(prev => 
      prev.includes(day) 
        ? prev.filter(d => d !== day)
        : [...prev, day]
    );
  };

  const formatTime = (date: Date): string => {
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  };

  const formatDisplayTime = (date: Date): string => {
    const hours = date.getHours();
    const minutes = date.getMinutes();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    const displayHour = hours % 12 || 12;
    return `${displayHour}:${minutes.toString().padStart(2, '0')} ${ampm}`;
  };

  const handleSave = async () => {
    try {
      setLoading(true);
      
      if (isEditing && editingAlarm) {
        await actions.updateAlarm({
          id: editingAlarm.id,
          time: formatTime(time),
          label,
          repeatDays,
          spotifyTrack: selectedTrack,
          snoozeMinutes,
        });
      } else {
        await actions.createAlarm({
          time: formatTime(time),
          label,
          repeatDays,
          spotifyTrack: selectedTrack,
          snoozeMinutes,
        });
      }

      navigation.goBack();
    } catch (error) {
      console.error('Error saving alarm:', error);
      Alert.alert('Error', 'Failed to save alarm. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const selectQuickRepeat = (type: 'weekdays' | 'weekends' | 'everyday' | 'none') => {
    switch (type) {
      case 'weekdays':
        setRepeatDays(['monday', 'tuesday', 'wednesday', 'thursday', 'friday']);
        break;
      case 'weekends':
        setRepeatDays(['saturday', 'sunday']);
        break;
      case 'everyday':
        setRepeatDays(['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']);
        break;
      case 'none':
        setRepeatDays([]);
        break;
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
        {/* Time Selection */}
        <Card style={styles.card}>
          <Card.Content>
            <Text variant="titleMedium" style={styles.sectionTitle}>Time</Text>
            <Button
              mode="outlined"
              onPress={() => setShowTimePicker(true)}
              style={styles.timeButton}
            >
              <Text variant="headlineLarge">{formatDisplayTime(time)}</Text>
            </Button>
          </Card.Content>
        </Card>

        {/* Label */}
        <Card style={styles.card}>
          <Card.Content>
            <Text variant="titleMedium" style={styles.sectionTitle}>Label</Text>
            <TextInput
              value={label}
              onChangeText={setLabel}
              placeholder="Alarm label (optional)"
              style={styles.textInput}
            />
          </Card.Content>
        </Card>

        {/* Repeat Days */}
        <Card style={styles.card}>
          <Card.Content>
            <Text variant="titleMedium" style={styles.sectionTitle}>Repeat</Text>
            
            {/* Quick Select Buttons */}
            <View style={styles.quickSelectContainer}>
              <Chip
                selected={repeatDays.length === 0}
                onPress={() => selectQuickRepeat('none')}
                style={styles.quickChip}
              >
                Once
              </Chip>
              <Chip
                selected={repeatDays.length === 7}
                onPress={() => selectQuickRepeat('everyday')}
                style={styles.quickChip}
              >
                Every day
              </Chip>
              <Chip
                selected={
                  repeatDays.length === 5 &&
                  !repeatDays.includes('saturday') &&
                  !repeatDays.includes('sunday')
                }
                onPress={() => selectQuickRepeat('weekdays')}
                style={styles.quickChip}
              >
                Weekdays
              </Chip>
              <Chip
                selected={
                  repeatDays.length === 2 &&
                  repeatDays.includes('saturday') &&
                  repeatDays.includes('sunday')
                }
                onPress={() => selectQuickRepeat('weekends')}
                style={styles.quickChip}
              >
                Weekends
              </Chip>
            </View>

            {/* Individual Day Selection */}
            <View style={styles.daysContainer}>
              {DAYS.map(day => (
                <Chip
                  key={day.key}
                  selected={repeatDays.includes(day.key)}
                  onPress={() => toggleRepeatDay(day.key)}
                  style={styles.dayChip}
                >
                  {day.label}
                </Chip>
              ))}
            </View>
          </Card.Content>
        </Card>

        {/* Spotify Track */}
        <Card style={styles.card}>
          <Card.Content>
            <View style={styles.sectionHeader}>
              <Text variant="titleMedium" style={styles.sectionTitle}>Music</Text>
              <IconButton
                icon="spotify"
                onPress={() => setShowSpotifySelector(true)}
                size={24}
              />
            </View>
            
            {selectedTrack ? (
              <Surface style={styles.selectedTrack}>
                <View style={styles.trackInfo}>
                  <Text variant="bodyLarge" numberOfLines={1}>
                    {selectedTrack.name}
                  </Text>
                  <Text variant="bodyMedium" numberOfLines={1} style={styles.artistText}>
                    {selectedTrack.artist}
                  </Text>
                </View>
                <IconButton
                  icon="close"
                  onPress={() => setSelectedTrack(undefined)}
                  size={20}
                />
              </Surface>
            ) : (
              <Button
                mode="outlined"
                onPress={() => setShowSpotifySelector(true)}
                icon="music"
                style={styles.selectMusicButton}
              >
                Select Music from Spotify
              </Button>
            )}
          </Card.Content>
        </Card>

        {/* Snooze Settings */}
        <Card style={styles.card}>
          <Card.Content>
            <Text variant="titleMedium" style={styles.sectionTitle}>
              Snooze Duration: {snoozeMinutes} minutes
            </Text>
            <View style={styles.snoozeContainer}>
              <Button
                mode="outlined"
                onPress={() => setSnoozeMinutes(Math.max(1, snoozeMinutes - 1))}
                disabled={snoozeMinutes <= 1}
              >
                -
              </Button>
              <Text variant="headlineSmall" style={styles.snoozeText}>
                {snoozeMinutes}
              </Text>
              <Button
                mode="outlined"
                onPress={() => setSnoozeMinutes(Math.min(30, snoozeMinutes + 1))}
                disabled={snoozeMinutes >= 30}
              >
                +
              </Button>
            </View>
          </Card.Content>
        </Card>

        {/* Save Button */}
        <Button
          mode="contained"
          onPress={handleSave}
          loading={loading}
          disabled={loading}
          style={styles.saveButton}
        >
          {isEditing ? 'Update Alarm' : 'Create Alarm'}
        </Button>
      </ScrollView>

      {/* Time Picker Modal */}
      {showTimePicker && (
        <DateTimePicker
          value={time}
          mode="time"
          is24Hour={false}
          display="spinner"
          onChange={handleTimeChange}
        />
      )}

      {/* Spotify Track Selector Modal */}
      <SpotifyTrackSelector
        visible={showSpotifySelector}
        onDismiss={() => setShowSpotifySelector(false)}
        onTrackSelect={(track) => {
          setSelectedTrack(track);
          setShowSpotifySelector(false);
        }}
      />
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
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  timeButton: {
    padding: 20,
  },
  textInput: {
    backgroundColor: 'transparent',
  },
  quickSelectContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 16,
  },
  quickChip: {
    marginRight: 8,
    marginBottom: 8,
  },
  daysContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  dayChip: {
    marginRight: 8,
    marginBottom: 8,
  },
  selectedTrack: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 8,
  },
  trackInfo: {
    flex: 1,
  },
  artistText: {
    opacity: 0.7,
  },
  selectMusicButton: {
    marginTop: 8,
  },
  snoozeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 8,
  },
  snoozeText: {
    marginHorizontal: 20,
    minWidth: 40,
    textAlign: 'center',
  },
  saveButton: {
    marginTop: 20,
    marginBottom: 40,
    paddingVertical: 8,
  },
});