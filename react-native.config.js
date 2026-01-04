/**
 * React Native configuration for autolinking.
 *
 * Uses custom CMakeLists.txt that includes codegen-generated sources,
 * custom ShadowNodes, and shared C++ code.
 *
 * @see https://github.com/reactwg/react-native-new-architecture/blob/main/docs/codegen.md
 */
module.exports = {
  dependency: {
    platforms: {
      android: {
        cmakeListsPath: 'jni/CMakeLists.txt',
      },
    },
  },
};
