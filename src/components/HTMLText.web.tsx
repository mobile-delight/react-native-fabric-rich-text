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
  numberOfLines,
  writingDirection = 'auto',
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

  // Apply CSS line-clamp for truncation when numberOfLines > 0
  // The line-clamp styles must be applied directly to the text-containing elements,
  // not to a wrapper, for proper ellipsis behavior.
  const isTruncated = numberOfLines && numberOfLines > 0;
  const truncationStyle: React.CSSProperties = isTruncated
    ? { overflow: 'hidden' }
    : {};

  // Apply writing direction - 'auto' inherits from parent/system
  // Using CSS logical property 'start' which automatically adapts to direction:
  // - LTR: start = left
  // - RTL: start = right
  const directionStyle: React.CSSProperties =
    writingDirection === 'auto'
      ? {} // Inherit from parent
      : {
          direction: writingDirection,
          // Use CSS logical property for RTL-aware alignment
          textAlign: 'start',
        };

  // When truncating, apply line-clamp styles directly to block elements in the HTML.
  // This ensures the ellipsis appears correctly at the truncation point.
  const lineClampStyles = `display:-webkit-box;-webkit-line-clamp:${numberOfLines};-webkit-box-orient:vertical;overflow:hidden;margin:0;padding:0;`;
  const processedHtml = isTruncated
    ? sanitizedHtml.replace(
        /<(p|div|h[1-6]|blockquote|li|ul|ol)(\s|>)/gi,
        `<$1 style="${lineClampStyles}"$2`
      )
    : sanitizedHtml;

  return (
    <div
      ref={containerRef}
      className={className}
      style={{ ...cssStyle, ...truncationStyle, ...directionStyle }}
      dir={writingDirection === 'auto' ? undefined : writingDirection}
      data-testid={testID}
      onClick={onLinkPress ? handleClick : undefined}
      // nosemgrep: no-dangerous-innerhtml-without-sanitization - processedHtml is sanitized via DOMPurify (sanitizedHtml on line 75)
      dangerouslySetInnerHTML={{ __html: processedHtml }}
    />
  );
}
