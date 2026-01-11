# NativeWind Setup Guide

This guide covers the configuration required to use `react-native-fabric-rich-text` with [NativeWind](https://www.nativewind.dev/) for Tailwind CSS styling in React Native.

## Prerequisites

- React Native 0.81+ (Fabric/New Architecture required)
- NativeWind ^4.2.0
- Tailwind CSS 3.x (not 4.x)

## Installation

### 1. Install Dependencies

```bash
# Install NativeWind, Tailwind CSS, and required peer dependencies
npm install nativewind react-native-reanimated react-native-worklets
npm install -D tailwindcss@">=3.3.0 <4.0.0"

# Or with yarn
yarn add nativewind react-native-reanimated react-native-worklets
yarn add -D tailwindcss@">=3.3.0 <4.0.0"
```

> **Important**:
> - NativeWind 4.x requires Tailwind CSS 3.x. Tailwind CSS 4.x is not yet supported.
> - `react-native-reanimated` and `react-native-worklets` are required by NativeWind's babel plugin.

### 2. Configure Babel

Add the NativeWind babel plugin to your `babel.config.js`:

```javascript
// babel.config.js
module.exports = {
  presets: ['module:@react-native/babel-preset'],
  plugins: [
    // NativeWind babel plugin
    'nativewind/babel',
    // Required by NativeWind's css-interop
    'react-native-worklets/plugin',
  ],
};
```

If you're using `react-native-builder-bob` or a monorepo setup:

```javascript
// babel.config.js
const path = require('path');
const { getConfig } = require('react-native-builder-bob/babel-config');
const pkg = require('../package.json');

const root = path.resolve(__dirname, '..');

module.exports = getConfig(
  {
    presets: [
      [
        'module:@react-native/babel-preset',
        { useTransformReactJSXExperimental: true },
      ],
    ],
    plugins: [
      // NativeWind babel plugin - uses documented configuration
      'nativewind/babel',
      // Required by NativeWind's css-interop
      'react-native-worklets/plugin',
    ],
  },
  { root, pkg }
);
```

### 3. Configure Metro

Wrap your Metro configuration with `withNativeWind`:

```javascript
// metro.config.js
const { getDefaultConfig } = require('@react-native/metro-config');
const { withNativeWind } = require('nativewind/metro');

const config = getDefaultConfig(__dirname);

module.exports = withNativeWind(config, { input: './global.css' });
```

### 4. Create Global CSS

Create a `global.css` file in your project root:

```css
/* global.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### 5. Create Tailwind Config

Create a `tailwind.config.js` file. **Important**: Override `fontSize` and `lineHeight` with pixel values to ensure consistent sizing with React Native's StyleSheet:

```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './App.{js,jsx,ts,tsx}',
    './src/**/*.{js,jsx,ts,tsx}',
    // Include node_modules paths for libraries that use className
    './node_modules/react-native-fabric-rich-text/**/*.{js,jsx,ts,tsx}',
  ],
  presets: [require('nativewind/preset')],
  theme: {
    // Override fontSize with px values for React Native
    // NativeWind's default rem-based values differ from StyleSheet expectations
    fontSize: {
      'xs': ['12px', { lineHeight: '16px' }],
      'sm': ['14px', { lineHeight: '20px' }],
      'base': ['16px', { lineHeight: '24px' }],
      'lg': ['18px', { lineHeight: '28px' }],
      'xl': ['20px', { lineHeight: '28px' }],
      '2xl': ['24px', { lineHeight: '32px' }],
      '3xl': ['30px', { lineHeight: '36px' }],
      '4xl': ['36px', { lineHeight: '40px' }],
      '5xl': ['48px', { lineHeight: '48px' }],
    },
    // Override lineHeight (leading-*) with px values
    lineHeight: {
      'none': '1',
      'tight': '16px',
      'snug': '20px',
      'normal': '24px',
      'relaxed': '26px',
      'loose': '32px',
      '3': '12px',
      '4': '16px',
      '5': '20px',
      '6': '24px',
      '7': '28px',
      '8': '32px',
      '9': '36px',
      '10': '40px',
    },
    extend: {},
  },
  plugins: [],
};
```

> **Why pixel values?** NativeWind's default rem-based values produce different sizes than equivalent React Native StyleSheet values. Using explicit pixel values ensures `text-base` (16px) matches `{ fontSize: 16 }` in StyleSheet.

### 6. Import Global CSS

Import the global CSS file in your app entry point:

```javascript
// App.tsx or index.js
import './global.css';
```

### 7. TypeScript Configuration (Optional)

For TypeScript projects, create a type declaration file:

```typescript
// nativewind-env.d.ts
/// <reference types="nativewind/types" />
```

This adds the `className` prop type to React Native components.

## Usage

### Pre-configured Export (Recommended)

Import from the `/nativewind` subpath for zero-config className support:

```tsx
import { RichText } from 'react-native-fabric-rich-text/nativewind';

function MyComponent() {
  return (
    <RichText
      text="<p>Hello <strong>World</strong></p>"
      className="text-blue-500 text-lg font-medium p-4"
    />
  );
}
```

### Manual Integration

For more control, apply `cssInterop` yourself:

```tsx
import { RichText } from 'react-native-fabric-rich-text';
import { cssInterop } from 'nativewind';

// Apply once at app startup
cssInterop(RichText, { className: 'style' });

function MyComponent() {
  return (
    <RichText
      text="<p>Hello World</p>"
      className="text-blue-500"
    />
  );
}
```

## Features

### Responsive Variants

```tsx
<RichText
  text="<p>Responsive text</p>"
  className="text-sm md:text-base lg:text-lg"
/>
```

### Dark Mode

```tsx
<RichText
  text="<p>Theme-aware text</p>"
  className="text-gray-900 dark:text-gray-100"
/>
```

### Container Queries

Wrap RichText in a container to use container query variants:

```tsx
import { View } from 'react-native';
import { RichText } from 'react-native-fabric-rich-text/nativewind';

function ResponsiveCard() {
  return (
    <View className="@container">
      <RichText
        text="<p>Text adapts to container width</p>"
        className="text-sm @md:text-base @lg:text-lg"
      />
    </View>
  );
}
```

### Named Containers

```tsx
<View className="@container/card">
  <RichText
    text="<p>Named container</p>"
    className="text-sm @sm/card:text-base"
  />
</View>
```

## Troubleshooting

### Styles Not Applying

1. **Clear Metro cache**: `npx react-native start --reset-cache`
2. **Rebuild the app**: Delete `ios/build` and `android/build` folders
3. **Check content paths**: Ensure `tailwind.config.js` includes all relevant file paths

### "Cannot find module 'react-native-worklets/plugin'"

Install the required peer dependencies:

```bash
npm install react-native-reanimated react-native-worklets
```

In monorepo setups, you may need to install these at both the root and app level.

### "Unable to resolve module react-native-reanimated"

This runtime error means `react-native-reanimated` is missing. Install it:

```bash
npm install react-native-reanimated
```

### "Duplicate plugin/preset detected"

If you see this error, you may have both `nativewind/babel` preset and manual plugin configuration. Use one or the other, not both. We recommend the manual plugin configuration for better compatibility.

### Font Sizes Don't Match StyleSheet

NativeWind's default rem-based font sizes differ from React Native's pixel values. Add the `fontSize` and `lineHeight` overrides in your `tailwind.config.js` as shown in step 5.

### "className" prop not recognized in TypeScript

Add the type reference file as described in step 7.

### Tailwind CSS 4.x Compatibility

NativeWind 4.x does not yet support Tailwind CSS 4.x. Use Tailwind CSS 3.x:

```bash
npm install -D tailwindcss@">=3.3.0 <4.0.0"
```

## Example Project

See the [example app](../example/) for a complete working implementation with:

- Segmented control comparing StyleSheet vs NativeWind approaches
- All supported styling features
- Container query demonstrations
- Dark mode examples

## Additional Resources

- [NativeWind Documentation](https://www.nativewind.dev/)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [NativeWind GitHub](https://github.com/marklawlor/nativewind)
