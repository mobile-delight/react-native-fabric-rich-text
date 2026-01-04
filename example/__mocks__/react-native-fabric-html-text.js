const React = require('react');
const { View, Text } = require('react-native');

const HTMLText = ({ html, children, ...props }) =>
  React.createElement(
    View,
    { testID: 'html-text', ...props },
    React.createElement(Text, null, html || children)
  );

module.exports = {
  HTMLText,
  FabricHTMLText: HTMLText,
  sanitize: (html) => html,
  ALLOWED_TAGS: [],
  ALLOWED_ATTR: [],
  DetectedContentType: {},
};
