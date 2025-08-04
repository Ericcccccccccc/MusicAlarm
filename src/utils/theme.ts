import { MD3LightTheme as DefaultTheme } from 'react-native-paper';

export const theme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    primary: '#1DB954', // Spotify green
    secondary: '#191414', // Spotify black
    tertiary: '#ffffff',
    background: '#ffffff',
    surface: '#f5f5f5',
    onPrimary: '#ffffff',
    onSecondary: '#ffffff',
    onBackground: '#191414',
    onSurface: '#191414',
  },
};