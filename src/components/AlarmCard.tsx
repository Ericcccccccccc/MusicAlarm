import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Card, Text, Switch, IconButton, Chip } from 'react-native-paper';
import { Alarm, RepeatDay } from '../types';

interface AlarmCardProps {
  alarm: Alarm;
  onToggle: (alarmId: string) => void;
  onDelete: (alarmId: string) => void;
  onEdit: (alarm: Alarm) => void;
}

const REPEAT_DAY_LABELS: Record<RepeatDay, string> = {
  monday: 'Mon',
  tuesday: 'Tue',
  wednesday: 'Wed',
  thursday: 'Thu',
  friday: 'Fri',
  saturday: 'Sat',
  sunday: 'Sun',
};

export default function AlarmCard({ alarm, onToggle, onDelete, onEdit }: AlarmCardProps) {
  const formatTime = (time: string): string => {
    const [hours, minutes] = time.split(':');
    const hour = parseInt(hours, 10);
    const ampm = hour >= 12 ? 'PM' : 'AM';
    const displayHour = hour % 12 || 12;
    return `${displayHour}:${minutes} ${ampm}`;
  };

  const getRepeatText = (): string => {
    if (alarm.repeatDays.length === 0) return 'Once';
    if (alarm.repeatDays.length === 7) return 'Every day';
    if (alarm.repeatDays.length === 5 && 
        !alarm.repeatDays.includes('saturday') && 
        !alarm.repeatDays.includes('sunday')) {
      return 'Weekdays';
    }
    if (alarm.repeatDays.length === 2 && 
        alarm.repeatDays.includes('saturday') && 
        alarm.repeatDays.includes('sunday')) {
      return 'Weekends';
    }
    return alarm.repeatDays.map(day => REPEAT_DAY_LABELS[day]).join(', ');
  };

  return (
    <Card style={[styles.card, !alarm.isEnabled && styles.disabledCard]}>
      <Card.Content>
        <View style={styles.header}>
          <View style={styles.timeContainer}>
            <Text variant="headlineLarge" style={[styles.time, !alarm.isEnabled && styles.disabledText]}>
              {formatTime(alarm.time)}
            </Text>
            {alarm.label && (
              <Text variant="bodyMedium" style={[styles.label, !alarm.isEnabled && styles.disabledText]}>
                {alarm.label}
              </Text>
            )}
          </View>
          <Switch
            value={alarm.isEnabled}
            onValueChange={() => onToggle(alarm.id)}
          />
        </View>

        <View style={styles.details}>
          <Text variant="bodySmall" style={[styles.repeat, !alarm.isEnabled && styles.disabledText]}>
            {getRepeatText()}
          </Text>
          
          {alarm.spotifyTrack && (
            <View style={styles.spotifyContainer}>
              <Chip
                icon="spotify"
                style={styles.spotifyChip}
                textStyle={styles.spotifyText}
              >
                {alarm.spotifyTrack.name} - {alarm.spotifyTrack.artist}
              </Chip>
            </View>
          )}
        </View>

        <View style={styles.actions}>
          <IconButton
            icon="pencil"
            onPress={() => onEdit(alarm)}
            size={20}
          />
          <IconButton
            icon="delete"
            onPress={() => onDelete(alarm.id)}
            size={20}
          />
        </View>
      </Card.Content>
    </Card>
  );
}

const styles = StyleSheet.create({
  card: {
    marginBottom: 12,
    elevation: 2,
  },
  disabledCard: {
    opacity: 0.6,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  timeContainer: {
    flex: 1,
  },
  time: {
    fontWeight: 'bold',
    color: '#1DB954',
  },
  disabledText: {
    color: '#888',
  },
  label: {
    marginTop: 4,
  },
  details: {
    marginBottom: 8,
  },
  repeat: {
    marginBottom: 8,
  },
  spotifyContainer: {
    marginBottom: 8,
  },
  spotifyChip: {
    backgroundColor: '#1DB954',
    alignSelf: 'flex-start',
  },
  spotifyText: {
    color: 'white',
    fontSize: 12,
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    marginTop: 8,
  },
});