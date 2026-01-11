// Web-specific entry point - excludes native components that require react-native
import HTMLTextComponent from './components/HTMLText.web';
export type { HTMLTextProps } from './components/HTMLText';

// Export both as named and default for flexibility
export const HTMLText = HTMLTextComponent;
export default HTMLTextComponent;

export { sanitize, ALLOWED_TAGS, ALLOWED_ATTR } from './core/sanitize.web';

// Re-export DetectedContentType for API compatibility
export type DetectedContentType = 'link' | 'email' | 'phone';

// Accessibility link focus types
export type {
  LinkFocusEvent,
  LinkFocusType,
} from './types/HTMLTextNativeProps';

// FabricHTMLText is not available on web - provide a helpful error if accessed
export const FabricHTMLText = (): never => {
  throw new Error(
    'FabricHTMLText is not available on web. Use HTMLText instead.'
  );
};
