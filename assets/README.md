# Assets Directory

This directory contains app assets including icons, splash screens, and sounds.

## Required Assets

You'll need to add these assets for the app to work properly:

### Icons
- `icon.png` - App icon (1024x1024px)
- `adaptive-icon.png` - Android adaptive icon (1024x1024px)
- `favicon.png` - Web favicon (32x32px)
- `notification-icon.png` - Notification icon (256x256px)

### Splash Screen
- `splash.png` - Splash screen image (1242x2436px recommended)

### Sounds
- `sounds/alarm.wav` - Default alarm sound

## Generating Assets

You can generate these assets from a single source image using:

1. **Online generators**:
   - App Icon Generator: https://appicon.co/
   - Expo Asset Generator: https://docs.expo.dev/guides/app-icons/

2. **Manual creation**:
   - Use design tools like Figma, Canva, or GIMP
   - Follow platform guidelines for sizing and formats

## Temporary Development

For development testing, you can use placeholder images:
- Any PNG image renamed to the required filename
- The app will work without perfect sizing during development
- Focus on functionality first, polish assets later

## Asset Guidelines

- Use PNG format for all icons
- Maintain transparency where appropriate
- Follow iOS and Android design guidelines
- Keep file sizes reasonable for app bundle size