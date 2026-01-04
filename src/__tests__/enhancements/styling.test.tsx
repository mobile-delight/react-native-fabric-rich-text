import 'react';
import { render } from '@testing-library/react-native';
import HTMLText from '../../components/HTMLText';

describe('tagStyles', () => {
  describe('Style Application', () => {
    it('applies tagStyles to matching HTML elements', () => {
      const tagStyles = { strong: { color: 'red' } };
      const { getByTestId } = render(
        <HTMLText
          html="<p>Normal <strong>Bold</strong></p>"
          tagStyles={tagStyles}
          testID="styled-text"
        />
      );

      expect(getByTestId('styled-text')).toBeTruthy();
    });

    it('passes tagStyles to native component', () => {
      const tagStyles = { p: { fontSize: 18 } };
      const { getByTestId } = render(
        <HTMLText
          html="<p>Paragraph</p>"
          tagStyles={tagStyles}
          testID="styled-text"
        />
      );

      expect(getByTestId('styled-text')).toBeTruthy();
    });

    it('handles empty tagStyles object', () => {
      const { getByTestId } = render(
        <HTMLText html="<p>Text</p>" tagStyles={{}} testID="styled-text" />
      );

      expect(getByTestId('styled-text')).toBeTruthy();
    });

    it('handles undefined tagStyles gracefully', () => {
      const { getByTestId } = render(
        <HTMLText
          html="<p>Text</p>"
          tagStyles={undefined}
          testID="styled-text"
        />
      );

      expect(getByTestId('styled-text')).toBeTruthy();
    });
  });

  describe('Style Merging', () => {
    it('allows multiple tag styles in same object', () => {
      const tagStyles = {
        strong: { color: 'red' },
        em: { color: 'blue' },
        p: { marginBottom: 10 },
      };
      const { getByTestId } = render(
        <HTMLText
          html="<p><strong>Bold</strong> and <em>italic</em></p>"
          tagStyles={tagStyles}
          testID="multi-styled"
        />
      );

      expect(getByTestId('multi-styled')).toBeTruthy();
    });
  });

  describe('Invalid Styles', () => {
    it('renders without crashing when tagStyles contains invalid style keys', () => {
      const tagStyles = {
        p: {
          color: 'red',
          invalidStyle: 'value', // Invalid style property
        } as Record<string, unknown>,
      };
      const { getByTestId } = render(
        <HTMLText
          html="<p>Text</p>"
          tagStyles={tagStyles as never}
          testID="invalid-styles"
        />
      );

      expect(getByTestId('invalid-styles')).toBeTruthy();
    });

    it('handles tagStyles for non-existent HTML tags', () => {
      const tagStyles = { customtag: { color: 'red' } };
      const { getByTestId } = render(
        <HTMLText
          html="<p>No custom tag here</p>"
          tagStyles={tagStyles}
          testID="no-match"
        />
      );

      expect(getByTestId('no-match')).toBeTruthy();
    });
  });
});

describe('className', () => {
  describe('Basic Usage', () => {
    it('accepts className prop', () => {
      const { getByTestId } = render(
        <HTMLText
          html="<p>Text</p>"
          className="custom-class"
          testID="classed-text"
        />
      );

      expect(getByTestId('classed-text')).toBeTruthy();
    });

    it('accepts multiple space-separated classes', () => {
      const { getByTestId } = render(
        <HTMLText
          html="<p>Text</p>"
          className="class-one class-two"
          testID="multi-class"
        />
      );

      expect(getByTestId('multi-class')).toBeTruthy();
    });

    it('handles empty className string', () => {
      const { getByTestId } = render(
        <HTMLText html="<p>Text</p>" className="" testID="empty-class" />
      );

      expect(getByTestId('empty-class')).toBeTruthy();
    });

    it('handles undefined className gracefully', () => {
      const { getByTestId } = render(
        <HTMLText
          html="<p>Text</p>"
          className={undefined}
          testID="undefined-class"
        />
      );

      expect(getByTestId('undefined-class')).toBeTruthy();
    });
  });

  describe('NativeWind Compatibility', () => {
    it('renders with NativeWind-style class names without errors', () => {
      // NativeWind classes like text-lg, text-blue-500, etc.
      const { getByTestId } = render(
        <HTMLText
          html="<p>Styled text</p>"
          className="text-lg text-blue-500 font-bold"
          testID="nativewind-classes"
        />
      );

      expect(getByTestId('nativewind-classes')).toBeTruthy();
    });
  });
});

describe('Combined Props', () => {
  it('accepts both tagStyles and className together', () => {
    const tagStyles = { strong: { color: 'red' } };
    const { getByTestId } = render(
      <HTMLText
        html="<p><strong>Bold</strong></p>"
        tagStyles={tagStyles}
        className="custom-class"
        testID="combined"
      />
    );

    expect(getByTestId('combined')).toBeTruthy();
  });

  it('accepts all props together: style, tagStyles, className', () => {
    const style = { fontSize: 16 };
    const tagStyles = { p: { color: 'green' } };
    const { getByTestId } = render(
      <HTMLText
        html="<p>Full featured</p>"
        style={style}
        tagStyles={tagStyles}
        className="extra-class"
        testID="all-props"
      />
    );

    expect(getByTestId('all-props')).toBeTruthy();
  });
});
