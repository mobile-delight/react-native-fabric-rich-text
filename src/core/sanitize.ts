export { ALLOWED_TAGS, ALLOWED_ATTR } from './allowedHtml';

/**
 * Sanitize HTML content.
 *
 * Security Strategy:
 * - React Native: Pass-through (native sanitization in Swift/Kotlin)
 *   - iOS: SwiftSoup before NSAttributedString parsing
 *   - Android: OWASP before Html.fromHtml()
 * - Web: Uses sanitize.web.ts with DOMPurify (platform-specific import)
 *
 * @param html - The HTML string to sanitize
 * @returns HTML string (sanitized on web, pass-through on native)
 */
export function sanitize(html: string | null | undefined): string {
  if (html === null || html === undefined || html === '') {
    return '';
  }

  // In React Native, pass through - native layer handles sanitization
  return html;
}
