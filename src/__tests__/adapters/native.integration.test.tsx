import { render } from '@testing-library/react-native';
import { RichTextNative } from '../../adapters/native';

describe('RichTextNative Integration', () => {
  describe('html prop', () => {
    it('should render component with html prop', () => {
      const { toJSON } = render(<RichTextNative html="<p>Hello World</p>" />);
      expect(toJSON()).toBeTruthy();
    });

    it('should pass html prop to native view', () => {
      const { toJSON } = render(
        <RichTextNative html="<strong>Bold</strong>" />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.html).toBe('<strong>Bold</strong>');
      }
    });

    it('should handle complex HTML with multiple tags', () => {
      const html = '<p><strong>Bold</strong> and <em>italic</em></p>';
      const { toJSON } = render(<RichTextNative html={html} />);
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.html).toBe(html);
      }
    });
  });

  describe('style prop', () => {
    it('should forward style prop to native view', () => {
      const style = { fontSize: 16, color: 'red' };
      const { toJSON } = render(
        <RichTextNative html="<p>Test</p>" style={style} />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.style).toBeDefined();
      }
    });

    it('should accept undefined style prop', () => {
      const { toJSON } = render(
        <RichTextNative html="<p>Test</p>" style={undefined} />
      );
      expect(toJSON()).toBeTruthy();
    });
  });

  describe('testID prop', () => {
    it('should forward testID prop to native view', () => {
      const { getByTestId } = render(
        <RichTextNative html="<p>Test</p>" testID="my-test-id" />
      );
      expect(getByTestId('my-test-id')).toBeTruthy();
    });

    it('should accept undefined testID prop', () => {
      const { toJSON } = render(
        <RichTextNative html="<p>Test</p>" testID={undefined} />
      );
      expect(toJSON()).toBeTruthy();
    });
  });

  describe('empty input handling', () => {
    it('should render without errors for empty html', () => {
      const { toJSON } = render(<RichTextNative html="" />);
      expect(toJSON()).toBeTruthy();
    });

    it('should pass empty string to native view', () => {
      const { toJSON } = render(<RichTextNative html="" />);
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.html).toBe('');
      }
    });
  });

  describe('combined props', () => {
    it('should accept all props together', () => {
      const { toJSON, getByTestId } = render(
        <RichTextNative
          html="<h1>Title</h1>"
          style={{ fontSize: 24 }}
          testID="title-component"
        />
      );

      expect(toJSON()).toBeTruthy();
      expect(getByTestId('title-component')).toBeTruthy();

      const tree = toJSON();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.html).toBe('<h1>Title</h1>');
        expect(tree.props.style).toBeDefined();
      }
    });
  });

  describe('security - XSS vectors', () => {
    it('should handle script tags in html prop', () => {
      const { toJSON } = render(
        <RichTextNative html="<script>alert('xss')</script>Safe text" />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.html).toBe("<script>alert('xss')</script>Safe text");
      }
    });

    it('should handle event handler attributes', () => {
      const { toJSON } = render(
        <RichTextNative html='<p onclick="alert(1)">Click me</p>' />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.html).toBe('<p onclick="alert(1)">Click me</p>');
      }
    });

    it('should handle javascript URLs', () => {
      const { toJSON } = render(
        <RichTextNative html='<a href="javascript:void(0)">Link</a>' />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
    });

    it('should handle iframe tags', () => {
      const { toJSON } = render(
        <RichTextNative html='<iframe src="malicious.com"></iframe>Safe' />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
    });

    it('should handle nested malicious content in allowed tags', () => {
      const { toJSON } = render(
        <RichTextNative html="<p><script>evil()</script>Safe</p>" />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.html).toBe('<p><script>evil()</script>Safe</p>');
      }
    });
  });
});
