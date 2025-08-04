# Music Alarm - React Native App with Spotify Integration

A React Native alarm app that allows users to wake up to their favorite Spotify tracks. Built with Expo for easy testing on iPhone from Linux development environments.

## Features

- ✅ Multiple alarms with custom times and labels
- ✅ Spotify music selection (search tracks, browse playlists)
- ✅ Local notifications with snooze/dismiss actions
- ✅ Repeat scheduling (daily, weekdays, weekends, custom days)
- ✅ Enable/disable individual alarms
- ✅ Persistent storage of alarms and settings
- ✅ Clean, modern UI with React Native Paper
- ✅ TypeScript for better code quality

## Prerequisites

### Linux Development Environment Setup

1. **Install Node.js (v16 or later)**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

2. **Install Expo CLI**
   ```bash
   npm install -g @expo/cli
   ```

3. **Install Git (if not already installed)**
   ```bash
   sudo apt update
   sudo apt install git
   ```

### iPhone Setup

1. **Install Expo Go from the App Store**
   - Search for "Expo Go" in the App Store
   - Install the free app on your iPhone

2. **Ensure iPhone and Linux machine are on the same WiFi network**

## Project Setup

1. **Clone and navigate to the project**
   ```bash
   cd /home/eric/PROJECTS/MusicAlarm
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up Spotify API credentials** (see Spotify Setup section below)

## Running the App

1. **Start the Expo development server**
   ```bash
   npm start
   ```

2. **Test on iPhone**
   - A QR code will appear in your terminal
   - Open Expo Go app on your iPhone
   - Tap "Scan QR Code" and scan the code
   - The app will load on your iPhone instantly!

## Spotify API Setup

### 1. Create Spotify App

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Log in with your Spotify account
3. Click "Create an App"
4. Fill in:
   - App name: "Music Alarm"
   - App description: "Alarm app with Spotify integration"
   - Website: `http://localhost` (for development)
   - Redirect URI: `exp://192.168.1.100:19000` (replace with your machine's IP)

### 2. Configure App Settings

1. Copy your **Client ID** from the app dashboard
2. Add these redirect URIs in Spotify app settings:
   ```
   exp://localhost:19000
   exp://192.168.1.100:19000  (replace with your IP)
   https://auth.expo.io/@your-username/music-alarm
   ```

### 3. Update App Configuration

Edit `src/services/SpotifyService.ts`:
```typescript
const SPOTIFY_CLIENT_ID = 'your_actual_client_id_here';
```

## Testing on iPhone from Linux

### Quick Start Testing

1. **Start development server**
   ```bash
   npm start
   ```

2. **Connect iPhone**
   - Ensure iPhone and Linux machine are on same WiFi
   - Open Expo Go app on iPhone
   - Scan QR code from terminal

3. **Test core functionality**
   - Create a test alarm
   - Test notification permissions
   - Try Spotify authentication (requires setup)
   - Test alarm enable/disable
   - Test snooze functionality

### Live Reload Testing

- Any code changes will automatically reload on your iPhone
- Shake your iPhone to open developer menu
- Use "Reload" to manually refresh if needed

### Testing Notifications

1. **Grant notification permissions when prompted**
2. **Create a test alarm 1-2 minutes in the future**
3. **Put app in background**
4. **Wait for notification to appear**
5. **Test snooze and dismiss actions**

### Testing Spotify Integration

1. **Complete Spotify API setup (see above)**
2. **Open Settings tab in app**
3. **Tap "Connect Spotify"**
4. **Log in with your Spotify account**
5. **Create an alarm and select a track**

## Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── AlarmCard.tsx
│   └── SpotifyTrackSelector.tsx
├── contexts/           # React Context for state management
│   └── AppContext.tsx
├── screens/            # Main app screens
│   ├── AlarmsScreen.tsx
│   ├── CreateAlarmScreen.tsx
│   └── SettingsScreen.tsx
├── services/           # Business logic and API services
│   ├── NotificationService.ts
│   ├── SpotifyService.ts
│   └── StorageService.ts
├── types/              # TypeScript type definitions
│   └── index.ts
└── utils/              # Utility functions and themes
    └── theme.ts
```

## Common Testing Scenarios

### Scenario 1: Basic Alarm
1. Create alarm for 2 minutes from now
2. Set label "Test Alarm"
3. Enable alarm
4. Wait for notification
5. Test snooze (should re-trigger after 9 minutes)

### Scenario 2: Repeating Alarm
1. Create alarm for current time + 1 minute
2. Set to repeat on "Weekdays"
3. Enable alarm
4. Verify it shows correct repeat schedule

### Scenario 3: Spotify Integration
1. Complete Spotify setup
2. Connect account in Settings
3. Create alarm with Spotify track
4. Verify track shows in alarm details

## Troubleshooting

### Can't scan QR code
- Ensure iPhone and Linux machine are on same WiFi
- Check firewall settings on Linux machine
- Try using IP address instead of localhost

### Notifications not working
- Grant notification permissions when prompted
- Check iPhone Do Not Disturb settings
- Ensure app stays in background

### Spotify connection fails
- Verify Client ID is correct
- Check redirect URIs in Spotify app settings
- Ensure you have Spotify account (Premium recommended)

### App crashes or won't load
- Check terminal for error messages
- Try clearing Expo cache: `expo start -c`
- Restart Expo Go app on iPhone

## Production Deployment

For App Store deployment (requires paid Apple Developer account):

1. **Create Expo account**
   ```bash
   expo register
   expo login
   ```

2. **Build for iOS**
   ```bash
   expo build:ios
   ```

3. **Use EAS Build (recommended)**
   ```bash
   npm install -g eas-cli
   eas build --platform ios
   ```

## Important Notes

- **Spotify Premium**: Required for full track playback during alarms
- **Background limitations**: iOS may limit background processing
- **Notification reliability**: Depends on device settings and iOS version
- **WiFi requirement**: iPhone and Linux machine must be on same network for development

## Dependencies

- React Native 0.72.6
- Expo SDK 49
- React Native Paper 5.10.6
- Expo Notifications
- Expo Auth Session
- AsyncStorage
- React Navigation 6

## License

MIT License - feel free to use and modify for your needs.