import type { ViewProps, TextStyle } from 'react-native';
import type { RichTextNativeProps } from '../../types/RichTextNativeProps';

describe('RichTextNativeProps', () => {
  it('should extend ViewProps', () => {
    const props: RichTextNativeProps = {
      html: '<p>Test</p>',
    };
    const viewProps: ViewProps = props;
    expect(viewProps).toBeDefined();
  });

  it('should require html property as string', () => {
    const props: RichTextNativeProps = {
      html: '<p>Test</p>',
    };
    expect(typeof props.html).toBe('string');
  });

  it('should accept optional style property as TextStyle', () => {
    const style: TextStyle = {
      fontSize: 16,
      fontWeight: 'bold',
    };
    const props: RichTextNativeProps = {
      html: '<p>Test</p>',
      style,
    };
    expect(props.style).toBe(style);
  });

  it('should accept optional testID property as string', () => {
    const props: RichTextNativeProps = {
      html: '<p>Test</p>',
      testID: 'test-id',
    };
    expect(props.testID).toBe('test-id');
  });

  it('should work with all properties combined', () => {
    const props: RichTextNativeProps = {
      html: '<p>Test</p>',
      style: { fontSize: 14 },
      testID: 'my-test',
    };
    expect(props.html).toBeDefined();
    expect(props.style).toBeDefined();
    expect(props.testID).toBeDefined();
  });
});
