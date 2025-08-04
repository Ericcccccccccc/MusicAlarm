import React from 'react';
import { View, StyleSheet, FlatList } from 'react-native';
import { Text, FAB, Surface } from 'react-native-paper';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useApp } from '../contexts/AppContext';
import AlarmCard from '../components/AlarmCard';
import { Alarm } from '../types';

export default function AlarmsScreen({ navigation }: any) {
  const { state, actions } = useApp();

  const handleToggleAlarm = async (alarmId: string) => {
    try {
      await actions.toggleAlarm(alarmId);
    } catch (error) {
      console.error('Error toggling alarm:', error);
    }
  };

  const handleDeleteAlarm = async (alarmId: string) => {
    try {
      await actions.deleteAlarm(alarmId);
    } catch (error) {
      console.error('Error deleting alarm:', error);
    }
  };

  const handleEditAlarm = (alarm: Alarm) => {
    navigation.navigate('Add Alarm', { alarm });
  };

  const renderAlarm = ({ item }: { item: Alarm }) => (
    <AlarmCard
      alarm={item}
      onToggle={handleToggleAlarm}
      onDelete={handleDeleteAlarm}
      onEdit={handleEditAlarm}
    />
  );

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.content}>
        {state.alarms.length === 0 ? (
          <Surface style={styles.emptyContainer}>
            <Text variant="headlineMedium" style={styles.emptyTitle}>
              No Alarms Set
            </Text>
            <Text variant="bodyLarge" style={styles.emptyText}>
              Tap the + button to create your first alarm
            </Text>
          </Surface>
        ) : (
          <FlatList
            data={state.alarms}
            renderItem={renderAlarm}
            keyExtractor={(item) => item.id}
            contentContainerStyle={styles.listContainer}
            showsVerticalScrollIndicator={false}
          />
        )}
      </View>
      
      <FAB
        style={styles.fab}
        icon="plus"
        onPress={() => navigation.navigate('Add Alarm')}
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
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
    margin: 16,
    borderRadius: 8,
  },
  emptyTitle: {
    marginBottom: 8,
    textAlign: 'center',
  },
  emptyText: {
    textAlign: 'center',
    opacity: 0.7,
  },
  listContainer: {
    paddingBottom: 80,
  },
  fab: {
    position: 'absolute',
    margin: 16,
    right: 0,
    bottom: 0,
  },
});