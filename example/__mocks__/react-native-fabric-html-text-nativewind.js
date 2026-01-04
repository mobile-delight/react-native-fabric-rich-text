const React = require('react');
const { View, Text } = require('react-native');

const MockHTMLText = React.forwardRef((props, ref) => {
  return React.createElement(
    View,
    { ref, testID: props.testID, style: props.style },
    React.createElement(Text, null, props.html || '')
  );
});

module.exports = {
  HTMLText: MockHTMLText,
  FabricHTMLText: MockHTMLText,
  sanitize: jest.fn((html) => html),
  ALLOWED_TAGS: [],
  ALLOWED_ATTR: [],
};
