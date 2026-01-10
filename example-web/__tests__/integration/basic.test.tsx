import { render, screen, within } from '@testing-library/react';
import BasicPage from '@/app/basic/page';

// Mock RichText component since we're testing page structure, not component internals
jest.mock('react-native-fabric-rich-text', () => {
  // Import DOMPurify inside the mock factory for Jest module isolation
  const DOMPurify = jest.requireActual('dompurify');
  return function MockRichText({
    text,
    onLinkPress,
  }: {
    text: string;
    onLinkPress?: (url: string, type: string) => void;
  }) {
    return (
      <div
        data-testid="html-text"
        // nosemgrep: no-dangerous-innerhtml-without-sanitization
        dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(text) }}
        onClick={(e) => {
          if (onLinkPress) {
            const target = e.target as HTMLElement;
            const anchor = target.closest('a');
            if (anchor && anchor.href) {
              e.preventDefault();
              onLinkPress(anchor.href, 'link');
            }
          }
        }}
      />
    );
  };
});

describe('Basic Page - Integration', () => {
  it('renders the page title', () => {
    render(<BasicPage />);
    // Use getByText since demos also contain h1 elements
    expect(screen.getByText('Basic HTML Rendering')).toBeInTheDocument();
    expect(screen.getByText('Basic HTML Rendering').tagName).toBe('H1');
  });

  it('renders page description', () => {
    render(<BasicPage />);
    expect(
      screen.getByText(/Demonstrations of basic HTML rendering/)
    ).toBeInTheDocument();
  });

  it('renders all demo sections', () => {
    render(<BasicPage />);

    // Check for all section titles
    expect(screen.getByText('Simple Paragraph')).toBeInTheDocument();
    expect(screen.getByText('Nested Formatting')).toBeInTheDocument();
    expect(screen.getByText('Heading Levels')).toBeInTheDocument();
    expect(screen.getByText('Unordered List')).toBeInTheDocument();
    expect(screen.getByText('Ordered List')).toBeInTheDocument();
    expect(screen.getByText('Links (Default Behavior)')).toBeInTheDocument();
    expect(screen.getByText('Links (With onLinkPress)')).toBeInTheDocument();
    expect(screen.getByText('Blockquote')).toBeInTheDocument();
    expect(screen.getByText('Preformatted Text')).toBeInTheDocument();
  });

  it('renders RichText components for each demo', () => {
    render(<BasicPage />);

    // Should have 9 RichText instances (one per demo section)
    const htmlTextComponents = screen.getAllByTestId('html-text');
    expect(htmlTextComponents.length).toBe(9);
  });

  it('simple paragraph demo contains correct content', () => {
    render(<BasicPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // First demo is simple paragraph
    expect(htmlTexts[0]).toHaveTextContent('Hello World');
  });

  it('nested formatting demo contains formatting elements', () => {
    render(<BasicPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Second demo is nested formatting
    const formattingDemo = htmlTexts[1];
    expect(within(formattingDemo).getByText('bold')).toBeInTheDocument();
    expect(within(formattingDemo).getByText('italic')).toBeInTheDocument();
  });

  it('heading demo renders h1-h6 elements', () => {
    render(<BasicPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Third demo is headings
    const headingsDemo = htmlTexts[2];
    expect(headingsDemo.querySelector('h1')).toHaveTextContent('Heading 1');
    expect(headingsDemo.querySelector('h2')).toHaveTextContent('Heading 2');
    expect(headingsDemo.querySelector('h6')).toHaveTextContent('Heading 6');
  });

  it('unordered list demo renders ul with li elements', () => {
    render(<BasicPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Fourth demo is unordered list
    const ulDemo = htmlTexts[3];
    expect(ulDemo.querySelector('ul')).toBeInTheDocument();
    expect(ulDemo.querySelectorAll('li')).toHaveLength(3);
  });

  it('ordered list demo renders ol with li elements', () => {
    render(<BasicPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Fifth demo is ordered list
    const olDemo = htmlTexts[4];
    expect(olDemo.querySelector('ol')).toBeInTheDocument();
    expect(olDemo.querySelectorAll('li')).toHaveLength(3);
  });

  it('link demos contain anchor elements', () => {
    render(<BasicPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Sixth demo is links (default)
    const linkDemo = htmlTexts[5];
    expect(linkDemo.querySelector('a')).toHaveAttribute(
      'href',
      'https://github.com'
    );

    // Seventh demo is links (with onLinkPress)
    const linkPressDemo = htmlTexts[6];
    expect(linkPressDemo.querySelector('a')).toHaveAttribute(
      'href',
      'https://example.com'
    );
  });

  it('blockquote demo renders blockquote element', () => {
    render(<BasicPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Eighth demo is blockquote
    const blockquoteDemo = htmlTexts[7];
    expect(blockquoteDemo.querySelector('blockquote')).toBeInTheDocument();
  });

  it('preformatted demo renders pre element', () => {
    render(<BasicPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Ninth demo is preformatted text
    const preDemo = htmlTexts[8];
    expect(preDemo.querySelector('pre')).toBeInTheDocument();
  });
});
