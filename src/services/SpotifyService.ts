import * as AuthSession from 'expo-auth-session';
import * as Crypto from 'expo-crypto';
import { SpotifyAuthTokens, SpotifyTrack, SpotifyPlaylist } from '../types';
import { storageService } from './StorageService';

const SPOTIFY_CLIENT_ID = '4d3403d77aee43e181e173c926ecc4d3';
const SPOTIFY_REDIRECT_URI = AuthSession.makeRedirectUri({});

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
      const codeVerifier = await this.generateCodeVerifier();
      const codeChallenge = await this.generateCodeChallenge(codeVerifier);

      const authUrl = `${SPOTIFY_ENDPOINTS.AUTH}?${new URLSearchParams({
        client_id: SPOTIFY_CLIENT_ID,
        response_type: 'code',
        redirect_uri: SPOTIFY_REDIRECT_URI,
        code_challenge_method: 'S256',
        code_challenge: codeChallenge,
        scope: [
          'user-read-private',
          'user-read-email',
          'playlist-read-private',
          'playlist-read-collaborative',
          'user-library-read',
        ].join(' '),
      })}`;

      const result = await AuthSession.startAsync({
        authUrl,
        returnUrl: SPOTIFY_REDIRECT_URI,
      } as any);

      if (result.type === 'success' && result.params.code) {
        const tokens = await this.exchangeCodeForTokens(result.params.code, codeVerifier);
        this.tokens = tokens;
        await storageService.saveSpotifyTokens(tokens);
        return true;
      }

      return false;
    } catch (error) {
      console.error('Spotify authentication error:', error);
      return false;
    }
  }

  private async exchangeCodeForTokens(code: string, codeVerifier: string): Promise<SpotifyAuthTokens> {
    const response = await fetch(SPOTIFY_ENDPOINTS.TOKEN, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: SPOTIFY_CLIENT_ID,
        grant_type: 'authorization_code',
        code,
        redirect_uri: SPOTIFY_REDIRECT_URI,
        code_verifier: codeVerifier,
      }),
    });

    if (!response.ok) {
      throw new Error('Failed to exchange code for tokens');
    }

    const data = await response.json();
    
    return {
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      expiresAt: Date.now() + (data.expires_in * 1000),
    };
  }

  private async refreshAccessToken(): Promise<void> {
    if (!this.tokens?.refreshToken) {
      throw new Error('No refresh token available');
    }

    const response = await fetch(SPOTIFY_ENDPOINTS.TOKEN, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: SPOTIFY_CLIENT_ID,
        grant_type: 'refresh_token',
        refresh_token: this.tokens.refreshToken,
      }),
    });

    if (!response.ok) {
      throw new Error('Failed to refresh access token');
    }

    const data = await response.json();
    
    this.tokens = {
      accessToken: data.access_token,
      refreshToken: data.refresh_token || this.tokens.refreshToken,
      expiresAt: Date.now() + (data.expires_in * 1000),
    };

    await storageService.saveSpotifyTokens(this.tokens);
  }

  async searchTracks(query: string, limit: number = 20): Promise<SpotifyTrack[]> {
    await this.ensureValidToken();

    const url = `${SPOTIFY_ENDPOINTS.SEARCH}?${new URLSearchParams({
      q: query,
      type: 'track',
      limit: limit.toString(),
    })}`;

    const response = await this.makeAuthenticatedRequest(url);
    const data = await response.json();

    return data.tracks.items.map((track: any) => ({
      id: track.id,
      name: track.name,
      artist: track.artists[0]?.name || 'Unknown Artist',
      album: track.album.name,
      previewUrl: track.preview_url,
      uri: track.uri,
      imageUrl: track.album.images[0]?.url,
    }));
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
      throw new Error('No access token available');
    }

    const response = await fetch(url, {
      headers: {
        Authorization: `Bearer ${this.tokens.accessToken}`,
      },
    });

    if (response.status === 401) {
      await this.refreshAccessToken();
      return this.makeAuthenticatedRequest(url);
    }

    if (!response.ok) {
      throw new Error(`Spotify API error: ${response.status} ${response.statusText}`);
    }

    return response;
  }

  private async ensureValidToken(): Promise<void> {
    if (!this.tokens) {
      throw new Error('User not authenticated with Spotify');
    }

    if (this.isTokenExpired()) {
      await this.refreshAccessToken();
    }
  }

  private isTokenExpired(): boolean {
    if (!this.tokens) return true;
    return Date.now() >= this.tokens.expiresAt - 60000; // Refresh 1 minute before expiry
  }

  private async generateCodeVerifier(): Promise<string> {
    const array = new Uint8Array(32);
    await Crypto.getRandomBytesAsync(32).then(bytes => array.set(bytes));
    return this.base64URLEncode(array);
  }

  private async generateCodeChallenge(verifier: string): Promise<string> {
    const digest = await Crypto.digestStringAsync(
      Crypto.CryptoDigestAlgorithm.SHA256,
      verifier,
      { encoding: Crypto.CryptoEncoding.BASE64 }
    );
    return digest.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
  }

  private base64URLEncode(buffer: Uint8Array): string {
    const base64 = Buffer.from(buffer).toString('base64');
    return base64
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');
  }

  async disconnect(): Promise<void> {
    this.tokens = null;
    await storageService.clearSpotifyTokens();
  }

  isAuthenticated(): boolean {
    return this.tokens !== null && !this.isTokenExpired();
  }

  getTokens(): SpotifyAuthTokens | null {
    return this.tokens;
  }
}

export const spotifyService = new SpotifyService();