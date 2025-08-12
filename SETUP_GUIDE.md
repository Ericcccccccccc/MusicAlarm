# MusicAlarm Setup Guide for iPhone Testing

## Prerequisites
- Xcode installed on your Mac
- Apple Developer Account (free is fine for testing)
- iPhone with iOS 14.0 or later
- Spotify Premium account (for playback features)

## Step 1: Register Your App with Spotify

1. Go to https://developer.spotify.com/dashboard
2. Log in with your Spotify account
3. Click "Create App"
4. Fill in the form:
   - App Name: `MusicAlarm`
   - App Description: `Personal alarm clock with Spotify integration`
   - Redirect URI: `musicalarm://spotify-auth`
   - Which API/SDKs are you using?: Select "Web API"
5. Click "Save"
6. In your app dashboard, copy your `Client ID`
7. Keep the dashboard open, you'll need the Client Secret later

## Step 2: Configure the App

1. Open `/Config/SpotifyConfig.swift`
2. Replace `YOUR_SPOTIFY_CLIENT_ID` with your actual Client ID from Spotify Dashboard:
   ```swift
   static let clientID = "your-actual-client-id-here"
   ```

## Step 3: Set Up Xcode for Device Testing

1. Open `MusicAlarm.xcodeproj` in Xcode
2. Select your project in the navigator
3. In the "Signing & Capabilities" tab:
   - Select your Team (sign in with your Apple ID if needed)
   - Bundle Identifier should be something unique like `com.yourname.musicalarm`
   - Xcode will automatically manage signing

## Step 4: Prepare Your iPhone

1. Connect your iPhone to your Mac via USB
2. On your iPhone:
   - Go to Settings > Privacy & Security > Developer Mode
   - Enable Developer Mode (iOS 16+)
   - Trust your Mac when prompted
3. In Xcode:
   - Select your iPhone from the device dropdown (next to the scheme selector)
   - If prompted, trust the device

## Step 5: Build and Run

1. In Xcode, select your iPhone as the target device
2. Press Cmd+R or click the Play button
3. First time running:
   - Your iPhone will prompt to trust the developer certificate
   - Go to Settings > General > VPN & Device Management
   - Find your developer profile and trust it
4. The app should now launch on your iPhone

## Step 6: Test the App

1. **First Launch:**
   - The app will open to the main alarm list
   - Tap the + button to create an alarm

2. **Spotify Authentication:**
   - When you tap "Select Song from Spotify"
   - You'll be redirected to Spotify app/web for login
   - Grant the requested permissions
   - You'll be redirected back to MusicAlarm

3. **Creating an Alarm:**
   - Set your desired time
   - Choose a Spotify song
   - Enable/disable repeat days
   - Save the alarm

4. **Testing Alarms:**
   - For quick testing, set an alarm 1-2 minutes in the future
   - Keep the app in the background
   - The alarm should trigger with your selected song

## Troubleshooting

### "Untrusted Developer" Error
- Go to Settings > General > VPN & Device Management
- Trust your developer certificate

### Spotify Authentication Fails
- Verify your Client ID is correct in SpotifyConfig.swift
- Check that redirect URI matches exactly: `musicalarm://spotify-auth`
- Ensure you have Spotify app installed or use web auth

### Alarms Don't Trigger
- Check notification permissions in Settings > Notifications > MusicAlarm
- Ensure Background App Refresh is enabled
- Keep the app running in background (don't force quit)

### No Sound When Alarm Triggers
- Check device volume and ringer switch
- Verify Spotify Premium subscription (required for SDK playback)
- Check that the selected song is still available on Spotify

## Important Notes

- The app requires an active internet connection for Spotify features
- Spotify Premium is required for full playback control
- Alarms will fall back to default sound if Spotify playback fails
- The app must remain in the background (not force-quit) for alarms to work

## Next Steps

Once basic testing works:
1. Test all alarm features (snooze, repeat, etc.)
2. Test Spotify search and playback
3. Test alarm persistence after app restart
4. Test behavior with no internet connection