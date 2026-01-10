import type { ViewProps, TextStyle } from 'react-native';
import type { DetectedContentType } from '../FabricRichTextNativeComponent';

/**
 * Writing direction for text content.
 *
 * - 'auto': Inherit from I18nManager.isRTL (default)
 * - 'ltr': Force left-to-right direction
 * - 'rtl': Force right-to-left direction
 */
export type WritingDirection = 'auto' | 'ltr' | 'rtl';

/**
 * Type of focused link content.
 * Extends DetectedContentType with 'detected' for auto-detected content
 * where the specific type cannot be determined.
 */
export type LinkFocusType = DetectedContentType | 'detected';

/**
 * Event data for text measurement.
 */
export interface RichTextMeasurementData {
  /**
   * Total number of lines the text would occupy without truncation.
   */
  measuredLineCount: number;

  /**
   * Number of lines actually visible (after numberOfLines truncation).
   */
  visibleLineCount: number;
}

/**
 * Event data for link focus changes.
 */
export interface LinkFocusEvent {
  /**
   * Index of the currently focused link.
   * - -1: Container is focused
   * - 0+: Link at that index is focused
   * - null: Component has lost focus entirely
   */
  focusedLinkIndex: number | null;

  /**
   * URL of the focused link, or null if no link is focused.
   */
  url: string | null;

  /**
   * Type of the focused link.
   * - 'link': Standard URL
   * - 'email': Email address
   * - 'phone': Phone number
   * - 'detected': Auto-detected content (when type cannot be determined)
   * - null: No link focused
   */
  type: LinkFocusType | null;

  /**
   * Total number of visible (non-truncated) links in the component.
   */
  totalLinks: number;
}

/**
 * Props for the RichTextNative component.
 * Extends ViewProps to support standard view properties including accessibility.
 */
export interface RichTextNativeProps extends ViewProps {
  /** Markup string to render as native styled text */
  text: string;
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
  /**
   * Maximum number of lines to display before truncating with ellipsis.
   *
   * - `0` (default): No limit, all content is displayed
   * - Positive integer: Limits visible lines to this count
   * - Negative values: Treated as 0 (no limit)
   *
   * When content exceeds the limit, a trailing ellipsis (...) is shown.
   */
  numberOfLines?: number | undefined;
  /**
   * Duration in seconds for animating height changes when numberOfLines changes.
   *
   * - Positive value: Smooth height animation over this duration
   * - `0` or negative: Instant height change (no animation)
   *
   * Uses ease-in-out timing curve on both platforms.
   * @default 0.2
   */
  animationDuration?: number | undefined;
  /**
   * Base writing direction for all content.
   *
   * - 'auto': Uses I18nManager.isRTL to determine direction (default)
   * - 'ltr': Forces left-to-right direction
   * - 'rtl': Forces right-to-left direction
   *
   * HTML elements with explicit `dir` attribute will override this setting.
   * @default 'auto'
   */
  writingDirection?: WritingDirection | undefined;

  /**
   * Callback fired when accessibility focus moves between links.
   * Fires for both user-initiated (screen reader gestures, keyboard navigation)
   * and programmatic focus changes.
   *
   * @param event - Contains information about the newly focused link
   */
  onLinkFocusChange?: ((event: LinkFocusEvent) => void) | undefined;

  /**
   * Callback fired when the text has been measured and laid out.
   * Provides information about line counts for truncation detection.
   *
   * @param data - Contains measured and visible line counts
   */
  onRichTextMeasurement?: ((data: RichTextMeasurementData) => void) | undefined;
}
