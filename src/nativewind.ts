/**
 * NativeWind-compatible exports with cssInterop pre-applied.
 *
 * @example
 * ```tsx
 * import { RichText } from 'react-native-fabric-rich-text/nativewind';
 *
 * <RichText
 *   text="<p>Hello World</p>"
 *   className="text-blue-500 text-lg"
 * />
 * ```
 *
 * @requires nativewind ^4.1.0 as peer dependency
 */

import { cssInterop } from 'nativewind';
import {
  RichText as BaseRichText,
  FabricRichText as BaseFabricRichText,
} from './index';

// Apply cssInterop to map className → style
cssInterop(BaseRichText, { className: 'style' });
cssInterop(BaseFabricRichText, { className: 'style' });

// Re-export with cssInterop applied
export { BaseRichText as RichText, BaseFabricRichText as FabricRichText };

// Re-export types and utilities
export type { RichTextProps, DetectedContentType } from './index';
export { sanitize, ALLOWED_TAGS, ALLOWED_ATTR } from './index';
