const path = require('path');
const nextJest = require('next/jest');

const createJestConfig = nextJest({
  dir: './',
});

// Ensure all React imports resolve to example-web's React 18
const reactPath = path.resolve(__dirname, 'node_modules/react');
const reactDomPath = path.resolve(__dirname, 'node_modules/react-dom');

// Resolve library path relative to this config file
const libWebPath = path.resolve(__dirname, '../lib/module/index.web.js');

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.ts'],
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
    // Map to built web-specific entry point (includes sanitize, ALLOWED_TAGS, etc.)
    // This MUST come before tsconfig paths to override them
    '^react-native-fabric-rich-text$': libWebPath,
    // Force all React imports to use example-web's React 18
    '^react$': reactPath,
    '^react/(.*)$': `${reactPath}/$1`,
    '^react-dom$': reactDomPath,
    '^react-dom/(.*)$': `${reactDomPath}/$1`,
  },
  testMatch: ['**/__tests__/**/*.test.{ts,tsx}'],
  collectCoverageFrom: [
    'app/**/*.{ts,tsx}',
    'components/**/*.{ts,tsx}',
    '!**/*.d.ts',
  ],
  coverageThreshold: {
    // Lower thresholds for example app - it's demo code, not production
    // Core library tests are in the root package
    global: {
      branches: 30,
      functions: 25,
      lines: 35,
      statements: 35,
    },
  },
};

// Wrap with next/jest but ensure our moduleNameMapper takes precedence
module.exports = async () => {
  const nextJestConfig = await createJestConfig(customJestConfig)();

  // Override the library path mapping (next/jest adds tsconfig paths)
  nextJestConfig.moduleNameMapper = {
    ...nextJestConfig.moduleNameMapper,
    '^react-native-fabric-rich-text$': libWebPath,
  };

  return nextJestConfig;
};
