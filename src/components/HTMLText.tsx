import type { ReactElement } from 'react';
import type { TextStyle } from 'react-native';
import { I18nManager } from 'react-native';
import { sanitize } from '../core/sanitize';
import { HTMLTextNative } from '../adapters/native';
import type { DetectedContentType } from '../FabricHTMLTextNativeComponent';
import type { WritingDirection } from '../types/HTMLTextNativeProps';

export interface HTMLTextProps {
  /** HTML string to render */
  html: string;
  /** Optional text styling applied to the rendered content */
  style?: TextStyle | undefined;
  /** Optional class name for NativeWind/web CSS styling */
  className?: string | undefined;
  /** Optional test identifier for testing frameworks */
  testID?: string | undefined;
  /**
   * Optional callback fired when a link, email, or phone number is pressed.
   * @param url - The URL, email address, or phone number that was pressed
   * @param type - The type of content that was detected ('link', 'email', or 'phone')
   */
  onLinkPress?: ((url: string, type: DetectedContentType) => void) | undefined;
  /** Optional per-tag style overrides. Keys are HTML tag names, values are TextStyle objects. */
  tagStyles?: Record<string, TextStyle> | undefined;
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
}

export default function HTMLText({
  html,
  style,
  testID,
  className,
  onLinkPress,
  tagStyles,
  detectLinks,
  detectPhoneNumbers,
  detectEmails,
  numberOfLines,
  animationDuration,
  writingDirection = 'auto',
}: HTMLTextProps): ReactElement | null {
  if (!html) {
    return null;
  }

  const trimmedHtml = html.trim();
  if (!trimmedHtml) {
    return null;
  }

  const sanitizedHtml = sanitize(html);

  // Resolve 'auto' to explicit direction using I18nManager
  const resolvedDirection: 'ltr' | 'rtl' =
    writingDirection === 'auto'
      ? I18nManager.isRTL
        ? 'rtl'
        : 'ltr'
      : writingDirection;

  return (
    <HTMLTextNative
      html={sanitizedHtml}
      style={style}
      testID={testID}
      className={className}
      onLinkPress={onLinkPress}
      tagStyles={tagStyles}
      detectLinks={detectLinks}
      detectPhoneNumbers={detectPhoneNumbers}
      detectEmails={detectEmails}
      numberOfLines={numberOfLines}
      animationDuration={animationDuration}
      writingDirection={resolvedDirection}
    />
  );
}
