import { render, screen } from '@testing-library/react-native';

// Mock the RichTextNative component - use require inside factory to access Text
jest.mock('../adapters/native', () => {
  const mockReact = require('react');
  const { Text } = require('react-native');
  return {
    RichTextNative: jest.fn(
      ({
        text,
        style,
        testID,
      }: {
        text: string;
        style?: object;
        testID?: string;
      }) => {
        return mockReact.createElement(Text, { style, testID }, text);
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
    it('returns null for empty string text', () => {
      const { toJSON } = render(<RichText text="" />);
      expect(toJSON()).toBeNull();
    });

    it('returns null for undefined text', () => {
      const { toJSON } = render(
        <RichText text={undefined as unknown as string} />
      );
      expect(toJSON()).toBeNull();
    });

    it('returns null for null text', () => {
      const { toJSON } = render(<RichText text={null as unknown as string} />);
      expect(toJSON()).toBeNull();
    });

    it('returns null for whitespace-only text', () => {
      const { toJSON } = render(<RichText text={'   \n\t   '} />);
      expect(toJSON()).toBeNull();
    });

    it('renders nothing for empty input', () => {
      render(<RichText text="" />);
      expect(RichTextNative).not.toHaveBeenCalled();
    });

    it('renders nothing for whitespace-only input', () => {
      render(<RichText text={'   \n\t   '} />);
      expect(RichTextNative).not.toHaveBeenCalled();
    });
  });

  describe('Native Adapter Integration', () => {
    it('passes text prop to RichTextNative', () => {
      render(<RichText text="<p>Hello</p>" />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ text: '<p>Hello</p>' }),
        undefined
      );
    });

    it('passes exact html value to RichTextNative', () => {
      const testText = '<strong>Bold text</strong>';
      render(<RichText text={testText} />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ text: testText }),
        undefined
      );
    });
  });

  describe('Style Prop Pass-Through', () => {
    it('passes style prop to RichTextNative', () => {
      const testStyle = { color: 'red', fontSize: 16 };
      render(<RichText text="<p>Hello</p>" style={testStyle} />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ style: testStyle }),
        undefined
      );
    });

    it('preserves style prop value exactly', () => {
      const complexStyle = { fontWeight: 'bold' as const, marginTop: 10 };
      render(<RichText text="<p>Hello</p>" style={complexStyle} />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ style: complexStyle }),
        undefined
      );
    });

    it('works when style is undefined', () => {
      render(<RichText text="<p>Hello</p>" />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ style: undefined }),
        undefined
      );
    });
  });

  describe('TestID Prop Pass-Through', () => {
    it('passes testID prop to RichTextNative', () => {
      render(<RichText text="<p>Hello</p>" testID="html-content" />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ testID: 'html-content' }),
        undefined
      );
    });

    it('preserves testID value exactly', () => {
      const testId = 'my-custom-test-id';
      render(<RichText text="<p>Hello</p>" testID={testId} />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ testID: testId }),
        undefined
      );
    });

    it('component is queryable by testID', () => {
      render(<RichText text="<p>Hello</p>" testID="queryable-id" />);
      expect(screen.getByTestId('queryable-id')).toBeTruthy();
    });

    it('works when testID is undefined', () => {
      render(<RichText text="<p>Hello</p>" />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ testID: undefined }),
        undefined
      );
    });
  });

  describe('Re-Rendering on Prop Changes', () => {
    it('text prop change triggers re-render', () => {
      const { rerender } = render(<RichText text="<p>Old</p>" />);
      jest.clearAllMocks();
      rerender(<RichText text="<p>New</p>" />);
      expect(RichTextNative).toHaveBeenCalled();
    });

    it('RichTextNative receives updated html', () => {
      const { rerender } = render(<RichText text="<p>Old</p>" />);
      jest.clearAllMocks();
      rerender(<RichText text="<p>New</p>" />);
      expect(RichTextNative).toHaveBeenCalledWith(
        expect.objectContaining({ text: '<p>New</p>' }),
        undefined
      );
    });

    it('changing from empty to valid text renders component', () => {
      const { rerender, toJSON } = render(<RichText text="" />);
      expect(toJSON()).toBeNull();
      rerender(<RichText text="<p>Hello</p>" />);
      expect(toJSON()).not.toBeNull();
    });

    it('changing from valid to empty text renders null', () => {
      const { rerender, toJSON } = render(<RichText text="<p>Hello</p>" />);
      expect(toJSON()).not.toBeNull();
      rerender(<RichText text="" />);
      expect(toJSON()).toBeNull();
    });
  });

  describe('Type Exports', () => {
    it('RichTextProps type is exported from component', () => {
      const props: import('../components/RichText').RichTextProps = {
        text: '<p>Test</p>',
        style: { color: 'red' },
        testID: 'test',
      };
      expect(props.text).toBe('<p>Test</p>');
    });

    it('RichText and RichTextProps are exported from index', async () => {
      const indexExports = await import('../index');
      expect(indexExports.RichText).toBeDefined();
      expect(typeof indexExports.RichText).toBe('function');
    });
  });
});
