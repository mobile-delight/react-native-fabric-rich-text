import { sanitize, ALLOWED_TAGS, ALLOWED_ATTR } from '../sanitize';

/**
 * Sanitize function tests for React Native environment.
 *
 * In React Native (no DOM), the sanitize function is a pass-through.
 * Actual sanitization happens at the native layer:
 * - iOS: SwiftSoup before NSAttributedString parsing
 * - Android: OWASP before Html.fromHtml()
 *
 * These tests verify pass-through behavior in non-DOM environments.
 * See sanitize.web.test.ts for DOMPurify tests in DOM environments.
 */
describe('sanitize (React Native pass-through)', () => {
  describe('Edge Cases', () => {
    it('returns empty string for null input', () => {
      expect(sanitize(null as unknown as string)).toBe('');
    });

    it('returns empty string for undefined input', () => {
      expect(sanitize(undefined as unknown as string)).toBe('');
    });

    it('returns empty string for empty string input', () => {
      expect(sanitize('')).toBe('');
    });
  });

  describe('Pass-through Behavior (React Native)', () => {
    it('returns HTML content unchanged in non-DOM environment', () => {
      const input = '<p><strong>Bold</strong> and <em>italic</em></p>';
      expect(sanitize(input)).toBe(input);
    });

    it('returns plain text unchanged', () => {
      const input = 'Just plain text with no tags';
      expect(sanitize(input)).toBe(input);
    });

    it('returns links with href unchanged', () => {
      const input = '<a href="https://example.com">Link</a>';
      expect(sanitize(input)).toBe(input);
    });

    it('preserves nested tags', () => {
      const input = '<p><strong><em>Text</em></strong></p>';
      expect(sanitize(input)).toBe(input);
    });

    it('preserves whitespace and formatting', () => {
      const input = '<p>Line1<br/>Line2</p>';
      expect(sanitize(input)).toBe(input);
    });
  });

  describe('Exports', () => {
    it('exports ALLOWED_TAGS array with all permitted tags', () => {
      expect(Array.isArray(ALLOWED_TAGS)).toBe(true);
      expect(ALLOWED_TAGS).toContain('p');
      expect(ALLOWED_TAGS).toContain('div');
      expect(ALLOWED_TAGS).toContain('strong');
      expect(ALLOWED_TAGS).toContain('em');
      expect(ALLOWED_TAGS).toContain('a');
      expect(ALLOWED_TAGS).toContain('h1');
      expect(ALLOWED_TAGS).toContain('h6');
      expect(ALLOWED_TAGS).toContain('ul');
      expect(ALLOWED_TAGS).toContain('ol');
      expect(ALLOWED_TAGS).toContain('li');
      expect(ALLOWED_TAGS).toContain('blockquote');
      expect(ALLOWED_TAGS).toContain('pre');
    });

    it('exports ALLOWED_ATTR array with permitted attributes', () => {
      expect(Array.isArray(ALLOWED_ATTR)).toBe(true);
      expect(ALLOWED_ATTR).toContain('href');
      expect(ALLOWED_ATTR).toContain('class');
      // 'id' removed per YAGNI - not used in rendering (matches native sanitizers)
    });
  });
});
