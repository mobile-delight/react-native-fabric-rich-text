/**
 * @jest-environment jsdom
 */
import { sanitize, ALLOWED_TAGS, ALLOWED_ATTR } from '../sanitize.web';

/**
 * Web-specific sanitization tests using DOMPurify.
 *
 * These tests verify that all OWASP XSS vectors are neutralized
 * in the web environment where DOMPurify is available.
 */
describe('sanitize (web with DOMPurify)', () => {
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

    it('handles whitespace-only input', () => {
      expect(sanitize('   ')).toBe('   ');
    });
  });

  describe('Safe Content Pass-through', () => {
    it('preserves plain text', () => {
      const input = 'Just plain text with no tags';
      expect(sanitize(input)).toBe(input);
    });

    it('preserves allowed block elements', () => {
      const input = '<p>Paragraph</p><div>Division</div>';
      expect(sanitize(input)).toContain('<p>');
      expect(sanitize(input)).toContain('<div>');
    });

    it('preserves heading elements h1-h6', () => {
      const input =
        '<h1>H1</h1><h2>H2</h2><h3>H3</h3><h4>H4</h4><h5>H5</h5><h6>H6</h6>';
      expect(sanitize(input)).toContain('<h1>');
      expect(sanitize(input)).toContain('<h6>');
    });

    it('preserves inline formatting elements', () => {
      const input =
        '<strong>Bold</strong> <b>Bold2</b> <em>Italic</em> <i>Italic2</i>';
      expect(sanitize(input)).toContain('<strong>');
      expect(sanitize(input)).toContain('<b>');
      expect(sanitize(input)).toContain('<em>');
      expect(sanitize(input)).toContain('<i>');
    });

    it('preserves underline, strikethrough, and del elements', () => {
      const input = '<u>Underline</u> <s>Strike</s> <del>Deleted</del>';
      expect(sanitize(input)).toContain('<u>');
      expect(sanitize(input)).toContain('<s>');
      expect(sanitize(input)).toContain('<del>');
    });

    it('preserves span and br elements', () => {
      const input = '<span>Span text</span><br>';
      expect(sanitize(input)).toContain('<span>');
      expect(sanitize(input)).toContain('<br');
    });

    it('preserves blockquote and pre elements', () => {
      const input = '<blockquote>Quote</blockquote><pre>Code</pre>';
      expect(sanitize(input)).toContain('<blockquote>');
      expect(sanitize(input)).toContain('<pre>');
    });

    it('preserves list elements', () => {
      const input = '<ul><li>Item 1</li></ul><ol><li>Item 2</li></ol>';
      expect(sanitize(input)).toContain('<ul>');
      expect(sanitize(input)).toContain('<ol>');
      expect(sanitize(input)).toContain('<li>');
    });

    it('preserves anchor with safe href', () => {
      const input = '<a href="https://example.com">Link</a>';
      const output = sanitize(input);
      expect(output).toContain('<a');
      expect(output).toContain('href');
      expect(output).toContain('https://example.com');
    });

    it('preserves mailto: URLs', () => {
      const input = '<a href="mailto:test@example.com">Email</a>';
      const output = sanitize(input);
      expect(output).toContain('mailto:');
    });

    it('preserves tel: URLs', () => {
      const input = '<a href="tel:+1234567890">Call</a>';
      const output = sanitize(input);
      expect(output).toContain('tel:');
    });

    it('preserves class attribute', () => {
      // 'id' attribute removed per YAGNI - not used in rendering
      const input = '<div class="container">Content</div>';
      const output = sanitize(input);
      expect(output).toContain('class="container"');
    });

    it('preserves nested safe tags', () => {
      const input = '<p><strong><em>Bold and italic</em></strong></p>';
      const output = sanitize(input);
      expect(output).toContain('<p>');
      expect(output).toContain('<strong>');
      expect(output).toContain('<em>');
    });
  });

  describe('Script Injection (OWASP XSS Vectors)', () => {
    it('removes <script> tags', () => {
      const input = '<p>Safe<script>alert(1)</script></p>';
      const output = sanitize(input);
      expect(output).not.toContain('script');
      expect(output).toContain('Safe');
    });

    it('removes <SCRIPT> tags (case-insensitive)', () => {
      const input = '<SCRIPT>alert(1)</SCRIPT>';
      const output = sanitize(input);
      expect(output.toLowerCase()).not.toContain('script');
    });

    it('removes <script src="..."> tags', () => {
      const input = '<script src="evil.js"></script>';
      const output = sanitize(input);
      expect(output).not.toContain('script');
      expect(output).not.toContain('evil.js');
    });

    it('removes <svg onload="..."> injection', () => {
      const input = '<svg onload="alert(1)">';
      const output = sanitize(input);
      expect(output).not.toContain('onload');
      expect(output).not.toContain('alert');
    });

    it('removes nested script in svg', () => {
      const input = '<svg><script>alert(1)</script></svg>';
      const output = sanitize(input);
      expect(output).not.toContain('script');
    });

    it('removes script with line breaks', () => {
      const input = '<script\n>alert(1)</script>';
      const output = sanitize(input);
      expect(output.toLowerCase()).not.toContain('script');
    });
  });

  describe('Event Handler Injection (OWASP XSS Vectors)', () => {
    it('removes onerror handlers', () => {
      const input = '<img onerror="alert(1)" src="x">';
      const output = sanitize(input);
      expect(output).not.toContain('onerror');
      expect(output).not.toContain('alert');
    });

    it('removes onclick handlers', () => {
      const input = '<div onclick="alert(1)">click</div>';
      const output = sanitize(input);
      expect(output).not.toContain('onclick');
      expect(output).toContain('click');
    });

    it('removes onload handlers', () => {
      const input = '<body onload="alert(1)">';
      const output = sanitize(input);
      expect(output).not.toContain('onload');
    });

    it('removes onmouseover handlers', () => {
      const input = '<a onmouseover="alert(1)">hover</a>';
      const output = sanitize(input);
      expect(output).not.toContain('onmouseover');
    });

    it('removes onfocus handlers', () => {
      const input = '<input onfocus="alert(1)">';
      const output = sanitize(input);
      expect(output).not.toContain('onfocus');
    });

    it('removes mixed-case event handlers', () => {
      const input = '<div OnClIcK="alert(1)">test</div>';
      const output = sanitize(input);
      expect(output.toLowerCase()).not.toContain('onclick');
    });
  });

  describe('JavaScript URL Injection (OWASP XSS Vectors)', () => {
    it('removes javascript: URLs', () => {
      const input = '<a href="javascript:alert(1)">click</a>';
      const output = sanitize(input);
      expect(output).not.toContain('javascript');
    });

    it('removes mixed-case jAvAsCrIpT: URLs', () => {
      const input = '<a href="jAvAsCrIpT:alert(1)">click</a>';
      const output = sanitize(input);
      expect(output.toLowerCase()).not.toContain('javascript');
    });

    it('removes javascript with tab injection', () => {
      const input = '<a href="java\tscript:alert(1)">click</a>';
      const output = sanitize(input);
      expect(output).not.toContain('alert');
    });

    it('removes HTML-encoded javascript URLs', () => {
      const input = '<a href="&#106;avascript:alert(1)">click</a>';
      const output = sanitize(input);
      expect(output.toLowerCase()).not.toContain('javascript');
    });

    it('removes javascript with newline injection (decoded)', () => {
      // URL-decoded variant where \n is actual character
      const input = '<a href="java\nscript:alert(1)">click</a>';
      const output = sanitize(input);
      // DOMPurify removes the dangerous href when it can decode the protocol
      expect(output).not.toContain('alert(1)');
    });
  });

  describe('Data URL Injection (OWASP XSS Vectors)', () => {
    it('removes data: URLs with HTML content', () => {
      const input =
        '<a href="data:text/html,<script>alert(1)</script>">click</a>';
      const output = sanitize(input);
      expect(output).not.toContain('data:text/html');
    });

    it('removes data: URLs in iframe src', () => {
      const input = '<iframe src="data:text/html,<script>alert(1)</script>">';
      const output = sanitize(input);
      expect(output).not.toContain('iframe');
      expect(output).not.toContain('data:');
    });
  });

  describe('CSS Expression Attacks (Legacy IE)', () => {
    it('removes background javascript URL in style', () => {
      const input = '<div style="background:url(javascript:alert(1))">';
      const output = sanitize(input);
      expect(output).not.toContain('javascript');
    });

    it('removes CSS expression in style', () => {
      const input = '<div style="width:expression(alert(1))">';
      const output = sanitize(input);
      expect(output).not.toContain('expression');
    });

    it('removes style attributes with dangerous content', () => {
      const input = '<div style="behavior: url(xss.htc)">';
      const output = sanitize(input);
      expect(output).not.toContain('behavior');
    });
  });

  describe('Encoded XSS Variants', () => {
    it('handles HTML entity encoded event handlers', () => {
      const input = '<img src="x" onerror="&#97;lert(1)">';
      const output = sanitize(input);
      expect(output).not.toContain('onerror');
    });

    it('handles URL-encoded javascript in browser context', () => {
      // Note: URL-encoded %0a stays encoded in the href attribute
      // This is safe because browsers won't decode and execute it as javascript:
      // The actual decoded newline variant is tested above
      const input = '<a href="java%0ascript:alert(1)">click</a>';
      const output = sanitize(input);
      // Href may be preserved but browser won't execute it as javascript:
      // The critical protection is that decoded variants are caught
      expect(output).toContain('<a');
    });

    it('handles String.fromCharCode injection', () => {
      const input = '<script>alert(String.fromCharCode(88,83,83))</script>';
      const output = sanitize(input);
      expect(output).not.toContain('script');
    });
  });

  describe('Dangerous Tags Removal', () => {
    it('removes iframe tags', () => {
      const input = '<iframe src="https://evil.com"></iframe>';
      const output = sanitize(input);
      expect(output).not.toContain('iframe');
    });

    it('removes object tags', () => {
      const input = '<object data="malware.swf"></object>';
      const output = sanitize(input);
      expect(output).not.toContain('object');
    });

    it('removes embed tags', () => {
      const input = '<embed src="malware.swf">';
      const output = sanitize(input);
      expect(output).not.toContain('embed');
    });

    it('removes form tags', () => {
      const input = '<form action="https://evil.com"><input></form>';
      const output = sanitize(input);
      expect(output).not.toContain('form');
    });

    it('removes meta tags', () => {
      const input = '<meta http-equiv="refresh" content="0;url=evil.com">';
      const output = sanitize(input);
      expect(output).not.toContain('meta');
    });

    it('removes link tags', () => {
      const input = '<link rel="stylesheet" href="evil.css">';
      const output = sanitize(input);
      expect(output).not.toContain('link');
    });

    it('removes base tags', () => {
      const input = '<base href="https://evil.com/">';
      const output = sanitize(input);
      expect(output).not.toContain('base');
    });
  });

  describe('Dangerous Attributes Removal', () => {
    it('removes data-* attributes', () => {
      const input = '<div data-evil="payload">content</div>';
      const output = sanitize(input);
      expect(output).not.toContain('data-evil');
    });

    it('removes src attribute on disallowed tags', () => {
      const input = '<img src="https://track.evil.com/pixel.gif">';
      const output = sanitize(input);
      // img tag should be removed entirely as it's not in allowed tags
      expect(output).not.toContain('src');
    });

    it('removes formaction attribute', () => {
      const input = '<button formaction="https://evil.com">Submit</button>';
      const output = sanitize(input);
      expect(output).not.toContain('formaction');
    });

    it('removes srcdoc attribute', () => {
      const input = '<iframe srcdoc="<script>alert(1)</script>">';
      const output = sanitize(input);
      expect(output).not.toContain('srcdoc');
    });
  });

  describe('Allowed Tags Export', () => {
    it('exports ALLOWED_TAGS array', () => {
      expect(Array.isArray(ALLOWED_TAGS)).toBe(true);
      expect(ALLOWED_TAGS).toContain('p');
      expect(ALLOWED_TAGS).toContain('strong');
      expect(ALLOWED_TAGS).toContain('a');
    });

    it('ALLOWED_TAGS does not contain dangerous tags', () => {
      expect(ALLOWED_TAGS).not.toContain('script');
      expect(ALLOWED_TAGS).not.toContain('iframe');
      expect(ALLOWED_TAGS).not.toContain('object');
      expect(ALLOWED_TAGS).not.toContain('embed');
    });
  });

  describe('Allowed Attributes Export', () => {
    it('exports ALLOWED_ATTR array', () => {
      expect(Array.isArray(ALLOWED_ATTR)).toBe(true);
      expect(ALLOWED_ATTR).toContain('href');
      expect(ALLOWED_ATTR).toContain('class');
      // 'id' removed per YAGNI - not used in rendering (matches native sanitizers)
    });

    it('ALLOWED_ATTR does not contain dangerous attributes', () => {
      expect(ALLOWED_ATTR).not.toContain('onclick');
      expect(ALLOWED_ATTR).not.toContain('onerror');
      expect(ALLOWED_ATTR).not.toContain('onload');
    });
  });
});
