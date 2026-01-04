import { render } from '@testing-library/react-native';
import { HTMLTextNative } from '../../adapters/native';

describe('HTMLTextNative', () => {
  it('should render with html prop and forward it to native view', () => {
    const { toJSON } = render(<HTMLTextNative html="<p>Test</p>" />);
    const tree = toJSON();
    expect(tree).toBeTruthy();
    if (tree && !Array.isArray(tree)) {
      expect(tree.props.html).toBe('<p>Test</p>');
    }
  });

  it('should forward style prop value to native view', () => {
    const style = { fontSize: 16 };
    const { toJSON } = render(
      <HTMLTextNative html="<p>Test</p>" style={style} />
    );
    const tree = toJSON();
    expect(tree).toBeTruthy();
    if (tree && !Array.isArray(tree)) {
      expect(tree.props.style).toEqual(expect.objectContaining(style));
    }
  });

  it('should forward testID prop to native view', () => {
    const { getByTestId } = render(
      <HTMLTextNative html="<p>Test</p>" testID="my-test" />
    );
    expect(getByTestId('my-test')).toBeTruthy();
  });

  it('should forward empty html string to native view', () => {
    const { toJSON } = render(<HTMLTextNative html="" />);
    const tree = toJSON();
    expect(tree).toBeTruthy();
    if (tree && !Array.isArray(tree)) {
      expect(tree.props.html).toBe('');
    }
  });

  describe('XSS protection', () => {
    it('should pass script tags to native view for handling', () => {
      const { toJSON } = render(
        <HTMLTextNative html="<script>alert('xss')</script>Safe text" />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.html).toBe("<script>alert('xss')</script>Safe text");
      }
    });

    it('should pass event handlers to native view for handling', () => {
      const { toJSON } = render(
        <HTMLTextNative html='<p onclick="alert(1)">Text</p>' />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.html).toBe('<p onclick="alert(1)">Text</p>');
      }
    });

    it('should pass javascript URLs to native view for handling', () => {
      const { toJSON } = render(
        <HTMLTextNative html='<a href="javascript:alert(1)">Link</a>' />
      );
      const tree = toJSON();
      expect(tree).toBeTruthy();
      if (tree && !Array.isArray(tree)) {
        expect(tree.props.html).toBe('<a href="javascript:alert(1)">Link</a>');
      }
    });
  });

  describe('accessibility', () => {
    it('should forward accessibility props to native view', () => {
      const { toJSON } = render(
        <HTMLTextNative
          html="<p>Accessible text</p>"
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
