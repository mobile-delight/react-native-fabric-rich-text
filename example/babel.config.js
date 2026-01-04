const path = require('path');
const { getConfig } = require('react-native-builder-bob/babel-config');
const pkg = require('../package.json');

const root = path.resolve(__dirname, '..');

const isTestEnv = process.env.NODE_ENV === 'test';

// NativeWind and worklets plugins don't work in Jest test environment
const nativewindPlugins = isTestEnv
  ? []
  : ['nativewind/babel', 'react-native-worklets/plugin'];

module.exports = getConfig(
  {
    presets: ['module:@react-native/babel-preset'],
    plugins: nativewindPlugins,
  },
  { root, pkg }
);
