import { render } from '@testing-library/react-native';
import { RichTextNative } from '../../adapters/native';

describe('RichTextNative', () => {
  it('should render with text prop and forward it to native view', () => {
    const { toJSON } = render(<RichTextNative text="<p>Test</p>" />);
    const tree = toJSON();
    expect(tree).toBeTruthy();
    if (tree && !Array.isArray(tree)) {
      expect(tree.props.text).toBe('<p>Test</p>');
    }
  });

  it('should forward style prop value to native view', () => {
    const style = { fontSize: 16 };
    const { toJSON } = render(
      <RichTextNative text="<p>Test</p>" style={style} />
    );
    const tree = toJSON();
    expect(tree).toBeTruthy();
    if (tree && !Array.isArray(tree)) {
      expect(tree.props.style).toEqual(expect.objectContaining(style));
    }
  });

  it('should forward testID prop to native view', () => {
    const { getByTestId } = render(
      <RichTextNative text="<p>Test</p>" testID="my-test" />
    );
    expect(getByTestId('my-test')).toBeTruthy();
  });

  it('should forward empty text string to native view', () => {
    const { toJSON } = render(<RichTextNative text="" />);
    const tree = toJSON();
    expect(tree).toBeTruthy();
    if (tree && !Array.isArray(tree)) {
      expect(tree.props.text).toBe('');
    }
  });

  describe('XSS protection', () => {
    it('should pass script tags to native view for handling', () => {
      const { toJSON } = render(
        <RichTextNative text="<script>alert('xss')</script>Safe text" />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.text).toBe("<script>alert('xss')</script>Safe text");
      }
    });

    it('should pass event handlers to native view for handling', () => {
      const { toJSON } = render(
        <RichTextNative text='<p onclick="alert(1)">Text</p>' />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.text).toBe('<p onclick="alert(1)">Text</p>');
      }
    });

    it('should pass javascript URLs to native view for handling', () => {
      const { toJSON } = render(
        <RichTextNative text='<a href="javascript:alert(1)">Link</a>' />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.text).toBe('<a href="javascript:alert(1)">Link</a>');
      }
    });
  });

  describe('accessibility', () => {
    it('should forward accessibility props to native view', () => {
      const { toJSON } = render(
        <RichTextNative
          text="<p>Accessible text</p>"
          accessible={true}
          accessibilityLabel="Test label"
        />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.accessible).toBe(true);
        expect(tree.props.accessibilityLabel).toBe('Test label');
      }
    });
  });
});
