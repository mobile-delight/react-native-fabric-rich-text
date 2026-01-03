import type { ViewProps, TextStyle } from 'react-native';
import type { DetectedContentType } from '../FabricHTMLTextNativeComponent';

/**
 * Props for the HTMLTextNative component.
 * Extends ViewProps to support standard view properties including accessibility.
 */
export interface HTMLTextNativeProps extends ViewProps {
  /** HTML string to render as native styled text */
  html: string;
  /** Optional text styling applied to the rendered content */
  style?: TextStyle | undefined;
  /** Optional test identifier for testing frameworks */
  testID?: string | undefined;
  /** Optional class name for NativeWind/web CSS styling */
  className?: string | undefined;
  /**
   * Optional callback fired when a link, email, or phone number is pressed.
   * @param url - The URL, email address, or phone number that was pressed
   * @param type - The type of content that was detected ('link', 'email', or 'phone')
   */
  onLinkPress?: ((url: string, type: DetectedContentType) => void) | undefined;
  /** Optional per-tag style overrides. Keys are HTML tag names, values are TextStyle objects. */
  tagStyles?: Record<string, TextStyle> | undefined;
  /** Whether to allow font scaling based on accessibility settings. Defaults to true. */
  allowFontScaling?: boolean | undefined;
  /** Android-only: Include font padding. Defaults to true. */
  includeFontPadding?: boolean | undefined;
  /** Maximum font size multiplier when allowFontScaling is enabled. 0 means no limit. */
  maxFontSizeMultiplier?: number | undefined;
  /**
   * Enable automatic URL/link detection. When true, URLs in the text will be
   * tappable even without explicit <a> tags. Defaults to false.
   */
  detectLinks?: boolean | undefined;
  /**
   * Enable automatic phone number detection. When true, phone numbers in the
   * text will be tappable. Defaults to false.
   */
  detectPhoneNumbers?: boolean | undefined;
  /**
   * Enable automatic email address detection. When true, email addresses in
   * the text will be tappable. Defaults to false.
   * Note: On iOS, enabling this also enables URL detection due to platform limitations.
   */
  detectEmails?: boolean | undefined;
}
