import React, { useState, useEffect } from 'react';
import { View, StyleSheet, FlatList } from 'react-native';
import {
  Modal,
  Portal,
  Surface,
  Text,
  Button,
  TextInput,
  Card,
  ActivityIndicator,
  IconButton,
} from 'react-native-paper';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useApp } from '../contexts/AppContext';
import { spotifyService } from '../services/SpotifyService';
import { SpotifyTrack } from '../types';

interface SpotifyTrackSelectorProps {
  visible: boolean;
  onDismiss: () => void;
  onTrackSelect: (track: SpotifyTrack) => void;
}

export default function SpotifyTrackSelector({
  visible,
  onDismiss,
  onTrackSelect,
}: SpotifyTrackSelectorProps) {
  const { state, actions } = useApp();
  const [searchQuery, setSearchQuery] = useState('');
  const [tracks, setTracks] = useState<SpotifyTrack[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (visible && !state.isSpotifyConnected) {
      handleSpotifyAuth();
    }
  }, [visible, state.isSpotifyConnected]);

  const handleSpotifyAuth = async () => {
    try {
      setLoading(true);
      setError(null);
      const success = await actions.authenticateSpotify();
      if (!success) {
        setError('Failed to connect to Spotify. Please try again.');
      }
    } catch (error) {
      setError('Failed to connect to Spotify. Please check your internet connection.');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async () => {
    if (!searchQuery.trim() || !state.isSpotifyConnected) return;

    try {
      setLoading(true);
      setError(null);
      const results = await spotifyService.searchTracks(searchQuery.trim());
      setTracks(results);
    } catch (error) {
      console.error('Search error:', error);
      setError('Failed to search tracks. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleTrackSelect = (track: SpotifyTrack) => {
    onTrackSelect(track);
  };

  const renderTrack = ({ item }: { item: SpotifyTrack }) => (
    <Card style={styles.trackCard} onPress={() => handleTrackSelect(item)}>
      <Card.Content style={styles.trackContent}>
        <View style={styles.trackInfo}>
          <Text variant="bodyLarge" numberOfLines={1} style={styles.trackName}>
            {item.name}
          </Text>
          <Text variant="bodyMedium" numberOfLines={1} style={styles.artistName}>
            {item.artist} • {item.album}
          </Text>
        </View>
        <IconButton
          icon="play"
          size={20}
          onPress={() => handleTrackSelect(item)}
        />
      </Card.Content>
    </Card>
  );

  const renderContent = () => {
    if (!state.isSpotifyConnected) {
      return (
        <View style={styles.authContainer}>
          <Text variant="headlineSmall" style={styles.authTitle}>
            Connect to Spotify
          </Text>
          <Text variant="bodyMedium" style={styles.authDescription}>
            Connect your Spotify account to search and select music for your alarms.
          </Text>
          {error && (
            <Text variant="bodyMedium" style={styles.errorText}>
              {error}
            </Text>
          )}
          <Button
            mode="contained"
            onPress={handleSpotifyAuth}
            loading={loading}
            disabled={loading}
            style={styles.authButton}
            icon="spotify"
          >
            Connect Spotify
          </Button>
        </View>
      );
    }

    return (
      <View style={styles.searchContainer}>
        <View style={styles.searchInputContainer}>
          <TextInput
            value={searchQuery}
            onChangeText={setSearchQuery}
            placeholder="Search for songs..."
            onSubmitEditing={handleSearch}
            style={styles.searchInput}
            right={
              <TextInput.Icon
                icon="magnify"
                onPress={handleSearch}
                disabled={loading}
              />
            }
          />
        </View>

        {error && (
          <Text variant="bodyMedium" style={styles.errorText}>
            {error}
          </Text>
        )}

        {loading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator animating={true} size="large" />
            <Text variant="bodyMedium" style={styles.loadingText}>
              Searching...
            </Text>
          </View>
        ) : (
          <FlatList
            data={tracks}
            renderItem={renderTrack}
            keyExtractor={(item) => item.id}
            style={styles.tracksList}
            showsVerticalScrollIndicator={false}
            ListEmptyComponent={
              searchQuery ? (
                <View style={styles.emptyContainer}>
                  <Text variant="bodyMedium" style={styles.emptyText}>
                    No tracks found. Try a different search term.
                  </Text>
                </View>
              ) : (
                <View style={styles.emptyContainer}>
                  <Text variant="bodyMedium" style={styles.emptyText}>
                    Search for songs, artists, or albums
                  </Text>
                </View>
              )
            }
          />
        )}
      </View>
    );
  };

  return (
    <Portal>
      <Modal
        visible={visible}
        onDismiss={onDismiss}
        contentContainerStyle={styles.modal}
      >
        <Surface style={styles.container}>
          <SafeAreaView style={styles.safeArea}>
            <View style={styles.header}>
              <Text variant="headlineSmall" style={styles.title}>
                Select Music
              </Text>
              <IconButton icon="close" onPress={onDismiss} />
            </View>
            
            {renderContent()}
          </SafeAreaView>
        </Surface>
      </Modal>
    </Portal>
  );
}

const styles = StyleSheet.create({
  modal: {
    flex: 1,
    margin: 20,
    borderRadius: 8,
  },
  container: {
    flex: 1,
    borderRadius: 8,
  },
  safeArea: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  title: {
    fontWeight: 'bold',
  },
  authContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  authTitle: {
    marginBottom: 16,
    textAlign: 'center',
  },
  authDescription: {
    marginBottom: 24,
    textAlign: 'center',
    opacity: 0.7,
  },
  authButton: {
    marginTop: 16,
    paddingHorizontal: 24,
  },
  searchContainer: {
    flex: 1,
    padding: 16,
  },
  searchInputContainer: {
    marginBottom: 16,
  },
  searchInput: {
    backgroundColor: 'transparent',
  },
  tracksList: {
    flex: 1,
  },
  trackCard: {
    marginBottom: 8,
    elevation: 1,
  },
  trackContent: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
  },
  trackInfo: {
    flex: 1,
  },
  trackName: {
    fontWeight: '500',
  },
  artistName: {
    opacity: 0.7,
    marginTop: 2,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 16,
    opacity: 0.7,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 40,
  },
  emptyText: {
    textAlign: 'center',
    opacity: 0.7,
  },
  errorText: {
    color: '#d32f2f',
    textAlign: 'center',
    marginBottom: 16,
  },
});