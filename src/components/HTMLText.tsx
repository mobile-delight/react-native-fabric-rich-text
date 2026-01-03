import type { ReactElement } from 'react';
import type { TextStyle } from 'react-native';
import { sanitize } from '../core/sanitize';
import { HTMLTextNative } from '../adapters/native';
import type { DetectedContentType } from '../FabricHTMLTextNativeComponent';

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
}: HTMLTextProps): ReactElement | null {
  if (!html) {
    return null;
  }

  const trimmedHtml = html.trim();
  if (!trimmedHtml) {
    return null;
  }

  const sanitizedHtml = sanitize(html);

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
    />
  );
}
