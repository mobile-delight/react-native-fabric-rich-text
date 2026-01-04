/**
 * Type declarations for React Native codegen types.
 * These types are used for native component event handlers.
 */
declare module 'react-native/Libraries/Types/CodegenTypes' {
  export type DirectEventHandler<T extends object> = (event: {
    nativeEvent: T;
  }) => void;

  export type BubblingEventHandler<T extends object> = (event: {
    nativeEvent: T;
  }) => void;

  export type Int32 = number;

  export type Float = number;

  export type Double = number;
}
