// Web-specific entry point - excludes native components that require react-native
import RichTextComponent from './components/RichText.web';
export type { RichTextProps } from './components/RichText';

// Export both as named and default for flexibility
export const RichText = RichTextComponent;
export default RichTextComponent;

export { sanitize, ALLOWED_TAGS, ALLOWED_ATTR } from './core/sanitize.web';

// Re-export DetectedContentType for API compatibility
export type DetectedContentType = 'link' | 'email' | 'phone';

// Accessibility link focus types
export type {
  LinkFocusEvent,
  LinkFocusType,
} from './types/RichTextNativeProps';

// FabricRichText is not available on web - provide a helpful error if accessed
export const FabricRichText = (): never => {
  throw new Error(
    'FabricRichText is not available on web. Use RichText instead.'
  );
};
