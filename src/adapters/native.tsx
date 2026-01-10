import { useCallback, useMemo, type ReactElement } from 'react';
import { processColor, StyleSheet, type TextStyle } from 'react-native';
import FabricRichText, {
  type DetectedContentType,
} from '../FabricRichTextNativeComponent';
import type { RichTextNativeProps } from '../types/RichTextNativeProps';

interface LinkPressEvent {
  nativeEvent: {
    url: string;
    type: DetectedContentType;
  };
}

interface LinkFocusChangeNativeEvent {
  nativeEvent: {
    focusedLinkIndex: number;
    url: string;
    type: string;
    totalLinks: number;
  };
}

interface RichTextMeasurementNativeEvent {
  nativeEvent: {
    measuredLineCount: number;
    visibleLineCount: number;
  };
}

export function RichTextNative(props: RichTextNativeProps): ReactElement {
  const {
    text,
    style,
    testID,
    onLinkPress,
    onLinkFocusChange,
    onRichTextMeasurement,
    tagStyles,
    className,
    detectLinks,
    detectPhoneNumbers,
    detectEmails,
    numberOfLines,
    animationDuration,
    writingDirection,
    ...rest
  } = props;

  const handleLinkPress = useCallback(
    (event: LinkPressEvent): void => {
      if (onLinkPress) {
        onLinkPress(event.nativeEvent.url, event.nativeEvent.type);
      }
    },
    [onLinkPress]
  );

  const handleLinkFocusChange = useCallback(
    (event: LinkFocusChangeNativeEvent): void => {
      if (onLinkFocusChange) {
        const { focusedLinkIndex, url, type, totalLinks } = event.nativeEvent;
        // Convert native event format to TypeScript LinkFocusEvent
        // Native uses -1 for container focus; we preserve that
        // Native uses empty string for null values; we convert to null
        onLinkFocusChange({
          focusedLinkIndex: focusedLinkIndex,
          url: url || null,
          type: type ? (type as 'link' | 'email' | 'phone' | 'detected') : null,
          totalLinks,
        });
      }
    },
    [onLinkFocusChange]
  );

  const handleRichTextMeasurement = useCallback(
    (event: RichTextMeasurementNativeEvent): void => {
      if (onRichTextMeasurement) {
        const { measuredLineCount, visibleLineCount } = event.nativeEvent;
        onRichTextMeasurement({
          measuredLineCount,
          visibleLineCount,
        });
      }
    },
    [onRichTextMeasurement]
  );

  const serializedTagStyles = useMemo((): string | undefined => {
    if (!tagStyles || Object.keys(tagStyles).length === 0) {
      return undefined;
    }
    try {
      return JSON.stringify(tagStyles);
    } catch (error) {
      if (__DEV__) {
        console.error('[RichText] Failed to serialize tagStyles:', error);
      }
      return undefined;
    }
  }, [tagStyles]);

  // Extract text style properties from style prop
  // These are passed as individual props to ensure C++ measurement and native rendering
  // use identical values (following AndroidTextInput pattern)
  // Use StyleSheet.flatten to handle style arrays (e.g., [styles.text, styles.debug])
  const textStyle = style
    ? (StyleSheet.flatten(style) as TextStyle)
    : undefined;
  const fontSize = textStyle?.fontSize;
  const lineHeight = textStyle?.lineHeight;
  const fontWeight = textStyle?.fontWeight;
  const fontFamily = textStyle?.fontFamily;
  const fontStyle = textStyle?.fontStyle;
  const letterSpacing = textStyle?.letterSpacing;
  const textAlign = textStyle?.textAlign;
  const color = textStyle?.color
    ? (processColor(textStyle.color) as number)
    : undefined;

  // Font scaling props - use defaults that match React Native Text behavior
  // allowFontScaling defaults to true (matches React Native default)
  // includeFontPadding defaults to true on Android (matches React Native default)
  const allowFontScaling = props.allowFontScaling ?? true;
  const includeFontPadding = props.includeFontPadding ?? true;
  const maxFontSizeMultiplier = props.maxFontSizeMultiplier;

  // Coerce negative numberOfLines to 0 (no limit)
  const effectiveNumberOfLines =
    numberOfLines !== undefined && numberOfLines < 0 ? 0 : numberOfLines;

  // Default animationDuration to 0.2 if not specified
  const effectiveAnimationDuration = animationDuration ?? 0.2;

  return (
    <FabricRichText
      text={text}
      style={style}
      testID={testID}
      onLinkPress={handleLinkPress}
      onLinkFocusChange={handleLinkFocusChange}
      onRichTextMeasurement={handleRichTextMeasurement}
      tagStyles={serializedTagStyles}
      className={className}
      fontSize={fontSize}
      lineHeight={lineHeight}
      fontWeight={fontWeight as string | undefined}
      fontFamily={fontFamily}
      fontStyle={fontStyle}
      letterSpacing={letterSpacing}
      textAlign={textAlign}
      color={color}
      allowFontScaling={allowFontScaling}
      includeFontPadding={includeFontPadding}
      maxFontSizeMultiplier={maxFontSizeMultiplier}
      detectLinks={detectLinks}
      detectPhoneNumbers={detectPhoneNumbers}
      detectEmails={detectEmails}
      numberOfLines={effectiveNumberOfLines}
      animationDuration={effectiveAnimationDuration}
      writingDirection={writingDirection}
      {...rest}
    />
  );
}
