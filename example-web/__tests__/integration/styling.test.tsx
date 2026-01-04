import { render, screen } from '@testing-library/react';
import StylingPage from '@/app/styling/page';

// Mock HTMLText component to test page structure
jest.mock('react-native-fabric-html-text', () => {
  return function MockHTMLText({
    html,
    className,
    numberOfLines,
  }: {
    html: string;
    className?: string;
    numberOfLines?: number;
  }) {
    return (
      <div
        data-testid="html-text"
        className={className}
        data-numberoflines={numberOfLines}
        dangerouslySetInnerHTML={{ __html: html }}
      />
    );
  };
});

describe('Styling Page - Integration', () => {
  it('renders the page title', () => {
    render(<StylingPage />);
    expect(
      screen.getByText('Styling with className & Tailwind')
    ).toBeInTheDocument();
    expect(
      screen.getByText('Styling with className & Tailwind').tagName
    ).toBe('H1');
  });

  it('renders page description about className prop', () => {
    render(<StylingPage />);
    expect(
      screen.getByText(/className prop allows seamless integration/)
    ).toBeInTheDocument();
  });

  it('renders all demo sections', () => {
    render(<StylingPage />);

    expect(screen.getByText('Basic className')).toBeInTheDocument();
    expect(screen.getByText('Multiple Tailwind Classes')).toBeInTheDocument();
    expect(screen.getByText('Border and Shadow')).toBeInTheDocument();
    expect(screen.getByText('Gradient Background')).toBeInTheDocument();
    expect(screen.getByText('Responsive Typography')).toBeInTheDocument();
    expect(screen.getByText('Hover Effects')).toBeInTheDocument();
    expect(screen.getByText('Combining with numberOfLines')).toBeInTheDocument();
    expect(screen.getByText('Complex HTML with Styling')).toBeInTheDocument();
  });

  it('renders HTMLText components for each demo', () => {
    render(<StylingPage />);

    const htmlTextComponents = screen.getAllByTestId('html-text');
    // 8 styling demos + 7 container query HTMLText instances:
    // full width (1), half width (1), side-by-side (2), named (1), nested (2)
    expect(htmlTextComponents.length).toBe(15);
  });

  it('basic className demo has text-blue-600 class', () => {
    render(<StylingPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[0]).toHaveClass('text-blue-600');
  });

  it('multiple classes demo has all Tailwind classes', () => {
    render(<StylingPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[1]).toHaveClass('text-lg');
    expect(htmlTexts[1]).toHaveClass('font-semibold');
    expect(htmlTexts[1]).toHaveClass('text-purple-700');
    expect(htmlTexts[1]).toHaveClass('bg-purple-50');
    expect(htmlTexts[1]).toHaveClass('p-4');
    expect(htmlTexts[1]).toHaveClass('rounded-lg');
  });

  it('border and shadow demo has border and shadow classes', () => {
    render(<StylingPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[2]).toHaveClass('border');
    expect(htmlTexts[2]).toHaveClass('shadow-md');
    expect(htmlTexts[2]).toHaveClass('rounded-xl');
  });

  it('gradient demo has gradient classes', () => {
    render(<StylingPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[3]).toHaveClass('bg-gradient-to-r');
    expect(htmlTexts[3]).toHaveClass('from-cyan-500');
    expect(htmlTexts[3]).toHaveClass('to-blue-500');
  });

  it('responsive typography demo has responsive classes', () => {
    render(<StylingPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[4]).toHaveClass('text-sm');
    expect(htmlTexts[4]).toHaveClass('md:text-base');
    expect(htmlTexts[4]).toHaveClass('lg:text-xl');
  });

  it('hover effects demo has hover class', () => {
    render(<StylingPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[5]).toHaveClass('hover:bg-blue-100');
    expect(htmlTexts[5]).toHaveClass('transition-colors');
  });

  it('combining with numberOfLines demo has both className and numberOfLines', () => {
    render(<StylingPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[6]).toHaveClass('bg-amber-50');
    expect(htmlTexts[6]).toHaveClass('border-l-4');
    expect(htmlTexts[6]).toHaveAttribute('data-numberoflines', '2');
  });

  it('complex HTML demo has prose classes', () => {
    render(<StylingPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    expect(htmlTexts[7]).toHaveClass('prose');
    expect(htmlTexts[7]).toHaveClass('prose-blue');
  });

  it('renders container queries section heading', () => {
    render(<StylingPage />);
    expect(screen.getByText('Container Queries')).toBeInTheDocument();
  });

  it('renders all container query demos', () => {
    render(<StylingPage />);

    expect(
      screen.getByText('Container Query - Full Width')
    ).toBeInTheDocument();
    expect(
      screen.getByText('Container Query - Half Width')
    ).toBeInTheDocument();
    expect(
      screen.getByText('Container Query - Side by Side')
    ).toBeInTheDocument();
    expect(screen.getByText('Container Query - Named')).toBeInTheDocument();
    expect(screen.getByText('Container Query - Nested')).toBeInTheDocument();
  });

  it('full width container query demo has container classes', () => {
    render(<StylingPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Index 8 is the full width container query demo
    expect(htmlTexts[8]).toHaveClass('text-sm');
    expect(htmlTexts[8]).toHaveClass('text-slate-700');
  });

  it('side by side container query demo renders two HTMLText components', () => {
    render(<StylingPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Index 10 and 11 are the side-by-side containers
    expect(htmlTexts[10]).toHaveClass('text-emerald-800');
    expect(htmlTexts[11]).toHaveClass('text-violet-800');
  });

  it('nested container query demo renders outer and inner text', () => {
    render(<StylingPage />);

    const htmlTexts = screen.getAllByTestId('html-text');
    // Index 13 and 14 are the nested container texts (outer, inner)
    expect(htmlTexts[13]).toHaveClass('text-sky-800');
    expect(htmlTexts[14]).toHaveClass('text-sky-900');
  });
});
