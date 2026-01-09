const React = require('react');
const { View, Text } = require('react-native');

const RichText = ({ html, children, ...props }) =>
  React.createElement(
    View,
    { testID: 'html-text', ...props },
    React.createElement(Text, null, html || children)
  );

module.exports = {
  RichText,
  FabricRichText: RichText,
  sanitize: (html) => html,
  ALLOWED_TAGS: [],
  ALLOWED_ATTR: [],
  DetectedContentType: {},
};
