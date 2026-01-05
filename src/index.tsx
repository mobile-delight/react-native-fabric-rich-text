export {
  default as FabricHTMLText,
  type DetectedContentType,
} from './FabricHTMLTextNativeComponent';

export { default as HTMLText, type HTMLTextProps } from './components/HTMLText';
export { sanitize, ALLOWED_TAGS, ALLOWED_ATTR } from './core/sanitize';
export type { WritingDirection } from './types/HTMLTextNativeProps';
