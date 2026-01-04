import DOMPurify from 'dompurify';

import { ALLOWED_TAGS, ALLOWED_ATTR } from './allowedHtml';

export { ALLOWED_TAGS, ALLOWED_ATTR };

/**
 * Sanitize HTML content using DOMPurify.
 *
 * This is the web-specific implementation that uses DOMPurify
 * for comprehensive XSS protection in browser environments.
 *
 * @param html - The HTML string to sanitize
 * @returns Sanitized HTML string safe for rendering
 */
export function sanitize(html: string | null | undefined): string {
  if (html === null || html === undefined || html === '') {
    return '';
  }

  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: [...ALLOWED_TAGS],
    ALLOWED_ATTR: [...ALLOWED_ATTR],
    ALLOW_DATA_ATTR: false,
  });
}
