import { render } from '@testing-library/react-native';
import { RichTextNative } from '../../adapters/native';

describe('RichTextNative Integration', () => {
  describe('text prop', () => {
    it('should render component with text prop', () => {
      const { toJSON } = render(<RichTextNative text="<p>Hello World</p>" />);
      expect(toJSON()).toBeTruthy();
    });

    it('should pass text prop to native view', () => {
      const { toJSON } = render(
        <RichTextNative text="<strong>Bold</strong>" />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.text).toBe('<strong>Bold</strong>');
      }
    });

    it('should handle complex HTML with multiple tags', () => {
      const markup = '<p><strong>Bold</strong> and <em>italic</em></p>';
      const { toJSON } = render(<RichTextNative text={markup} />);
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.text).toBe(markup);
      }
    });
  });

  describe('style prop', () => {
    it('should forward style prop to native view', () => {
      const style = { fontSize: 16, color: 'red' };
      const { toJSON } = render(
        <RichTextNative text="<p>Test</p>" style={style} />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.style).toBeDefined();
      }
    });

    it('should accept undefined style prop', () => {
      const { toJSON } = render(
        <RichTextNative text="<p>Test</p>" style={undefined} />
      );
      expect(toJSON()).toBeTruthy();
    });
  });

  describe('testID prop', () => {
    it('should forward testID prop to native view', () => {
      const { getByTestId } = render(
        <RichTextNative text="<p>Test</p>" testID="my-test-id" />
      );
      expect(getByTestId('my-test-id')).toBeTruthy();
    });

    it('should accept undefined testID prop', () => {
      const { toJSON } = render(
        <RichTextNative text="<p>Test</p>" testID={undefined} />
      );
      expect(toJSON()).toBeTruthy();
    });
  });

  describe('empty input handling', () => {
    it('should render without errors for empty text', () => {
      const { toJSON } = render(<RichTextNative text="" />);
      expect(toJSON()).toBeTruthy();
    });

    it('should pass empty string to native view', () => {
      const { toJSON } = render(<RichTextNative text="" />);
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.text).toBe('');
      }
    });
  });

  describe('combined props', () => {
    it('should accept all props together', () => {
      const { toJSON, getByTestId } = render(
        <RichTextNative
          text="<h1>Title</h1>"
          style={{ fontSize: 24 }}
          testID="title-component"
        />
      );

      expect(toJSON()).toBeTruthy();
      expect(getByTestId('title-component')).toBeTruthy();

      const tree = toJSON();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.text).toBe('<h1>Title</h1>');
        expect(tree.props.style).toBeDefined();
      }
    });
  });

  describe('security - XSS vectors', () => {
    it('should handle script tags in text prop', () => {
      const { toJSON } = render(
        <RichTextNative text="<script>alert('xss')</script>Safe text" />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.text).toBe("<script>alert('xss')</script>Safe text");
      }
    });

    it('should handle event handler attributes', () => {
      const { toJSON } = render(
        <RichTextNative text='<p onclick="alert(1)">Click me</p>' />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.text).toBe('<p onclick="alert(1)">Click me</p>');
      }
    });

    it('should handle javascript URLs', () => {
      const { toJSON } = render(
        <RichTextNative text='<a href="javascript:void(0)">Link</a>' />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
    });

    it('should handle iframe tags', () => {
      const { toJSON } = render(
        <RichTextNative text='<iframe src="malicious.com"></iframe>Safe' />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
    });

    it('should handle nested malicious content in allowed tags', () => {
      const { toJSON } = render(
        <RichTextNative text="<p><script>evil()</script>Safe</p>" />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.text).toBe('<p><script>evil()</script>Safe</p>');
      }
    });
  });
});
