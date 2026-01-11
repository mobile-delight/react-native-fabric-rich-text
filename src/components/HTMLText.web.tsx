import {
  useCallback,
  useEffect,
  useId,
  useRef,
  type ReactElement,
} from 'react';
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

  // Generate a unique instance ID for aria-describedby references
  // Using useId() to avoid side effects during render
  const instanceId = useId();

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

  // Post-render DOM manipulation for accessibility and truncation
  useEffect(() => {
    if (!containerRef.current) return;

    const container = containerRef.current;
    const links = container.querySelectorAll('a');

    // Add position info to links for screen readers
    if (links.length > 0) {
      links.forEach((link, index) => {
        const descId = `${instanceId}-link-desc-${index + 1}`;

        // Add aria-describedby to link
        link.setAttribute('aria-describedby', descId);

        // Create hidden description element
        const descSpan = document.createElement('span');
        descSpan.id = descId;
        descSpan.style.cssText =
          'position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0;';
        descSpan.textContent = `Link ${index + 1} of ${links.length}`;

        // Append to container
        container.appendChild(descSpan);
      });
    }

    // Apply line-clamp styles for truncation via className
    if (numberOfLines && numberOfLines > 0) {
      const blockElements = container.querySelectorAll(
        'p, div, h1, h2, h3, h4, h5, h6, blockquote, li, ul, ol'
      );
      blockElements.forEach((element) => {
        const htmlElement = element as HTMLElement;
        htmlElement.style.display = '-webkit-box';
        htmlElement.style.webkitLineClamp = String(numberOfLines);
        htmlElement.style.webkitBoxOrient = 'vertical';
        htmlElement.style.overflow = 'hidden';
        htmlElement.style.margin = '0';
        htmlElement.style.padding = '0';
      });
    }

    // Cleanup function
    return () => {
      // Remove added description elements
      const descElements = container.querySelectorAll(
        `[id^="${instanceId}-link-desc-"]`
      );
      descElements.forEach((el) => el.remove());
    };
  }, [html, numberOfLines, instanceId]);

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

  const cssStyle = convertStyle(style);

  // Sanitize HTML once - used for link counting and dangerouslySetInnerHTML
  const sanitizedHtml = sanitize(trimmedHtml);

  // Count links for ARIA attributes using DOM parsing
  // This is more robust than regex and handles edge cases like newlines in attributes
  let linkCount = 0;
  if (typeof DOMParser !== 'undefined') {
    try {
      const parser = new DOMParser();
      const doc = parser.parseFromString(sanitizedHtml, 'text/html');
      linkCount = doc.querySelectorAll('a[href]').length;
    } catch {
      // Fallback: count won't be set, which results in no ARIA label
      linkCount = 0;
    }
  }

  // Apply CSS for truncation container
  const isTruncated = numberOfLines && numberOfLines > 0;
  const truncationStyle: React.CSSProperties = isTruncated
    ? { overflow: 'hidden', position: 'relative' as const }
    : { position: 'relative' as const };

  // Apply writing direction
  const directionStyle: React.CSSProperties =
    writingDirection === 'auto'
      ? {}
      : {
          direction: writingDirection,
          textAlign: 'start',
        };

  // Build ARIA description for screen reader navigation
  // Using aria-describedby to preserve native semantics (aria-label replaces accessible name)
  const linkCountDescId =
    linkCount > 0 ? `${instanceId}-link-count` : undefined;
  const linkCountDesc =
    linkCount > 0
      ? `Contains ${linkCount} ${linkCount === 1 ? 'link' : 'links'}`
      : undefined;

  // Visually hidden style for screen reader-only content
  const visuallyHiddenStyle: React.CSSProperties = {
    position: 'absolute',
    width: '1px',
    height: '1px',
    padding: 0,
    margin: '-1px',
    overflow: 'hidden',
    clip: 'rect(0, 0, 0, 0)',
    whiteSpace: 'nowrap',
    border: 0,
  };

  return (
    <>
      <div
        ref={containerRef}
        className={className}
        style={{ ...cssStyle, ...truncationStyle, ...directionStyle }}
        dir={writingDirection === 'auto' ? undefined : writingDirection}
        data-testid={testID}
        onClick={onLinkPress ? handleClick : undefined}
        // Container is not keyboard focusable since nested links are natively focusable
        // This prevents duplicate tab stops (container + individual links)
        tabIndex={-1}
        aria-describedby={linkCountDescId}
        // SAFETY: sanitize() uses DOMPurify (browser) or sanitize-html (SSR) - see sanitize.web.ts
        dangerouslySetInnerHTML={{ __html: sanitizedHtml }}
      />
      {linkCountDesc && (
        <span id={linkCountDescId} style={visuallyHiddenStyle}>
          {linkCountDesc}
        </span>
      )}
    </>
  );
}
