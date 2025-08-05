import * as AuthSession from 'expo-auth-session';
import * as WebBrowser from 'expo-web-browser';
import { SpotifyAuthTokens, SpotifyTrack, SpotifyPlaylist } from '../types';
import { storageService } from './StorageService';

// Complete the auth session properly
WebBrowser.maybeCompleteAuthSession();

const SPOTIFY_CLIENT_ID = '4d3403d77aee43e181e173c926ecc4d3';
const SPOTIFY_REDIRECT_URI = AuthSession.makeRedirectUri({
  scheme: 'music-alarm',
  preferLocalhost: true,
});

const SPOTIFY_ENDPOINTS = {
  AUTH: 'https://accounts.spotify.com/authorize',
  TOKEN: 'https://accounts.spotify.com/api/token',
  SEARCH: 'https://api.spotify.com/v1/search',
  USER_PLAYLISTS: 'https://api.spotify.com/v1/me/playlists',
  PLAYLIST_TRACKS: (playlistId: string) => `https://api.spotify.com/v1/playlists/${playlistId}/tracks`,
} as const;

class SpotifyService {
  private tokens: SpotifyAuthTokens | null = null;

  async initialize(): Promise<void> {
    this.tokens = await storageService.getSpotifyTokens();
    if (this.tokens && this.isTokenExpired()) {
      await this.refreshAccessToken();
    }
  }

  async authenticate(): Promise<boolean> {
    try {
      console.log('Starting Spotify authentication...');
      console.log('Redirect URI:', SPOTIFY_REDIRECT_URI);

      // THE FIX: Let AuthRequest handle PKCE generation by using `usePKCE: true`.
      // This is the correct method for older versions of expo-auth-session.
      const request = new AuthSession.AuthRequest({
        clientId: SPOTIFY_CLIENT_ID,
        scopes: [
          'user-read-private',
          'user-read-email',
          'playlist-read-private',
          'playlist-read-collaborative',
          'user-library-read',
        ],
        redirectUri: SPOTIFY_REDIRECT_URI,
        responseType: AuthSession.ResponseType.Code,
        // This flag tells the library to generate and manage the code verifier and challenge automatically.
        usePKCE: true,
      });

      console.log('Auth request created with usePKCE, prompting user...');
      const result = await request.promptAsync({
        authorizationEndpoint: SPOTIFY_ENDPOINTS.AUTH,
      });

      console.log('Auth result:', result.type);

      if (result.type === 'success' && result.params.code) {
        console.log('Auth successful, exchanging code for tokens...');
        
        // THE FIX (Part 2): The codeVerifier is now stored on the `request` instance itself.
        if (!request.codeVerifier) {
            throw new Error('Code verifier not found on AuthRequest object after authentication.');
        }

        const tokens = await this.exchangeCodeForTokens(result.params.code, request.codeVerifier);
        this.tokens = tokens;
        await storageService.saveSpotifyTokens(tokens);
        console.log('Tokens saved successfully');
        return true;
      }

      if (result.type === 'cancel') {
        console.log('User cancelled authentication');
      } else if (result.type === 'error') {
        console.log('Authentication error:', result.error);
      }
      
      return false;
    } catch (error) {
      console.error('Spotify authentication error:', error);
      return false;
    }
  }

  private async exchangeCodeForTokens(code: string, codeVerifier: string): Promise<SpotifyAuthTokens> {
    try {
      console.log('Exchanging code for tokens...');
      console.log('Code length:', code.length);
      console.log('Code verifier length:', codeVerifier.length);
      console.log('Redirect URI:', SPOTIFY_REDIRECT_URI);

      const requestBody = new URLSearchParams({
        client_id: SPOTIFY_CLIENT_ID,
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: SPOTIFY_REDIRECT_URI,
        code_verifier: codeVerifier,
      });

      const response = await fetch(SPOTIFY_ENDPOINTS.TOKEN, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: requestBody.toString(),
      });

      console.log('Token response status:', response.status);

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Token exchange failed:', errorText);
        throw new Error(`Failed to exchange code for tokens: ${response.status} ${errorText}`);
      }

      const data = await response.json();
      console.log('Token exchange successful');
      
      return {
        accessToken: data.access_token,
        refreshToken: data.refresh_token,
        expiresAt: Date.now() + (data.expires_in * 1000),
      };
    } catch (error) {
      console.error('Error in exchangeCodeForTokens:', error);
      throw error;
    }
  }

  private async refreshAccessToken(): Promise<void> {
    if (!this.tokens?.refreshToken) {
      // If there's no refresh token, we can't do anything. Disconnect to clear state.
      await this.disconnect();
      throw new Error('No refresh token available. User has been disconnected.');
    }

    const requestBody = new URLSearchParams({
      client_id: SPOTIFY_CLIENT_ID,
      grant_type: 'refresh_token',
      refresh_token: this.tokens.refreshToken,
    });

    const response = await fetch(SPOTIFY_ENDPOINTS.TOKEN, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: requestBody.toString(),
    });

    if (!response.ok) {
      // If refresh fails (e.g., token revoked), disconnect the user to force re-authentication.
      await this.disconnect();
      const errorText = await response.text();
      console.error('Failed to refresh access token:', errorText);
      throw new Error(`Failed to refresh access token: ${response.status}`);
    }

    const data = await response.json();
    
    this.tokens = {
      accessToken: data.access_token,
      // Spotify may not always return a new refresh token. If not, reuse the old one.
      refreshToken: data.refresh_token || this.tokens.refreshToken,
      expiresAt: Date.now() + (data.expires_in * 1000),
    };

    await storageService.saveSpotifyTokens(this.tokens);
    console.log('Access token refreshed successfully.');
  }

  async searchTracks(query: string, limit: number = 20): Promise<SpotifyTrack[]> {
    console.log('SpotifyService.searchTracks called with query:', query);
    await this.ensureValidToken();

    const url = `${SPOTIFY_ENDPOINTS.SEARCH}?${new URLSearchParams({
      q: query,
      type: 'track',
      limit: limit.toString(),
    })}`;

    console.log('Search URL:', url);
    console.log('Making authenticated request...');
    
    const response = await this.makeAuthenticatedRequest(url);
    const data = await response.json();

    console.log('Spotify API response status:', response.status);
    console.log('Raw API response:', JSON.stringify(data, null, 2));
    
    if (!data.tracks || !data.tracks.items) {
      console.error('Invalid response structure:', data);
      return [];
    }

    const tracks = data.tracks.items.map((track: any) => ({
      id: track.id,
      name: track.name,
      artist: track.artists[0]?.name || 'Unknown Artist',
      album: track.album.name,
      previewUrl: track.preview_url,
      uri: track.uri,
      imageUrl: track.album.images[0]?.url,
    }));

    console.log('Mapped tracks:', tracks.length, 'items');
    return tracks;
  }

  async getUserPlaylists(): Promise<SpotifyPlaylist[]> {
    await this.ensureValidToken();

    const response = await this.makeAuthenticatedRequest(SPOTIFY_ENDPOINTS.USER_PLAYLISTS);
    const data = await response.json();

    return data.items.map((playlist: any) => ({
      id: playlist.id,
      name: playlist.name,
      imageUrl: playlist.images[0]?.url,
      trackCount: playlist.tracks.total,
    }));
  }

  async getPlaylistTracks(playlistId: string): Promise<SpotifyTrack[]> {
    await this.ensureValidToken();

    const response = await this.makeAuthenticatedRequest(
      SPOTIFY_ENDPOINTS.PLAYLIST_TRACKS(playlistId)
    );
    const data = await response.json();

    return data.items
      .filter((item: any) => item.track && item.track.type === 'track')
      .map((item: any) => ({
        id: item.track.id,
        name: item.track.name,
        artist: item.track.artists[0]?.name || 'Unknown Artist',
        album: item.track.album.name,
        previewUrl: item.track.preview_url,
        uri: item.track.uri,
        imageUrl: item.track.album.images[0]?.url,
      }));
  }

  private async makeAuthenticatedRequest(url: string): Promise<Response> {
    if (!this.tokens?.accessToken) {
      throw new Error('No access token available. Please authenticate.');
    }

    const response = await fetch(url, {
      headers: {
        Authorization: `Bearer ${this.tokens.accessToken}`,
      },
    });

    if (response.status === 401) {
      // Token is expired or invalid. Attempt to refresh it.
      console.log('Received 401 Unauthorized. Attempting to refresh token...');
      await this.refreshAccessToken();
      // Retry the original request with the new token.
      return this.makeAuthenticatedRequest(url);
    }

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Spotify API error for URL ${url}:`, errorText);
      throw new Error(`Spotify API error: ${response.status} ${response.statusText}`);
    }

    return response;
  }

  private async ensureValidToken(): Promise<void> {
    if (!this.tokens) {
      throw new Error('User not authenticated with Spotify. Please authenticate first.');
    }

    if (this.isTokenExpired()) {
      await this.refreshAccessToken();
    }
  }

  private isTokenExpired(): boolean {
    if (!this.tokens) return true;
    // Use a 60-second buffer to refresh the token before it actually expires.
    return Date.now() >= this.tokens.expiresAt - 60000;
  }

  async disconnect(): Promise<void> {
    this.tokens = null;
    await storageService.clearSpotifyTokens();
    console.log('User disconnected and Spotify tokens cleared.');
  }

  isAuthenticated(): boolean {
    return this.tokens !== null && !this.isTokenExpired();
  }

  getTokens(): SpotifyAuthTokens | null {
    return this.tokens;
  }
}

export const spotifyService = new SpotifyService();