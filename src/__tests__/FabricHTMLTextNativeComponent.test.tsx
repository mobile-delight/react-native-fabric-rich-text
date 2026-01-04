import FabricHTMLText from '../FabricHTMLTextNativeComponent';

describe('FabricHTMLTextNativeComponent', () => {
  it('should accept html prop', () => {
    const element = <FabricHTMLText html="<p>Test</p>" />;
    expect(element.props.html).toBe('<p>Test</p>');
  });

  it('should accept optional style prop', () => {
    const style = { padding: 16 };
    const element = <FabricHTMLText html="<p>Test</p>" style={style} />;
    expect(element.props.style).toBe(style);
  });

  it('should accept optional testID prop', () => {
    const element = <FabricHTMLText html="<p>Test</p>" testID="my-test" />;
    expect(element.props.testID).toBe('my-test');
  });
});
