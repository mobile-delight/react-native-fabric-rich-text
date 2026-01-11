import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  type ReactElement,
} from 'react';
import type { RichTextProps } from './RichText';
import { sanitize } from '../core/sanitize.web';
import { convertStyle } from '../adapters/web/StyleConverter';

// Module-level flag to warn only once across all RichText instances
let hasWarnedAboutDetection = false;

// Unique ID counter for aria-describedby references
let uniqueIdCounter = 0;

/**
 * Web-specific implementation of RichText using semantic HTML elements.
 * Renders sanitized HTML using dangerouslySetInnerHTML for proper semantic output.
 *
 * Note: Wraps sanitized HTML in a div to apply className, style, and testID props.
 * This adds an extra wrapper element around the HTML content.
 *
 * Detection props (detectLinks, detectPhoneNumbers, detectEmails) are accepted
 * for API compatibility but have limited functionality on web. Browsers handle
 * URL detection natively, and phone/email detection is not supported.
 */
/**
 * Counts the number of anchor tags in an HTML string.
 */
function countLinks(htmlString: string): number {
  const matches = htmlString.match(/<a\s[^>]*href\s*=/gi);
  return matches ? matches.length : 0;
}

// Escape a string for safe use in HTML attribute values
function escapeAttr(s: string): string {
  return s
    .replace(/&/g, '&amp;') // Must be first to avoid double-escaping
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * Adds aria-describedby attributes to links with position info.
 * Returns the modified HTML and the hidden description elements.
 */
function addLinkPositionInfo(
  htmlString: string,
  linkCount: number,
  instanceId: string
): { processedHtml: string; descriptionElements: string } {
  if (linkCount === 0) {
    return { processedHtml: htmlString, descriptionElements: '' };
  }

  let linkIndex = 0;
  const descIds: string[] = [];

  // Add aria-describedby to each link by matching the opening <a tag
  // Use a simpler pattern that inserts the attribute right after <a
  const processedHtml = htmlString.replace(/<a\s/gi, () => {
    linkIndex++;
    const descId = `${escapeAttr(instanceId)}-link-desc-${linkIndex}`;
    descIds.push(descId);
    return `<a aria-describedby="${descId}" `;
  });

  // Create hidden description elements for screen readers
  const descriptionElements = descIds
    .map(
      (id, index) =>
        `<span id="${id}" style="position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0;">Link ${
          index + 1
        } of ${linkCount}</span>`
    )
    .join('');

  return { processedHtml, descriptionElements };
}

export default function RichText({
  text,
  style,
  className,
  testID,
  onLinkPress,
  detectLinks,
  detectPhoneNumbers,
  detectEmails,
  numberOfLines,
  writingDirection = 'auto',
}: RichTextProps): ReactElement | null {
  const containerRef = useRef<HTMLDivElement>(null);

  // Generate a unique instance ID for aria-describedby references
  const instanceId = useMemo(() => {
    uniqueIdCounter++;
    return `richtext-${uniqueIdCounter}`;
  }, []);

  // Warn once in dev mode if detection props are used (limited functionality on web)
  useEffect(() => {
    if (
      !hasWarnedAboutDetection &&
      process.env.NODE_ENV !== 'production' &&
      (detectLinks || detectPhoneNumbers || detectEmails)
    ) {
      hasWarnedAboutDetection = true;
      console.warn(
        '[RichText] Detection props (detectLinks, detectPhoneNumbers, detectEmails) ' +
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

  if (!text) {
    return null;
  }

  const trimmedText = text.trim();
  if (!trimmedText) {
    return null;
  }

  const sanitizedText = sanitize(trimmedText);
  const cssStyle = convertStyle(style);

  // Count links in the sanitized text for accessibility
  const linkCount = countLinks(sanitizedText);

  // Apply CSS line-clamp for truncation when numberOfLines > 0
  // The line-clamp styles must be applied directly to the text-containing elements,
  // not to a wrapper, for proper ellipsis behavior.
  const isTruncated = numberOfLines && numberOfLines > 0;
  const truncationStyle: React.CSSProperties = isTruncated
    ? { overflow: 'hidden', position: 'relative' as const }
    : { position: 'relative' as const };

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

  // When truncating, apply line-clamp styles directly to block elements in the markup.
  // This ensures the ellipsis appears correctly at the truncation point.
  const lineClampStyles = `display:-webkit-box;-webkit-line-clamp:${numberOfLines};-webkit-box-orient:vertical;overflow:hidden;margin:0;padding:0;`;
  let processedMarkup = isTruncated
    ? sanitizedText.replace(
        /<(p|div|h[1-6]|blockquote|li|ul|ol)(\s|>)/gi,
        `<$1 style="${lineClampStyles}"$2`
      )
    : sanitizedText;

  // Add position info to links for screen readers (WCAG 2.4.4 Link Purpose)
  let descriptionElements = '';
  if (linkCount > 0) {
    const result = addLinkPositionInfo(processedMarkup, linkCount, instanceId);
    processedMarkup = result.processedHtml;
    descriptionElements = result.descriptionElements;
  }

  // Combine content with hidden description elements
  const finalMarkup = processedMarkup + descriptionElements;

  // Build ARIA attributes for screen reader navigation
  const ariaLabel =
    linkCount > 0
      ? `Contains ${linkCount} ${linkCount === 1 ? 'link' : 'links'}`
      : undefined;

  // Use role="group" when multiple links for semantic grouping
  const role = linkCount > 1 ? 'group' : undefined;

  return (
    <div
      ref={containerRef}
      className={className}
      style={{ ...cssStyle, ...truncationStyle, ...directionStyle }}
      dir={writingDirection === 'auto' ? undefined : writingDirection}
      data-testid={testID}
      onClick={onLinkPress ? handleClick : undefined}
      tabIndex={0}
      aria-label={ariaLabel}
      role={role}
      // nosemgrep: no-dangerous-innerhtml-without-sanitization - finalMarkup is sanitized via DOMPurify (sanitizedText above) with only safe accessibility attributes added
      dangerouslySetInnerHTML={{ __html: finalMarkup }}
    />
  );
}
