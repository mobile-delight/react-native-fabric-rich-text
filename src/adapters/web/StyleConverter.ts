import type { TextStyle } from 'react-native';
import type { CSSProperties } from 'react';

/**
 * Converts React Native TextStyle to CSS CSSProperties.
 * Transforms numeric values to px strings where appropriate.
 */
export function convertStyle(style?: TextStyle): CSSProperties {
  if (!style) {
    return {};
  }

  const cssStyle: CSSProperties = {};

  if (style.fontSize !== undefined) {
    cssStyle.fontSize = `${style.fontSize}px`;
  }

  if (style.fontWeight !== undefined) {
    cssStyle.fontWeight = style.fontWeight;
  }

  if (style.color !== undefined && style.color !== null) {
    cssStyle.color = style.color as string;
  }

  if (style.lineHeight !== undefined) {
    cssStyle.lineHeight = `${style.lineHeight}px`;
  }

  if (style.fontFamily !== undefined) {
    cssStyle.fontFamily = style.fontFamily;
  }

  if (style.fontStyle !== undefined) {
    cssStyle.fontStyle = style.fontStyle;
  }

  if (style.textAlign !== undefined) {
    cssStyle.textAlign = style.textAlign as CSSProperties['textAlign'];
  }

  if (style.textDecorationLine !== undefined) {
    cssStyle.textDecoration = style.textDecorationLine;
  }

  if (style.textTransform !== undefined) {
    cssStyle.textTransform = style.textTransform;
  }

  if (style.letterSpacing !== undefined) {
    cssStyle.letterSpacing = `${style.letterSpacing}px`;
  }

  return cssStyle;
}
