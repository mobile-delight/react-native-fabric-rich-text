module.exports = {
  preset: 'react-native',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  moduleNameMapper: {
    '^react-native-fabric-html-text$':
      '<rootDir>/__mocks__/react-native-fabric-html-text.js',
    '^react-native-fabric-html-text/nativewind$':
      '<rootDir>/__mocks__/react-native-fabric-html-text-nativewind.js',
    '\\.css$': '<rootDir>/__mocks__/styleMock.js',
  },
};
