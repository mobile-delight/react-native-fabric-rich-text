module.exports = {
  preset: 'react-native',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  transform: {
    '^.+\\.(js|jsx|ts|tsx)$': 'babel-jest',
  },
  transformIgnorePatterns: [
    'node_modules/(?!(react-native|@react-native|react-native-.*|@react-native-community)/)',
  ],
  moduleNameMapper: {
    '^react-native-fabric-rich-text$':
      '<rootDir>/__mocks__/react-native-fabric-rich-text.js',
    '^react-native-fabric-rich-text/nativewind$':
      '<rootDir>/__mocks__/react-native-fabric-rich-text-nativewind.js',
    '\\.css$': '<rootDir>/__mocks__/styleMock.js',
  },
};
