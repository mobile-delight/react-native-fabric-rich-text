import {
  FabricHTMLText,
  HTMLText,
  sanitize,
  ALLOWED_TAGS,
  ALLOWED_ATTR,
  type DetectedContentType,
} from '../index';

describe('Library exports', () => {
  it('exports FabricHTMLText component', () => {
    expect(FabricHTMLText).toBeDefined();
  });

  it('exports HTMLText component', () => {
    expect(HTMLText).toBeDefined();
    expect(typeof HTMLText).toBe('function');
  });

  it('exports sanitize function', () => {
    expect(sanitize).toBeDefined();
    expect(typeof sanitize).toBe('function');
  });

  it('exports ALLOWED_TAGS array', () => {
    expect(ALLOWED_TAGS).toBeDefined();
    expect(Array.isArray(ALLOWED_TAGS)).toBe(true);
  });

  it('exports ALLOWED_ATTR array', () => {
    expect(ALLOWED_ATTR).toBeDefined();
    expect(Array.isArray(ALLOWED_ATTR)).toBe(true);
  });

  it('DetectedContentType type is exported', () => {
    // Type-only test: verify the type exists at compile time
    const linkType: DetectedContentType = 'link';
    const emailType: DetectedContentType = 'email';
    const phoneType: DetectedContentType = 'phone';
    expect(linkType).toBe('link');
    expect(emailType).toBe('email');
    expect(phoneType).toBe('phone');
  });
});
