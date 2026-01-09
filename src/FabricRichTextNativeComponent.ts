import {
  codegenNativeComponent,
  type ViewProps,
  type HostComponent,
} from 'react-native';
import type {
  DirectEventHandler,
  Float,
  Int32,
} from 'react-native/Libraries/Types/CodegenTypes';

/**
 * Type of content detected when a link is pressed.
 * - 'link': A URL or anchor tag
 * - 'email': An email address
 * - 'phone': A phone number
 */
export type DetectedContentType = 'link' | 'email' | 'phone';

type LinkPressEvent = Readonly<{
  url: string;
  // Inline string union for codegen compatibility (doesn't support type aliases)
  type: 'link' | 'email' | 'phone';
}>;

type LinkFocusChangeEvent = Readonly<{
  // -1 for container focus, >= 0 for link index
  focusedLinkIndex: Int32;
  // Empty string if no URL (codegen requires non-null for primitives)
  url: string;
  // 'link' | 'email' | 'phone' | 'detected' | '' (empty = no focus)
  type: string;
  // Total number of visible links
  totalLinks: Int32;
}>;

interface NativeProps extends ViewProps {
  html: string;
  // testID is inherited from ViewProps - do not redeclare here
  // as it breaks iOS accessibility identifier mapping in Fabric
  onLinkPress?: DirectEventHandler<LinkPressEvent>;
  tagStyles?: string | undefined;

  // Content detection props (all default to false)
  detectLinks?: boolean | undefined;
  detectPhoneNumbers?: boolean | undefined;
  detectEmails?: boolean | undefined;
  className?: string | undefined;

  // Text style props (following AndroidTextInput pattern)
  // These ensure C++ measurement and Kotlin/Swift rendering use identical values
  fontSize?: Float | undefined;
  lineHeight?: Float | undefined;
  fontWeight?: string | undefined;
  fontFamily?: string | undefined;
  fontStyle?: string | undefined;
  letterSpacing?: Float | undefined;
  textAlign?: string | undefined;
  includeFontPadding?: boolean | undefined;
  allowFontScaling?: boolean | undefined;
  maxFontSizeMultiplier?: Float | undefined;
  color?: Int32 | undefined; // Process with processColor before passing

  // numberOfLines feature props
  numberOfLines?: Int32 | undefined;
  animationDuration?: Float | undefined;

  // RTL text direction prop
  // 'ltr' = left-to-right, 'rtl' = right-to-left
  // Note: 'auto' is resolved in JS to explicit direction before passing to native
  writingDirection?: string | undefined;

  // Accessibility link focus event
  onLinkFocusChange?: DirectEventHandler<LinkFocusChangeEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'FabricRichText'
) as HostComponent<NativeProps>;
