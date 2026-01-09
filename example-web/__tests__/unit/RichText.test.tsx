import { render, screen, fireEvent } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import RichText from 'react-native-fabric-rich-text';

expect.extend(toHaveNoViolations);

describe('RichText - Basic Rendering', () => {
  it('renders simple paragraph content', () => {
    render(<RichText html="<p>Hello World</p>" />);
    expect(screen.getByText('Hello World')).toBeInTheDocument();
  });

  it('renders nested formatting (bold, italic)', () => {
    render(
      <RichText html="<p>This is <strong>bold</strong> and <em>italic</em> text</p>" />
    );
    expect(screen.getByText(/bold/)).toBeInTheDocument();
    expect(screen.getByText(/italic/)).toBeInTheDocument();
  });

  it('renders heading elements (h1-h6)', () => {
    const { container } = render(
      <RichText html="<h1>Heading 1</h1><h2>Heading 2</h2><h3>Heading 3</h3>" />
    );
    expect(container.querySelector('h1')).toHaveTextContent('Heading 1');
    expect(container.querySelector('h2')).toHaveTextContent('Heading 2');
    expect(container.querySelector('h3')).toHaveTextContent('Heading 3');
  });

  it('renders unordered lists', () => {
    const { container } = render(
      <RichText html="<ul><li>Item 1</li><li>Item 2</li></ul>" />
    );
    const listItems = container.querySelectorAll('li');
    expect(listItems).toHaveLength(2);
    expect(listItems[0]).toHaveTextContent('Item 1');
    expect(listItems[1]).toHaveTextContent('Item 2');
  });

  it('renders ordered lists', () => {
    const { container } = render(
      <RichText html="<ol><li>First</li><li>Second</li></ol>" />
    );
    expect(container.querySelector('ol')).toBeInTheDocument();
    expect(container.querySelectorAll('li')).toHaveLength(2);
  });

  it('renders links with href', () => {
    const { container } = render(
      <RichText html='<p>Visit <a href="https://example.com">our site</a></p>' />
    );
    const link = container.querySelector('a');
    expect(link).toHaveAttribute('href', 'https://example.com');
    expect(link).toHaveTextContent('our site');
  });

  it('calls onLinkPress when link is clicked', () => {
    const onLinkPress = jest.fn();
    const { container } = render(
      <RichText
        html='<a href="https://example.com">Click me</a>'
        onLinkPress={onLinkPress}
      />
    );
    const link = container.querySelector('a');
    fireEvent.click(link!);
    // Browser normalizes URL with trailing slash
    expect(onLinkPress).toHaveBeenCalledWith('https://example.com/', 'link');
  });

  it('renders blockquotes', () => {
    const { container } = render(
      <RichText html="<blockquote>A quote</blockquote>" />
    );
    expect(container.querySelector('blockquote')).toHaveTextContent('A quote');
  });

  it('renders preformatted text', () => {
    const { container } = render(<RichText html="<pre>const x = 1;</pre>" />);
    expect(container.querySelector('pre')).toHaveTextContent('const x = 1;');
  });
});

describe('RichText - XSS Sanitization', () => {
  it('strips script tags', () => {
    const { container } = render(
      <RichText html='<p>Safe</p><script>alert("xss")</script>' />
    );
    expect(container.querySelector('script')).toBeNull();
    expect(screen.getByText('Safe')).toBeInTheDocument();
  });

  it('strips onclick attributes', () => {
    const { container } = render(
      <RichText html='<p onclick="alert(1)">Click</p>' />
    );
    const p = container.querySelector('p');
    expect(p).not.toHaveAttribute('onclick');
  });

  it('strips javascript: URLs', () => {
    const { container } = render(
      <RichText html='<p>Safe text <a href="javascript:alert(1)">Link</a></p>' />
    );
    // DOMPurify removes javascript: hrefs entirely
    const link = container.querySelector('a');
    // Link is either removed entirely, or has href stripped
    if (link) {
      const href = link.getAttribute('href');
      // href should be null/empty or not contain javascript:
      expect(href === null || !href.includes('javascript:')).toBe(true);
    }
    // The safe text should remain
    expect(container.textContent).toContain('Safe text');
  });

  it('strips img tags with onerror', () => {
    const { container } = render(
      <RichText html='<img src="x" onerror="alert(1)"/><p>Safe</p>' />
    );
    expect(container.querySelector('img')).toBeNull();
  });
});

describe('RichText - Accessibility', () => {
  it('preserves semantic HTML structure', async () => {
    const { container } = render(
      <RichText html="<h1>Title</h1><p>Paragraph with <a href='#'>link</a></p>" />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('maintains heading hierarchy', async () => {
    const { container } = render(
      <RichText html="<h1>Main</h1><h2>Section</h2><h3>Subsection</h3>" />
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});

describe('RichText - Truncation (numberOfLines)', () => {
  // Helper to access webkit style properties (jsdom uses camelCase)
  const getWebkitStyle = (
    el: HTMLElement,
    prop: 'WebkitLineClamp' | 'WebkitBoxOrient'
  ) => {
    return (el.style as unknown as Record<string, string>)[prop] || '';
  };

  it('applies single-line truncation styles when numberOfLines={1}', () => {
    const { container } = render(
      <RichText
        html="<p>This is a very long text that should be truncated to a single line with ellipsis.</p>"
        numberOfLines={1}
      />
    );
    const wrapper = container.firstChild as HTMLElement;
    // Wrapper has overflow:hidden, inner block elements get line-clamp styles
    expect(wrapper.style.overflow).toBe('hidden');

    // Check that inner p element has truncation styles injected via inline style attribute
    // (jsdom doesn't fully parse vendor-prefixed CSS in style objects)
    const paragraph = container.querySelector('p');
    expect(paragraph).not.toBeNull();
    const styleAttr = paragraph!.getAttribute('style') || '';
    expect(styleAttr).toContain('-webkit-line-clamp:1');
    expect(styleAttr).toContain('-webkit-box-orient:vertical');
    expect(styleAttr).toContain('display:-webkit-box');
  });

  it('applies multi-line truncation styles when numberOfLines={3}', () => {
    const { container } = render(
      <RichText
        html="<p>Line one.</p><p>Line two.</p><p>Line three.</p><p>Line four should be hidden.</p>"
        numberOfLines={3}
      />
    );
    const wrapper = container.firstChild as HTMLElement;
    // Wrapper has overflow:hidden, inner block elements get line-clamp styles
    expect(wrapper.style.overflow).toBe('hidden');

    // Check that inner p elements have truncation styles injected via inline style attribute
    const paragraphs = container.querySelectorAll('p');
    expect(paragraphs.length).toBeGreaterThan(0);
    const styleAttr = paragraphs[0].getAttribute('style') || '';
    expect(styleAttr).toContain('-webkit-line-clamp:3');
    expect(styleAttr).toContain('-webkit-box-orient:vertical');
    expect(styleAttr).toContain('display:-webkit-box');
  });

  it('does not apply truncation styles when numberOfLines is 0', () => {
    const { container } = render(
      <RichText html="<p>Short text that fits.</p>" numberOfLines={0} />
    );
    const wrapper = container.firstChild as HTMLElement;
    // Should not have line-clamp styles
    expect(wrapper.style.display).not.toBe('-webkit-box');
    expect(getWebkitStyle(wrapper, 'WebkitLineClamp')).toBe('');
  });

  it('does not apply truncation styles when numberOfLines is undefined', () => {
    const { container } = render(
      <RichText html="<p>Normal text without truncation.</p>" />
    );
    const wrapper = container.firstChild as HTMLElement;
    // Should not have line-clamp styles
    expect(wrapper.style.display).not.toBe('-webkit-box');
    expect(getWebkitStyle(wrapper, 'WebkitLineClamp')).toBe('');
  });

  it('treats negative numberOfLines as no limit', () => {
    const { container } = render(
      <RichText
        html="<p>Text with negative numberOfLines.</p>"
        numberOfLines={-1}
      />
    );
    const wrapper = container.firstChild as HTMLElement;
    // Should not have line-clamp styles
    expect(wrapper.style.display).not.toBe('-webkit-box');
    expect(getWebkitStyle(wrapper, 'WebkitLineClamp')).toBe('');
  });
});
