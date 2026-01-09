export {
  default as FabricRichText,
  type DetectedContentType,
} from './FabricRichTextNativeComponent';

export { default as RichText, type RichTextProps } from './components/RichText';
export { sanitize, ALLOWED_TAGS, ALLOWED_ATTR } from './core/sanitize';
export type { WritingDirection } from './types/RichTextNativeProps';

// Accessibility link focus types
export type {
  LinkFocusEvent,
  LinkFocusType,
} from './types/RichTextNativeProps';
