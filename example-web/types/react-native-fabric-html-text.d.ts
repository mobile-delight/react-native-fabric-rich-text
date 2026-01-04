/**
 * Type shim for react-native-fabric-html-text web module
 * Fixes React version mismatch between library (React 19) and example-web (React 18)
 *
 * This is an ambient module declaration that TypeScript will pick up automatically
 * when the types directory is included in tsconfig.
 */
import type { FC } from 'react';

declare module 'react-native-fabric-html-text' {
  export interface HTMLTextProps {
    html: string;
    style?: React.CSSProperties;
    className?: string;
    testID?: string;
    onLinkPress?: (url: string, type: 'link' | 'email' | 'phone') => void;
    detectLinks?: boolean;
    detectPhoneNumbers?: boolean;
    detectEmails?: boolean;
    numberOfLines?: number;
  }

  export const HTMLText: FC<HTMLTextProps>;
  const defaultExport: FC<HTMLTextProps>;
  export default defaultExport;

  export function sanitize(html: string | null | undefined): string;
  export const ALLOWED_TAGS: readonly string[];
  export const ALLOWED_ATTR: readonly string[];

  export type DetectedContentType = 'link' | 'email' | 'phone';

  export const FabricHTMLText: () => never;
}
