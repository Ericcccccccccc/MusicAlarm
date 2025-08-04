// Simple script to create placeholder assets for development
const fs = require('fs');
const path = require('path');

// Create a simple SVG that can be converted to PNG
const createSVGIcon = (size, text) => `
<svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
  <rect width="${size}" height="${size}" fill="#1DB954"/>
  <text x="50%" y="50%" text-anchor="middle" dy="0.3em" font-family="Arial" font-size="${size/8}" fill="white" font-weight="bold">${text}</text>
</svg>`;

// Create directories
const assetsDir = path.join(__dirname, 'assets');
const soundsDir = path.join(assetsDir, 'sounds');

if (!fs.existsSync(soundsDir)) {
  fs.mkdirSync(soundsDir, { recursive: true });
}

// Create placeholder SVG files (you'll need to convert these to PNG manually)
const svgFiles = [
  { name: 'icon.svg', size: 1024, text: 'ALARM' },
  { name: 'adaptive-icon.svg', size: 1024, text: 'A' },
  { name: 'favicon.svg', size: 32, text: 'A' },
  { name: 'notification-icon.svg', size: 256, text: '🔔' },
  { name: 'splash.svg', size: 1242, text: 'Music Alarm' }
];

svgFiles.forEach(({ name, size, text }) => {
  const svgContent = createSVGIcon(size, text);
  fs.writeFileSync(path.join(assetsDir, name), svgContent);
  console.log(`Created ${name}`);
});

// Create a simple text file as placeholder for alarm sound
const soundPlaceholder = `
# Placeholder Alarm Sound

This file represents where the alarm.wav sound should be placed.

For development, you can:
1. Find any .wav audio file
2. Rename it to "alarm.wav"
3. Place it in this directory

The app will work without this file, but alarms will use the default system sound.
`;

fs.writeFileSync(path.join(soundsDir, 'README.md'), soundPlaceholder);
console.log('Created sounds/README.md');

console.log('\nPlaceholder assets created!');
console.log('To use these assets:');
console.log('1. Convert SVG files to PNG using online tools or design software');
console.log('2. Add a real alarm.wav sound file');
console.log('3. The app will work for development testing with these placeholders');