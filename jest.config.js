/** @type {import('jest').Config} */
module.exports = {
  projects: [
    // React Native tests (default)
    {
      displayName: 'native',
      preset: 'react-native',
      modulePathIgnorePatterns: ['<rootDir>/example/', '<rootDir>/lib/'],
      testMatch: ['**/__tests__/**/*.test.[jt]s?(x)', '**/*.spec.[jt]s?(x)'],
      testPathIgnorePatterns: [
        '/node_modules/',
        '\\.web\\.test\\.[jt]sx?$',
        '<rootDir>/native-tests/',
        '<rootDir>/e2e/',
      ],
      collectCoverageFrom: [
        'src/**/*.{ts,tsx}',
        '!src/**/*.d.ts',
        '!src/**/index.ts',
        '!src/**/*.web.ts',
      ],
      setupFilesAfterEnv: ['@testing-library/jest-native/extend-expect'],
    },
    // Web tests (jsdom environment)
    {
      displayName: 'web',
      testEnvironment: 'jsdom',
      modulePathIgnorePatterns: ['<rootDir>/example/', '<rootDir>/lib/'],
      testMatch: ['**/*.web.test.[jt]s?(x)'],
      testPathIgnorePatterns: [
        '/node_modules/',
        '<rootDir>/native-tests/',
        '<rootDir>/e2e/',
      ],
      collectCoverageFrom: ['src/**/*.web.{ts,tsx}'],
      transform: {
        '^.+\\.(ts|tsx)$': [
          'babel-jest',
          { presets: ['@react-native/babel-preset'] },
        ],
      },
      resolver: '<rootDir>/jest.resolver.web.js',
    },
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov'],
};
