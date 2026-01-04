import { render, screen } from '@testing-library/react-native';

// Mock the HTMLTextNative component - use require inside factory to access Text
jest.mock('../adapters/native', () => {
  const mockReact = require('react');
  const { Text } = require('react-native');
  return {
    HTMLTextNative: jest.fn(
      ({
        html,
        style,
        testID,
      }: {
        html: string;
        style?: object;
        testID?: string;
      }) => {
        return mockReact.createElement(Text, { style, testID }, html);
      }
    ),
  };
});

import { HTMLTextNative } from '../adapters/native';

import HTMLText from '../components/HTMLText';

describe('HTMLText', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Edge Case Handling', () => {
    it('returns null for empty string html', () => {
      const { toJSON } = render(<HTMLText html="" />);
      expect(toJSON()).toBeNull();
    });

    it('returns null for undefined html', () => {
      const { toJSON } = render(
        <HTMLText html={undefined as unknown as string} />
      );
      expect(toJSON()).toBeNull();
    });

    it('returns null for null html', () => {
      const { toJSON } = render(<HTMLText html={null as unknown as string} />);
      expect(toJSON()).toBeNull();
    });

    it('returns null for whitespace-only html', () => {
      const { toJSON } = render(<HTMLText html={'   \n\t   '} />);
      expect(toJSON()).toBeNull();
    });

    it('renders nothing for empty input', () => {
      render(<HTMLText html="" />);
      expect(HTMLTextNative).not.toHaveBeenCalled();
    });

    it('renders nothing for whitespace-only input', () => {
      render(<HTMLText html={'   \n\t   '} />);
      expect(HTMLTextNative).not.toHaveBeenCalled();
    });
  });

  describe('Native Adapter Integration', () => {
    it('passes html prop to HTMLTextNative', () => {
      render(<HTMLText html="<p>Hello</p>" />);
      expect(HTMLTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ html: '<p>Hello</p>' }),
        undefined
      );
    });

    it('passes exact html value to HTMLTextNative', () => {
      const testHtml = '<strong>Bold text</strong>';
      render(<HTMLText html={testHtml} />);
      expect(HTMLTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ html: testHtml }),
        undefined
      );
    });
  });

  describe('Style Prop Pass-Through', () => {
    it('passes style prop to HTMLTextNative', () => {
      const testStyle = { color: 'red', fontSize: 16 };
      render(<HTMLText html="<p>Hello</p>" style={testStyle} />);
      expect(HTMLTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ style: testStyle }),
        undefined
      );
    });

    it('preserves style prop value exactly', () => {
      const complexStyle = { fontWeight: 'bold' as const, marginTop: 10 };
      render(<HTMLText html="<p>Hello</p>" style={complexStyle} />);
      expect(HTMLTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ style: complexStyle }),
        undefined
      );
    });

    it('works when style is undefined', () => {
      render(<HTMLText html="<p>Hello</p>" />);
      expect(HTMLTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ style: undefined }),
        undefined
      );
    });
  });

  describe('TestID Prop Pass-Through', () => {
    it('passes testID prop to HTMLTextNative', () => {
      render(<HTMLText html="<p>Hello</p>" testID="html-content" />);
      expect(HTMLTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ testID: 'html-content' }),
        undefined
      );
    });

    it('preserves testID value exactly', () => {
      const testId = 'my-custom-test-id';
      render(<HTMLText html="<p>Hello</p>" testID={testId} />);
      expect(HTMLTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ testID: testId }),
        undefined
      );
    });

    it('component is queryable by testID', () => {
      render(<HTMLText html="<p>Hello</p>" testID="queryable-id" />);
      expect(screen.getByTestId('queryable-id')).toBeTruthy();
    });

    it('works when testID is undefined', () => {
      render(<HTMLText html="<p>Hello</p>" />);
      expect(HTMLTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ testID: undefined }),
        undefined
      );
    });
  });

  describe('Re-Rendering on Prop Changes', () => {
    it('html prop change triggers re-render', () => {
      const { rerender } = render(<HTMLText html="<p>Old</p>" />);
      jest.clearAllMocks();
      rerender(<HTMLText html="<p>New</p>" />);
      expect(HTMLTextNative).toHaveBeenCalled();
    });

    it('HTMLTextNative receives updated html', () => {
      const { rerender } = render(<HTMLText html="<p>Old</p>" />);
      jest.clearAllMocks();
      rerender(<HTMLText html="<p>New</p>" />);
      expect(HTMLTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ html: '<p>New</p>' }),
        undefined
      );
    });

    it('changing from empty to valid html renders component', () => {
      const { rerender, toJSON } = render(<HTMLText html="" />);
      expect(toJSON()).toBeNull();
      rerender(<HTMLText html="<p>Hello</p>" />);
      expect(toJSON()).not.toBeNull();
    });

    it('changing from valid to empty html renders null', () => {
      const { rerender, toJSON } = render(<HTMLText html="<p>Hello</p>" />);
      expect(toJSON()).not.toBeNull();
      rerender(<HTMLText html="" />);
      expect(toJSON()).toBeNull();
    });
  });

  describe('Type Exports', () => {
    it('HTMLTextProps type is exported from component', () => {
      const props: import('../components/HTMLText').HTMLTextProps = {
        html: '<p>Test</p>',
        style: { color: 'red' },
        testID: 'test',
      };
      expect(props.html).toBe('<p>Test</p>');
    });

    it('HTMLText and HTMLTextProps are exported from index', async () => {
      const indexExports = await import('../index');
      expect(indexExports.HTMLText).toBeDefined();
      expect(typeof indexExports.HTMLText).toBe('function');
    });
  });
});
