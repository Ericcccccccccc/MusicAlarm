#!/bin/bash

echo "🎵 Music Alarm - React Native App with Spotify Integration"
echo "========================================================="
echo ""

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install Node.js first."
    echo "Run: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
    echo "     sudo apt-get install -y nodejs"
    exit 1
fi

# Check if expo is installed
if ! command -v expo &> /dev/null && ! command -v npx &> /dev/null; then
    echo "❌ Expo CLI is not installed. Installing now..."
    npm install -g @expo/cli
elif ! command -v expo &> /dev/null; then
    echo "✅ Using npx to run Expo CLI"
fi

echo "✅ Prerequisites check complete!"
echo ""

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

echo "🚀 Starting Expo development server..."
echo ""
echo "📱 TO TEST ON IPHONE:"
echo "1. Install 'Expo Go' app from the App Store"
echo "2. Ensure iPhone and this Linux machine are on the same WiFi network"
echo "3. When QR code appears below, open Expo Go and scan it"
echo "4. The app will load instantly on your iPhone!"
echo ""
echo "🔧 FOR SPOTIFY INTEGRATION:"
echo "1. Go to https://developer.spotify.com/dashboard"
echo "2. Create a new app and get your Client ID"
echo "3. Edit src/services/SpotifyService.ts and replace 'YOUR_SPOTIFY_CLIENT_ID'"
echo ""
echo "🧪 TESTING CHECKLIST:"
echo "□ Create a test alarm 2 minutes from now"
echo "□ Grant notification permissions when prompted"
echo "□ Test enable/disable alarm functionality"
echo "□ Connect Spotify account (after setup)"
echo "□ Test repeat scheduling (daily, weekdays, etc.)"
echo "□ Put app in background and wait for alarm notification"
echo "□ Test snooze and dismiss actions"
echo ""

echo "Starting development server in 3 seconds..."
sleep 3

# Start the development server
if command -v expo &> /dev/null; then
    expo start
else
    npx expo start
fi