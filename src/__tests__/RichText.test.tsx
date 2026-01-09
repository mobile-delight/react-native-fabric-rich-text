import { render, screen } from '@testing-library/react-native';

// Mock the RichTextNative component - use require inside factory to access Text
jest.mock('../adapters/native', () => {
  const mockReact = require('react');
  const { Text } = require('react-native');
  return {
    RichTextNative: jest.fn(
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

import { RichTextNative } from '../adapters/native';

import RichText from '../components/RichText';

describe('RichText', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Edge Case Handling', () => {
    it('returns null for empty string html', () => {
      const { toJSON } = render(<RichText html="" />);
      expect(toJSON()).toBeNull();
    });

    it('returns null for undefined html', () => {
      const { toJSON } = render(
        <RichText html={undefined as unknown as string} />
      );
      expect(toJSON()).toBeNull();
    });

    it('returns null for null html', () => {
      const { toJSON } = render(<RichText html={null as unknown as string} />);
      expect(toJSON()).toBeNull();
    });

    it('returns null for whitespace-only html', () => {
      const { toJSON } = render(<RichText html={'   \n\t   '} />);
      expect(toJSON()).toBeNull();
    });

    it('renders nothing for empty input', () => {
      render(<RichText html="" />);
      expect(RichTextNative).not.toHaveBeenCalled();
    });

    it('renders nothing for whitespace-only input', () => {
      render(<RichText html={'   \n\t   '} />);
      expect(RichTextNative).not.toHaveBeenCalled();
    });
  });

  describe('Native Adapter Integration', () => {
    it('passes html prop to RichTextNative', () => {
      render(<RichText html="<p>Hello</p>" />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ html: '<p>Hello</p>' }),
        undefined
      );
    });

    it('passes exact html value to RichTextNative', () => {
      const testHtml = '<strong>Bold text</strong>';
      render(<RichText html={testHtml} />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ html: testHtml }),
        undefined
      );
    });
  });

  describe('Style Prop Pass-Through', () => {
    it('passes style prop to RichTextNative', () => {
      const testStyle = { color: 'red', fontSize: 16 };
      render(<RichText html="<p>Hello</p>" style={testStyle} />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ style: testStyle }),
        undefined
      );
    });

    it('preserves style prop value exactly', () => {
      const complexStyle = { fontWeight: 'bold' as const, marginTop: 10 };
      render(<RichText html="<p>Hello</p>" style={complexStyle} />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ style: complexStyle }),
        undefined
      );
    });

    it('works when style is undefined', () => {
      render(<RichText html="<p>Hello</p>" />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ style: undefined }),
        undefined
      );
    });
  });

  describe('TestID Prop Pass-Through', () => {
    it('passes testID prop to RichTextNative', () => {
      render(<RichText html="<p>Hello</p>" testID="html-content" />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ testID: 'html-content' }),
        undefined
      );
    });

    it('preserves testID value exactly', () => {
      const testId = 'my-custom-test-id';
      render(<RichText html="<p>Hello</p>" testID={testId} />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ testID: testId }),
        undefined
      );
    });

    it('component is queryable by testID', () => {
      render(<RichText html="<p>Hello</p>" testID="queryable-id" />);
      expect(screen.getByTestId('queryable-id')).toBeTruthy();
    });

    it('works when testID is undefined', () => {
      render(<RichText html="<p>Hello</p>" />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ testID: undefined }),
        undefined
      );
    });
  });

  describe('Re-Rendering on Prop Changes', () => {
    it('html prop change triggers re-render', () => {
      const { rerender } = render(<RichText html="<p>Old</p>" />);
      jest.clearAllMocks();
      rerender(<RichText html="<p>New</p>" />);
      expect(RichTextNative).toHaveBeenCalled();
    });

    it('RichTextNative receives updated html', () => {
      const { rerender } = render(<RichText html="<p>Old</p>" />);
      jest.clearAllMocks();
      rerender(<RichText html="<p>New</p>" />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ html: '<p>New</p>' }),
        undefined
      );
    });

    it('changing from empty to valid html renders component', () => {
      const { rerender, toJSON } = render(<RichText html="" />);
      expect(toJSON()).toBeNull();
      rerender(<RichText html="<p>Hello</p>" />);
      expect(toJSON()).not.toBeNull();
    });

    it('changing from valid to empty html renders null', () => {
      const { rerender, toJSON } = render(<RichText html="<p>Hello</p>" />);
      expect(toJSON()).not.toBeNull();
      rerender(<RichText html="" />);
      expect(toJSON()).toBeNull();
    });
  });

  describe('Type Exports', () => {
    it('RichTextProps type is exported from component', () => {
      const props: import('../components/RichText').RichTextProps = {
        html: '<p>Test</p>',
        style: { color: 'red' },
        testID: 'test',
      };
      expect(props.html).toBe('<p>Test</p>');
    });

    it('RichText and RichTextProps are exported from index', async () => {
      const indexExports = await import('../index');
      expect(indexExports.RichText).toBeDefined();
      expect(typeof indexExports.RichText).toBe('function');
    });
  });
});
