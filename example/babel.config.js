const path = require('path');
const { getConfig } = require('react-native-builder-bob/babel-config');
const pkg = require('../package.json');

const root = path.resolve(__dirname, '..');

const isTestEnv = process.env.NODE_ENV === 'test';

// In test environment, skip NativeWind preset and worklets plugin (they cause Jest issues)
const nativewindPresets = isTestEnv ? [] : ['nativewind/babel'];
const nativewindPlugins = isTestEnv ? [] : ['react-native-worklets/plugin'];

module.exports = getConfig(
  {
    presets: [
      'module:@react-native/babel-preset',
      // NativeWind babel preset (must be a preset, not plugin)
      ...nativewindPresets,
    ],
    plugins: [
      // react-native-worklets/plugin is required by NativeWind's css-interop
      ...nativewindPlugins,
    ],
  },
  { root, pkg },
);
