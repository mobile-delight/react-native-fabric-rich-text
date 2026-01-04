import { ALLOWED_TAGS, ALLOWED_ATTR } from '../allowedHtml';

describe('allowedHtml', () => {
  describe('ALLOWED_TAGS', () => {
    it('is a readonly array', () => {
      expect(Array.isArray(ALLOWED_TAGS)).toBe(true);
    });

    it('contains all expected block elements', () => {
      const blockElements = [
        'p',
        'div',
        'h1',
        'h2',
        'h3',
        'h4',
        'h5',
        'h6',
        'blockquote',
        'pre',
      ];
      for (const tag of blockElements) {
        expect(ALLOWED_TAGS).toContain(tag);
      }
    });

    it('contains all expected inline elements', () => {
      const inlineElements = [
        'strong',
        'b',
        'em',
        'i',
        'u',
        's',
        'del',
        'span',
        'br',
        'a',
      ];
      for (const tag of inlineElements) {
        expect(ALLOWED_TAGS).toContain(tag);
      }
    });

    it('contains all expected list elements', () => {
      expect(ALLOWED_TAGS).toContain('ul');
      expect(ALLOWED_TAGS).toContain('ol');
      expect(ALLOWED_TAGS).toContain('li');
    });

    it('does not contain dangerous tags', () => {
      const dangerousTags = [
        'script',
        'iframe',
        'object',
        'embed',
        'form',
        'meta',
        'link',
        'base',
        'img',
      ];
      for (const tag of dangerousTags) {
        expect(ALLOWED_TAGS).not.toContain(tag);
      }
    });
  });

  describe('ALLOWED_ATTR', () => {
    it('is a readonly array', () => {
      expect(Array.isArray(ALLOWED_ATTR)).toBe(true);
    });

    it('contains exactly the expected attributes', () => {
      // 'id' removed per YAGNI - not used in rendering (matches native sanitizers)
      expect(ALLOWED_ATTR).toHaveLength(2);
      expect(ALLOWED_ATTR).toContain('href');
      expect(ALLOWED_ATTR).toContain('class');
    });

    it('does not contain dangerous attributes', () => {
      const dangerousAttrs = [
        'onclick',
        'onerror',
        'onload',
        'onmouseover',
        'src',
        'style',
      ];
      for (const attr of dangerousAttrs) {
        expect(ALLOWED_ATTR).not.toContain(attr);
      }
    });
  });
});
