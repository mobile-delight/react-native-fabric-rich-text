import { render } from '@testing-library/react';
import RichText from '../../components/RichText.web';

describe('RichText.web', () => {
  it('should render simple HTML content', () => {
    const { container } = render(<RichText text="<p>Hello</p>" />);
    expect(container.innerHTML).toContain('Hello');
  });

  it('should return null for empty string', () => {
    const { container } = render(<RichText text="" />);
    expect(container.firstChild).toBeNull();
  });

  it('should return null for null text prop', () => {
    const { container } = render(<RichText text={null as unknown as string} />);
    expect(container.firstChild).toBeNull();
  });

  it('should return null for undefined text prop', () => {
    const { container } = render(
      <RichText text={undefined as unknown as string} />
    );
    expect(container.firstChild).toBeNull();
  });

  it('should return null for whitespace-only text', () => {
    const { container } = render(<RichText text="   " />);
    expect(container.firstChild).toBeNull();
  });

  describe('Semantic HTML Output', () => {
    it('should render <strong> tag as semantic strong element', () => {
      const { container } = render(
        <RichText text="<strong>Bold text</strong>" />
      );
      const strongElement = container.querySelector('strong');
      expect(strongElement).toBeTruthy();
      expect(strongElement?.textContent).toBe('Bold text');
    });

    it('should render <em> tag as semantic em element', () => {
      const { container } = render(<RichText text="<em>Italic text</em>" />);
      const emElement = container.querySelector('em');
      expect(emElement).toBeTruthy();
      expect(emElement?.textContent).toBe('Italic text');
    });

    it('should render <p> tag as semantic p element', () => {
      const { container } = render(<RichText text="<p>Paragraph text</p>" />);
      const pElement = container.querySelector('p');
      expect(pElement).toBeTruthy();
      expect(pElement?.textContent).toBe('Paragraph text');
    });

    it('should render <h1> tag as semantic h1 element', () => {
      const { container } = render(<RichText text="<h1>Heading text</h1>" />);
      const h1Element = container.querySelector('h1');
      expect(h1Element).toBeTruthy();
      expect(h1Element?.textContent).toBe('Heading text');
    });

    it('should preserve nested semantic structure', () => {
      const { container } = render(
        <RichText text="<p><strong>Bold in paragraph</strong></p>" />
      );
      const pElement = container.querySelector('p');
      const strongElement = pElement?.querySelector('strong');
      expect(pElement).toBeTruthy();
      expect(strongElement).toBeTruthy();
      expect(strongElement?.textContent).toBe('Bold in paragraph');
    });
  });

  describe('Style Prop Integration', () => {
    it('should apply fontSize style to root element', () => {
      const { container } = render(
        <RichText text="<p>Text</p>" style={{ fontSize: 16 }} />
      );
      const rootElement = container.firstChild as HTMLElement;
      expect(rootElement.style.fontSize).toBe('16px');
    });

    it('should apply color style to root element', () => {
      const { container } = render(
        <RichText text="<p>Text</p>" style={{ color: '#FF0000' }} />
      );
      const rootElement = container.firstChild as HTMLElement;
      expect(rootElement.style.color).toBe('rgb(255, 0, 0)');
    });

    it('should apply multiple styles to root element', () => {
      const { container } = render(
        <RichText
          text="<p>Text</p>"
          style={{ fontSize: 16, color: '#FF0000' }}
        />
      );
      const rootElement = container.firstChild as HTMLElement;
      expect(rootElement.style.fontSize).toBe('16px');
      expect(rootElement.style.color).toBe('rgb(255, 0, 0)');
    });

    it('should handle undefined style without crashing', () => {
      const { container } = render(<RichText text="<p>Text</p>" />);
      expect(container.firstChild).toBeTruthy();
    });
  });

  describe('className Prop Integration', () => {
    it('should apply className to root element', () => {
      const { container } = render(
        <RichText text="<p>Text</p>" className="text-blue-500" />
      );
      const rootElement = container.firstChild as HTMLElement;
      expect(rootElement.className).toBe('text-blue-500');
    });

    it('should apply both className and style props', () => {
      const { container } = render(
        <RichText
          text="<p>Text</p>"
          className="my-class"
          style={{ fontSize: 16 }}
        />
      );
      const rootElement = container.firstChild as HTMLElement;
      expect(rootElement.className).toBe('my-class');
      expect(rootElement.style.fontSize).toBe('16px');
    });

    it('should handle undefined className without crashing', () => {
      const { container } = render(<RichText text="<p>Text</p>" />);
      expect(container.firstChild).toBeTruthy();
    });
  });

  describe('testID Prop Integration', () => {
    it('should apply testID as data-testid attribute', () => {
      const { getByTestId } = render(
        <RichText text="<p>Text</p>" testID="my-component" />
      );
      const element = getByTestId('my-component');
      expect(element).toBeTruthy();
    });

    it('should handle undefined testID without adding attribute', () => {
      const { container } = render(<RichText text="<p>Text</p>" />);
      const rootElement = container.firstChild as HTMLElement;
      expect(rootElement.hasAttribute('data-testid')).toBe(false);
    });
  });

  describe('Edge Case Handling', () => {
    it('should render deeply nested tags without stack overflow', () => {
      const deeplyNestedMarkup =
        '<div><p><strong><em><span>Deeply nested text</span></em></strong></p></div>';
      const { container } = render(<RichText text={deeplyNestedMarkup} />);
      expect(container.textContent).toContain('Deeply nested text');
      // Verify the nesting depth
      const div = container.querySelector('div div');
      const p = div?.querySelector('p');
      const strong = p?.querySelector('strong');
      const em = strong?.querySelector('em');
      const span = em?.querySelector('span');
      expect(span?.textContent).toBe('Deeply nested text');
    });

    it('should render very long text without performance degradation', () => {
      const longContent = 'A'.repeat(10000);
      const longMarkup = `<p>${longContent}</p>`;
      const startTime = performance.now();
      const { container } = render(<RichText text={longMarkup} />);
      const endTime = performance.now();

      expect(container.textContent).toContain(longContent);
      expect(endTime - startTime).toBeLessThan(100);
    });

    it('should handle special characters correctly', () => {
      const { container } = render(<RichText text="<p>&amp; &lt; &gt;</p>" />);
      const pElement = container.querySelector('p');
      expect(pElement?.textContent).toBe('& < >');
    });
  });

  describe('XSS Protection', () => {
    it('should sanitize script tags', () => {
      const { container } = render(
        <RichText text="<script>alert('xss')</script><p>Safe</p>" />
      );
      expect(container.querySelector('script')).toBeNull();
      expect(container.textContent).toContain('Safe');
    });

    it('should sanitize event handler attributes', () => {
      const { container } = render(
        <RichText text='<p><img src=x onerror="alert(1)"></p>' />
      );
      const img = container.querySelector('img');
      expect(img).toBeNull();
    });

    it('should sanitize onclick attributes', () => {
      const { container } = render(
        <RichText text='<p onclick="alert(1)">Click me</p>' />
      );
      const p = container.querySelector('p');
      expect(p?.getAttribute('onclick')).toBeNull();
      expect(p?.textContent).toBe('Click me');
    });

    it('should sanitize javascript protocol in links', () => {
      const protocol = 'javascript';
      const maliciousMarkup = `<p><a href="${protocol}:alert(1)">Link</a></p>`;
      const { container } = render(<RichText text={maliciousMarkup} />);
      const link = container.querySelector('a');
      expect(link).toBeTruthy();
      expect(link?.getAttribute('href')).toBeNull();
      expect(link?.textContent).toBe('Link');
    });

    it('should allow safe links', () => {
      const { container } = render(
        <RichText text='<a href="https://example.com">Link</a>' />
      );
      const link = container.querySelector('a');
      expect(link?.getAttribute('href')).toBe('https://example.com');
    });

    it('should sanitize data attributes with event handlers', () => {
      const { container } = render(
        <RichText text='<p data-onclick="alert(1)">Text</p>' />
      );
      const p = container.querySelector('p');
      expect(p?.getAttribute('data-onclick')).toBeNull();
      expect(p?.textContent).toBe('Text');
    });

    it('should sanitize iframe tags', () => {
      const { container } = render(
        <RichText text='<iframe src="https://evil.com"></iframe><p>Safe</p>' />
      );
      expect(container.querySelector('iframe')).toBeNull();
      expect(container.textContent).toContain('Safe');
    });

    it('should sanitize object and embed tags', () => {
      const { container } = render(
        <RichText text='<object data="malicious.swf"></object><p>Safe</p>' />
      );
      expect(container.querySelector('object')).toBeNull();
      expect(container.textContent).toContain('Safe');
    });

    it('should sanitize style tags with malicious CSS', () => {
      const { container } = render(
        <RichText text="<style>body { display: none; }</style><p>Visible</p>" />
      );
      expect(container.querySelector('style')).toBeNull();
      expect(container.textContent).toContain('Visible');
    });

    it('should sanitize svg with script elements', () => {
      const { container } = render(
        <RichText text="<svg><script>alert(1)</script></svg><p>Safe</p>" />
      );
      expect(container.querySelector('svg')).toBeNull();
      expect(container.querySelector('script')).toBeNull();
      expect(container.textContent).toContain('Safe');
    });
  });
});
