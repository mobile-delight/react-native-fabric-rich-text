import { useCallback, useEffect, useRef, type ReactElement } from 'react';
import type { HTMLTextProps } from './HTMLText';
import { sanitize } from '../core/sanitize.web';
import { convertStyle } from '../adapters/web/StyleConverter';

// Module-level flag to warn only once across all HTMLText instances
let hasWarnedAboutDetection = false;

/**
 * Web-specific implementation of HTMLText using semantic HTML elements.
 * Renders sanitized HTML using dangerouslySetInnerHTML for proper semantic output.
 *
 * Note: Wraps sanitized HTML in a div to apply className, style, and testID props.
 * This adds an extra wrapper element around the HTML content.
 *
 * Detection props (detectLinks, detectPhoneNumbers, detectEmails) are accepted
 * for API compatibility but have limited functionality on web. Browsers handle
 * URL detection natively, and phone/email detection is not supported.
 */
export default function HTMLText({
  html,
  style,
  className,
  testID,
  onLinkPress,
  detectLinks,
  detectPhoneNumbers,
  detectEmails,
}: HTMLTextProps): ReactElement | null {
  const containerRef = useRef<HTMLDivElement>(null);

  // Warn once in dev mode if detection props are used (limited functionality on web)
  useEffect(() => {
    if (
      !hasWarnedAboutDetection &&
      process.env.NODE_ENV !== 'production' &&
      (detectLinks || detectPhoneNumbers || detectEmails)
    ) {
      hasWarnedAboutDetection = true;
      console.warn(
        '[HTMLText] Detection props (detectLinks, detectPhoneNumbers, detectEmails) ' +
          'have limited functionality on web. Links work via native <a> tags. ' +
          'Phone and email detection are not supported on web.'
      );
    }
  }, [detectLinks, detectPhoneNumbers, detectEmails]);

  // Handle link clicks if onLinkPress is provided
  const handleClick = useCallback(
    (event: React.MouseEvent<HTMLDivElement>): void => {
      if (!onLinkPress) {
        return;
      }

      const target = event.target as HTMLElement;
      const anchor = target.closest('a');
      if (anchor && anchor.href) {
        event.preventDefault();
        onLinkPress(anchor.href, 'link');
      }
    },
    [onLinkPress]
  );

  if (!html) {
    return null;
  }

  const trimmedHtml = html.trim();
  if (!trimmedHtml) {
    return null;
  }

  const sanitizedHtml = sanitize(trimmedHtml);
  const cssStyle = convertStyle(style);

  return (
    <div
      ref={containerRef}
      className={className}
      style={cssStyle}
      data-testid={testID}
      onClick={onLinkPress ? handleClick : undefined}
      dangerouslySetInnerHTML={{ __html: sanitizedHtml }}
    />
  );
}
