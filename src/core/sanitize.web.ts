import DOMPurify from 'dompurify';

import { ALLOWED_TAGS, ALLOWED_ATTR } from './allowedHtml';

export { ALLOWED_TAGS, ALLOWED_ATTR };

// Pre-compute DOMPurify options
const DOMPURIFY_OPTIONS = {
  ALLOWED_TAGS: [...ALLOWED_TAGS],
  ALLOWED_ATTR: [...ALLOWED_ATTR],
  ALLOW_DATA_ATTR: false,
};

// Pre-compute sanitize-html options (used server-side only)
const SANITIZE_HTML_OPTIONS = {
  allowedTags: [...ALLOWED_TAGS],
  allowedAttributes: {
    a: ['href', 'target', 'rel'],
    img: ['src', 'alt', 'width', 'height'],
    '*': ALLOWED_ATTR.filter(
      (attr) =>
        !['href', 'target', 'rel', 'src', 'alt', 'width', 'height'].includes(
          attr
        )
    ),
  },
  disallowedTagsMode: 'discard' as const,
};

// Lazy-load sanitize-html only on server (avoids bundling for client)
let sanitizeHtmlFn: ((html: string, options: object) => string) | null = null;

function getSanitizeHtml(): (html: string, options: object) => string {
  if (sanitizeHtmlFn === null) {
    // Dynamic require for server-side only (webpack aliases to false on client)
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    sanitizeHtmlFn = require('sanitize-html');
  }
  return sanitizeHtmlFn!;
}

/**
 * Sanitize HTML content for web environments.
 *
 * Uses environment-appropriate sanitizer:
 * - Browser: DOMPurify (peer dependency) - uses native DOM
 * - Server/SSR: sanitize-html (peer dependency) - Node.js native
 *
 * @param html - The HTML string to sanitize
 * @returns Sanitized HTML string safe for rendering
 */
export function sanitize(html: string | null | undefined): string {
  if (html === null || html === undefined || html === '') {
    return '';
  }

  if (typeof window !== 'undefined') {
    // Browser environment - use DOMPurify
    return DOMPurify.sanitize(html, DOMPURIFY_OPTIONS);
  } else {
    // Server environment - use sanitize-html
    const sanitizeHtml = getSanitizeHtml();
    return sanitizeHtml(html, SANITIZE_HTML_OPTIONS);
  }
}
