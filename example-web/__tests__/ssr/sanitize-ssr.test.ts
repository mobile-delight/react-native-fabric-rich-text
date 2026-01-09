/**
 * SSR compatibility tests for the sanitize function.
 *
 * These tests verify that HTML sanitization works correctly in both
 * browser and server (Node.js) environments.
 */

// Note: We import the sanitize function directly from the library's web module
// This tests the dual-sanitizer approach:
// - Server: sanitize-html (Node.js native)
// - Browser: DOMPurify (uses native DOM)

describe('Sanitize - SSR Compatibility', () => {
  // In jsdom test environment, window is defined, so DOMPurify is used
  // These tests verify the output is correct regardless of which sanitizer is used

  it('sanitizes script tags consistently', async () => {
    const { sanitize } = await import('react-native-fabric-rich-text');
    const malicious = '<p>Safe</p><script>alert("xss")</script>';
    const result = sanitize(malicious);

    expect(result).toContain('Safe');
    expect(result).not.toContain('<script>');
    expect(result).not.toContain('alert');
  });

  it('sanitizes event handlers consistently', async () => {
    const { sanitize } = await import('react-native-fabric-rich-text');
    const malicious = '<p onclick="alert(1)" onmouseover="evil()">Click me</p>';
    const result = sanitize(malicious);

    expect(result).toContain('Click me');
    expect(result).not.toContain('onclick');
    expect(result).not.toContain('onmouseover');
    expect(result).not.toContain('alert');
  });

  it('preserves safe HTML tags', async () => {
    const { sanitize } = await import('react-native-fabric-rich-text');
    const safe = '<p>Hello <strong>bold</strong> and <em>italic</em></p>';
    const result = sanitize(safe);

    expect(result).toContain('<p>');
    expect(result).toContain('<strong>');
    expect(result).toContain('<em>');
    expect(result).toContain('Hello');
    expect(result).toContain('bold');
    expect(result).toContain('italic');
  });

  it('handles empty/null input consistently', async () => {
    const { sanitize } = await import('react-native-fabric-rich-text');

    expect(sanitize('')).toBe('');
    expect(sanitize(null as unknown as string)).toBe('');
    expect(sanitize(undefined as unknown as string)).toBe('');
  });

  it('preserves safe links', async () => {
    const { sanitize } = await import('react-native-fabric-rich-text');
    const html = '<a href="https://example.com">Link</a>';
    const result = sanitize(html);

    expect(result).toContain('href="https://example.com"');
    expect(result).toContain('Link');
  });

  it('strips javascript: URLs', async () => {
    const { sanitize } = await import('react-native-fabric-rich-text');
    const malicious = '<a href="javascript:alert(1)">Click</a>';
    const result = sanitize(malicious);

    expect(result).not.toContain('javascript:');
    // The link text should still be preserved (either as text or in a sanitized anchor)
    expect(result).toContain('Click');
  });

  it('handles complex nested HTML', async () => {
    const { sanitize } = await import('react-native-fabric-rich-text');
    const complex = `
      <div>
        <h1>Title</h1>
        <p>Paragraph with <a href="https://example.com">link</a></p>
        <ul>
          <li>Item 1</li>
          <li>Item 2</li>
        </ul>
      </div>
    `;
    const result = sanitize(complex);

    expect(result).toContain('<h1>');
    expect(result).toContain('Title');
    expect(result).toContain('<p>');
    expect(result).toContain('<a');
    expect(result).toContain('<ul>');
    expect(result).toContain('<li>');
  });
});

describe('Sanitize - Allowed Tags Export', () => {
  it('exports ALLOWED_TAGS array', async () => {
    const { ALLOWED_TAGS } = await import('react-native-fabric-rich-text');

    expect(Array.isArray(ALLOWED_TAGS)).toBe(true);
    expect(ALLOWED_TAGS).toContain('p');
    expect(ALLOWED_TAGS).toContain('a');
    expect(ALLOWED_TAGS).toContain('strong');
    expect(ALLOWED_TAGS).toContain('em');
    expect(ALLOWED_TAGS).toContain('ul');
    expect(ALLOWED_TAGS).toContain('ol');
    expect(ALLOWED_TAGS).toContain('li');
  });

  it('exports ALLOWED_ATTR array', async () => {
    const { ALLOWED_ATTR } = await import('react-native-fabric-rich-text');

    expect(Array.isArray(ALLOWED_ATTR)).toBe(true);
    expect(ALLOWED_ATTR).toContain('href');
    expect(ALLOWED_ATTR).toContain('class');
  });
});
