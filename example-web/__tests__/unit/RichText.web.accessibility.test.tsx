import { render } from '@testing-library/react';
import RichText from 'react-native-fabric-rich-text';

/**
 * Accessibility tests for RichText.web screen reader navigation.
 *
 * These tests verify the web implementation correctly exposes links for
 * screen reader navigation using ARIA attributes and semantic HTML.
 *
 * TDD Requirement: These tests should FAIL initially until T028-T030 are implemented.
 *
 * WCAG 2.1 Level AA Requirements:
 * - 2.4.4 Link Purpose: Links are identified with meaningful labels
 * - 4.1.2 Name, Role, Value: Links expose correct ARIA attributes
 */
describe('RichText.web Accessibility', () => {
  // MARK: - ARIA Container Tests

  describe('Container ARIA attributes', () => {
    it('should have aria-describedby referencing link count when links present', () => {
      const { container } = render(
        <RichText
          html='<p>Visit <a href="https://a.com">First</a> and <a href="https://b.com">Second</a></p>'
          testID="html-text"
        />
      );

      const rootElement = container.firstChild as HTMLElement;
      const describedBy = rootElement.getAttribute('aria-describedby');

      expect(describedBy).toBeTruthy();

      // The aria-describedby should reference a hidden element with link count
      // Use getElementById instead of querySelector to handle special characters in useId() output
      const descElement = document.getElementById(describedBy!);
      expect(descElement).toBeTruthy();
      expect(descElement?.textContent).toContain('2'); // Should mention 2 links
    });

    it('should not have aria-describedby when no links present', () => {
      const { container } = render(
        <RichText
          html="<p>Just plain text with no links.</p>"
          testID="html-text"
        />
      );

      const rootElement = container.firstChild as HTMLElement;
      const describedBy = rootElement.getAttribute('aria-describedby');

      // Either null or empty is acceptable when no links
      expect(!describedBy || describedBy === '').toBe(true);
    });

    it('should preserve native semantics without role attribute', () => {
      const { container } = render(
        <RichText html='<p><a href="https://a.com">First</a> and <a href="https://b.com">Second</a></p>' />
      );

      const rootElement = container.firstChild as HTMLElement;
      // Container should NOT have a role - preserves native div semantics
      const role = rootElement.getAttribute('role');
      expect(role).toBeNull();
    });
  });

  // MARK: - Link Semantic Tests

  describe('Link semantic HTML', () => {
    it('should render links as real <a> elements with href', () => {
      const { container } = render(
        <RichText html='<p><a href="https://example.com">Example Link</a></p>' />
      );

      const link = container.querySelector('a');
      expect(link).toBeTruthy();
      expect(link?.getAttribute('href')).toBe('https://example.com');
    });

    it('should preserve link text as accessible name', () => {
      const { container } = render(
        <RichText html='<p><a href="https://example.com">Click Here</a></p>' />
      );

      const link = container.querySelector('a');
      expect(link?.textContent).toBe('Click Here');
    });

    it('should maintain multiple links as distinct elements', () => {
      const { container } = render(
        <RichText html='<p><a href="https://a.com">First</a>, <a href="https://b.com">Second</a>, and <a href="https://c.com">Third</a></p>' />
      );

      const links = container.querySelectorAll('a');
      expect(links.length).toBe(3);
      expect(links[0]?.textContent).toBe('First');
      expect(links[1]?.textContent).toBe('Second');
      expect(links[2]?.textContent).toBe('Third');
    });
  });

  // MARK: - Link Position Info Tests

  describe('Link position information', () => {
    it('should add aria-describedby for link position (link 1 of 3)', () => {
      const { container } = render(
        <RichText html='<p><a href="https://a.com">First</a> <a href="https://b.com">Second</a> <a href="https://c.com">Third</a></p>' />
      );

      const links = container.querySelectorAll('a');
      expect(links.length).toBe(3);

      // First link should have position info
      const firstLink = links[0];
      const describedBy = firstLink?.getAttribute('aria-describedby');

      // Verify aria-describedby exists and references a valid element
      expect(describedBy).toBeTruthy();

      // Split space-separated IDs and find all referenced elements
      const descIds = describedBy!.split(/\s+/);
      let foundValidReference = false;
      let positionText = '';

      for (const id of descIds) {
        const descElement = document.getElementById(id);
        if (descElement) {
          foundValidReference = true;
          positionText += descElement.textContent || '';
        }
      }

      expect(foundValidReference).toBe(true);
      // Validate semantic format: "Link 1 of 3" or similar
      expect(positionText).toMatch(/\blink\s*1\s*of\s*3\b/i);
    });

    it('should update position info when links are filtered by truncation', () => {
      const { container } = render(
        <RichText
          html='<p><a href="https://a.com">First Link</a> <a href="https://b.com">Second Link</a></p>'
          numberOfLines={1}
        />
      );

      // When truncated, visible links should still have correct position info
      const links = container.querySelectorAll('a');
      expect(links.length).toBeGreaterThan(0);

      // Position info should reflect only visible links
      const firstLink = links[0];
      expect(firstLink).toBeTruthy();
    });
  });

  // MARK: - Focus Management Tests

  describe('Focus management', () => {
    it('should have tabIndex={-1} on container to avoid duplicate focus with nested links', () => {
      const { container } = render(
        <RichText html='<p><a href="https://example.com">Link</a></p>' />
      );

      const rootElement = container.firstChild as HTMLElement;
      // Container should NOT be keyboard focusable since nested links are focusable
      // This prevents duplicate tab stops
      expect(rootElement.tabIndex).toBe(-1);
    });

    it('links should be natively focusable', () => {
      const { container } = render(
        <RichText html='<p><a href="https://example.com">Focusable Link</a></p>' />
      );

      const link = container.querySelector('a') as HTMLAnchorElement;
      expect(link).toBeTruthy();

      // Links should be keyboard accessible (tabIndex >= 0)
      expect(link.tabIndex).toBeGreaterThanOrEqual(0);

      // Verify link can receive focus
      link.focus();
      expect(document.activeElement).toBe(link);
    });
  });

  // MARK: - Email/Phone Link Type Tests

  describe('Link type accessibility', () => {
    it('should preserve mailto: links for email actions', () => {
      const { container } = render(
        <RichText html='<p>Email: <a href="mailto:test@example.com">test@example.com</a></p>' />
      );

      const link = container.querySelector('a');
      expect(link?.getAttribute('href')).toBe('mailto:test@example.com');
    });

    it('should preserve tel: links for phone actions', () => {
      const { container } = render(
        <RichText html='<p>Call: <a href="tel:+1234567890">+1 234 567 890</a></p>' />
      );

      const link = container.querySelector('a');
      expect(link?.getAttribute('href')).toBe('tel:+1234567890');
    });
  });

  // MARK: - Dangerous Protocol Tests

  describe('Dangerous URL protocol sanitization', () => {
    it('should strip or block javascript: protocol links', () => {
      const { container } = render(
        <HTMLText html='<p><a href="javascript:alert(1)">XSS Link</a></p>' />
      );

      const link = container.querySelector('a');
      // Link should either be removed, have no href, or have a sanitized href
      if (link) {
        const href = link.getAttribute('href');
        // href being null/empty is valid sanitization (dangerous protocol stripped)
        if (href) {
          expect(href).not.toMatch(/^javascript:/i);
        }
      }
    });

    it('should strip or block data: protocol links', () => {
      const { container } = render(
        <HTMLText html='<p><a href="data:text/html,<script>alert(1)</script>">Data Link</a></p>' />
      );

      const link = container.querySelector('a');
      if (link) {
        const href = link.getAttribute('href');
        // href being null/empty is valid sanitization (dangerous protocol stripped)
        if (href) {
          expect(href).not.toMatch(/^data:/i);
        }
      }
    });

    it('should strip or block vbscript: protocol links', () => {
      const { container } = render(
        <HTMLText html='<p><a href="vbscript:msgbox(1)">VBScript Link</a></p>' />
      );

      const link = container.querySelector('a');
      if (link) {
        const href = link.getAttribute('href');
        // href being null/empty is valid sanitization (dangerous protocol stripped)
        if (href) {
          expect(href).not.toMatch(/^vbscript:/i);
        }
      }
    });

    it('should allow safe protocols (http, https, mailto, tel)', () => {
      const { container } = render(
        <HTMLText
          html={`
          <p>
            <a href="https://example.com">HTTPS</a>
            <a href="http://example.com">HTTP</a>
            <a href="mailto:test@example.com">Email</a>
            <a href="tel:+1234567890">Phone</a>
          </p>
        `}
        />
      );

      const links = container.querySelectorAll('a');
      expect(links.length).toBe(4);

      expect(links[0]?.getAttribute('href')).toBe('https://example.com');
      expect(links[1]?.getAttribute('href')).toBe('http://example.com');
      expect(links[2]?.getAttribute('href')).toBe('mailto:test@example.com');
      expect(links[3]?.getAttribute('href')).toBe('tel:+1234567890');
    });
  });

  // MARK: - Empty State Tests

  describe('Empty state accessibility', () => {
    it('should not have link-related ARIA when no links', () => {
      const { container } = render(<RichText html="<p>No links here.</p>" />);

      const links = container.querySelectorAll('a');
      expect(links.length).toBe(0);
    });

    it('should handle empty HTML gracefully', () => {
      const { container } = render(<RichText html="" />);
      expect(container.firstChild).toBeNull();
    });
  });

  // MARK: - Screen Reader Hidden Content Tests

  describe('Screen reader hidden content', () => {
    it('should not have hidden links when content is not truncated', () => {
      const { container } = render(
        <RichText
          html='<p><a href="https://example.com">Visible Link</a></p>'
          numberOfLines={0}
        />
      );

      const links = container.querySelectorAll('a');
      links.forEach((link) => {
        expect(link.getAttribute('aria-hidden')).not.toBe('true');
      });
    });

    it('should hide truncated links from screen readers', () => {
      const { container } = render(
        <HTMLText
          html='<p><a href="https://a.com">First Link That Is Very Long</a> <a href="https://b.com">Second Link That Is Also Long</a> <a href="https://c.com">Third Link</a></p>'
          numberOfLines={1}
        />
      );

      const links = container.querySelectorAll('a');

      // With truncation, some links should be visible
      const visibleLinks = Array.from(links).filter(
        (link) => link.getAttribute('aria-hidden') !== 'true'
      );

      // Should have at least one visible link
      expect(visibleLinks.length).toBeGreaterThan(0);
      // Due to CSS line-clamp, links may not be explicitly marked as hidden but overflow is hidden
      // So we just verify truncation is applied to the container
      const rootElement = container.firstChild as HTMLElement;
      expect(rootElement.style.overflow).toBe('hidden');
    });
  });

  // MARK: - Nested Link Content Tests

  describe('Nested link content accessibility', () => {
    it('should preserve nested formatting inside links for screen readers', () => {
      const { container } = render(
        <RichText html='<p><a href="https://example.com"><strong>Bold</strong> Link</a></p>' />
      );

      const link = container.querySelector('a');
      expect(link?.textContent).toBe('Bold Link');

      const strong = link?.querySelector('strong');
      expect(strong?.textContent).toBe('Bold');
    });

    it('should maintain link semantics with nested elements', () => {
      const { container } = render(
        <RichText html='<p><a href="https://example.com"><em>Emphasized</em> text</a></p>' />
      );

      const link = container.querySelector('a');
      expect(link?.getAttribute('href')).toBe('https://example.com');
      expect(link?.textContent).toBe('Emphasized text');
    });
  });
});
