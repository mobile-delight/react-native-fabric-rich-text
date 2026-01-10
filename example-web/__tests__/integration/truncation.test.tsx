import { render, screen } from '@testing-library/react';
import TruncationPage from '@/app/truncation/page';

// Mock RichText component to test page structure
jest.mock('react-native-fabric-rich-text', () => {
  // Import DOMPurify inside the mock factory for Jest module isolation
  const DOMPurify = jest.requireActual('dompurify');
  return function MockRichText({
    text,
    numberOfLines,
  }: {
    text: string;
    numberOfLines?: number;
  }) {
    return (
      <div
        data-testid="html-text"
        data-numberoflines={numberOfLines}
        // nosemgrep: no-dangerous-innerhtml-without-sanitization
        dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(text) }}
      />
    );
  };
});

describe('Truncation Page - Integration', () => {
  it('renders the page title', () => {
    render(<TruncationPage />);
    expect(screen.getByText('Text Truncation')).toBeInTheDocument();
    expect(screen.getByText('Text Truncation').tagName).toBe('H1');
  });

  it('renders page description mentioning CSS line-clamp', () => {
    render(<TruncationPage />);
    expect(
      screen.getByText(/numberOfLines prop for truncating text/)
    ).toBeInTheDocument();
    expect(screen.getByText(/-webkit-line-clamp/)).toBeInTheDocument();
  });

  it('renders all demo sections', () => {
    render(<TruncationPage />);

    expect(screen.getByText('Single Line Truncation')).toBeInTheDocument();
    expect(screen.getByText('Two Line Truncation')).toBeInTheDocument();
    expect(screen.getByText('Three Line Truncation')).toBeInTheDocument();
    expect(screen.getByText('No Truncation (Full Text)')).toBeInTheDocument();
    expect(
      screen.getByText('Truncation with Formatted Text')
    ).toBeInTheDocument();
    expect(
      screen.getByText('Truncation with Multiple Paragraphs')
    ).toBeInTheDocument();
    expect(
      screen.getByText('numberOfLines={0} (No Truncation)')
    ).toBeInTheDocument();
  });

  it('renders RichText components for each demo', () => {
    render(<TruncationPage />);

    const htmlTextComponents = screen.getAllByTestId('html-text');
    expect(htmlTextComponents.length).toBe(7);
  });

  it('single line truncation has numberOfLines={1}', () => {
    render(<TruncationPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[0]).toHaveAttribute('data-numberoflines', '1');
  });

  it('two line truncation has numberOfLines={2}', () => {
    render(<TruncationPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[1]).toHaveAttribute('data-numberoflines', '2');
  });

  it('three line truncation has numberOfLines={3}', () => {
    render(<TruncationPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[2]).toHaveAttribute('data-numberoflines', '3');
  });

  it('full text demo has no numberOfLines', () => {
    render(<TruncationPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Fourth demo (index 3) should not have numberOfLines
    expect(htmlTexts[3]).not.toHaveAttribute('data-numberoflines');
  });

  it('formatted text demo has numberOfLines={2}', () => {
    render(<TruncationPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[4]).toHaveAttribute('data-numberoflines', '2');
  });

  it('numberOfLines=0 demo disables truncation', () => {
    render(<TruncationPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Last demo (index 6) should have numberOfLines={0}
    expect(htmlTexts[6]).toHaveAttribute('data-numberoflines', '0');
  });
});
