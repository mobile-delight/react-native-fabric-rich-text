import { render, screen } from '@testing-library/react';
import HTMLText from 'react-native-fabric-html-text';

describe('HTMLText - className Styling', () => {
  it('applies className to the container element', () => {
    const { container } = render(
      <HTMLText html="<p>Styled text</p>" className="custom-class" />
    );
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('custom-class');
  });

  it('applies multiple className values', () => {
    const { container } = render(
      <HTMLText
        html="<p>Multi-class text</p>"
        className="class-one class-two class-three"
      />
    );
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('class-one');
    expect(wrapper).toHaveClass('class-two');
    expect(wrapper).toHaveClass('class-three');
  });

  it('applies Tailwind utility classes', () => {
    const { container } = render(
      <HTMLText
        html="<p>Tailwind styled</p>"
        className="text-blue-600 bg-gray-100 p-4 rounded-lg"
      />
    );
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('text-blue-600');
    expect(wrapper).toHaveClass('bg-gray-100');
    expect(wrapper).toHaveClass('p-4');
    expect(wrapper).toHaveClass('rounded-lg');
  });

  it('works without className (no class attribute)', () => {
    const { container } = render(<HTMLText html="<p>No class</p>" />);
    const wrapper = container.firstChild as HTMLElement;
    // Should not have a class attribute when className is not provided
    expect(wrapper.className).toBe('');
  });

  it('combines className with inline style prop', () => {
    const { container } = render(
      <HTMLText
        html="<p>Combined styling</p>"
        className="text-lg"
        style={{ color: 'red' }}
      />
    );
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('text-lg');
    expect(wrapper.style.color).toBe('red');
  });

  it('combines className with numberOfLines truncation', () => {
    const { container } = render(
      <HTMLText
        html="<p>Long text that will be truncated with styling applied.</p>"
        className="bg-amber-50 border-l-4"
        numberOfLines={2}
      />
    );
    const wrapper = container.firstChild as HTMLElement;
    // Check className is applied
    expect(wrapper).toHaveClass('bg-amber-50');
    expect(wrapper).toHaveClass('border-l-4');
    // Check truncation styles are also applied
    expect(wrapper.style.overflow).toBe('hidden');
    expect(wrapper.style.display).toBe('-webkit-box');
  });

  it('applies testID as data-testid attribute', () => {
    render(<HTMLText html="<p>Test ID text</p>" testID="my-html-text" />);
    expect(screen.getByTestId('my-html-text')).toBeInTheDocument();
  });

  it('combines className and testID', () => {
    const { container } = render(
      <HTMLText
        html="<p>All props</p>"
        className="custom-style"
        testID="test-element"
      />
    );
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('custom-style');
    expect(wrapper).toHaveAttribute('data-testid', 'test-element');
  });
});

describe('HTMLText - Responsive Classes', () => {
  it('applies responsive breakpoint classes', () => {
    const { container } = render(
      <HTMLText
        html="<p>Responsive text</p>"
        className="text-sm md:text-base lg:text-xl"
      />
    );
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('text-sm');
    expect(wrapper).toHaveClass('md:text-base');
    expect(wrapper).toHaveClass('lg:text-xl');
  });

  it('applies hover and focus state classes', () => {
    const { container } = render(
      <HTMLText
        html="<p>Interactive text</p>"
        className="hover:bg-blue-100 focus:ring-2"
      />
    );
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('hover:bg-blue-100');
    expect(wrapper).toHaveClass('focus:ring-2');
  });

  it('applies dark mode classes', () => {
    const { container } = render(
      <HTMLText
        html="<p>Dark mode text</p>"
        className="text-gray-900 dark:text-gray-100 bg-white dark:bg-gray-800"
      />
    );
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper).toHaveClass('text-gray-900');
    expect(wrapper).toHaveClass('dark:text-gray-100');
    expect(wrapper).toHaveClass('bg-white');
    expect(wrapper).toHaveClass('dark:bg-gray-800');
  });
});
