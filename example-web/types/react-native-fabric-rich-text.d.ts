/**
 * Type shim for react-native-fabric-rich-text web module
 *
 * This is an ambient module declaration that TypeScript will pick up automatically
 * when the types directory is included in tsconfig.
 */
import type { FC } from 'react';

declare module 'react-native-fabric-rich-text' {
  export interface RichTextProps {
    text: string;
    style?: React.CSSProperties;
    className?: string;
    testID?: string;
    onLinkPress?: (url: string, type: 'link' | 'email' | 'phone') => void;
    detectLinks?: boolean;
    detectPhoneNumbers?: boolean;
    detectEmails?: boolean;
    numberOfLines?: number;
    /** Custom styles for specific HTML tags (not supported on web) */
    tagStyles?: Record<string, React.CSSProperties>;
    /** Animation duration for truncation changes in ms (not supported on web) */
    animationDuration?: number;
  }

  export const RichText: FC<RichTextProps>;
  const defaultExport: FC<RichTextProps>;
  export default defaultExport;

  export function sanitize(text: string | null | undefined): string;
  export const ALLOWED_TAGS: readonly string[];
  export const ALLOWED_ATTR: readonly string[];

  export type DetectedContentType = 'link' | 'email' | 'phone';

  export const FabricRichText: () => never;
}
