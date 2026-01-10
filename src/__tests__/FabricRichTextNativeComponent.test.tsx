import FabricRichText from '../FabricRichTextNativeComponent';

describe('FabricRichTextNativeComponent', () => {
  it('should accept text prop', () => {
    const element = <FabricRichText text="<p>Test</p>" />;
    expect(element.props.text).toBe('<p>Test</p>');
  });

  it('should accept optional style prop', () => {
    const style = { padding: 16 };
    const element = <FabricRichText text="<p>Test</p>" style={style} />;
    expect(element.props.style).toBe(style);
  });

  it('should accept optional testID prop', () => {
    const element = <FabricRichText text="<p>Test</p>" testID="my-test" />;
    expect(element.props.testID).toBe('my-test');
  });
});
