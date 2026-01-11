/**
 * Single source of truth for HTML renderer constants.
 *
 * DO NOT modify platform-specific constants in native code.
 * Instead, modify this file and run: yarn codegen:constants
 *
 * This file is used to generate:
 * - android/src/main/java/com/htmlrenderer/GeneratedConstants.kt
 * - ios/GeneratedConstants.swift
 */

// =============================================================================
// Allowed Tags
// =============================================================================

/**
 * HTML tags allowed in rendered content.
 * These are the only tags that pass through sanitization.
 */
export const ALLOWED_TAGS = [
  // Structure
  'p',
  'div',
  // Headings
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  // Formatting
  'strong',
  'b',
  'em',
  'i',
  'u',
  's',
  'del',
  // Inline
  'span',
  'br',
  'a',
  // Bidirectional text support
  'bdi', // Bidirectional isolation
  'bdo', // Bidirectional override
  // Block
  'blockquote',
  'pre',
  // Lists
  'ul',
  'ol',
  'li',
] as const;

/**
 * HTML attributes allowed in rendered content.
 * Note: 'style' is allowed for accessibility features (hidden description spans
 * for screen readers). DOMPurify handles inline CSS sanitization.
 */
export const ALLOWED_ATTRIBUTES = [
  'href',
  'class',
  'dir',
  'aria-describedby',
  'style',
] as const;

/**
 * Allowed URL protocols for href attributes.
 */
export const ALLOWED_PROTOCOLS = ['http', 'https', 'mailto', 'tel'] as const;

/**
 * Allowed values for the dir attribute (text direction).
 * Invalid values are stripped during sanitization.
 */
export const ALLOWED_DIR_VALUES = ['ltr', 'rtl', 'auto'] as const;

// =============================================================================
// Heading Scales
// =============================================================================

/**
 * Scale factors for heading elements relative to base font size.
 * Matches CSS default heading sizes.
 */
export const HEADING_SCALES: Record<string, number> = {
  h1: 2.0,
  h2: 1.5,
  h3: 1.17,
  h4: 1.0,
  h5: 0.83,
  h6: 0.67,
};

// =============================================================================
// Named Colors
// =============================================================================

/**
 * CSS named colors mapped to ARGB integer values.
 * Format: 0xAARRGGBB where AA=alpha, RR=red, GG=green, BB=blue
 */
export const NAMED_COLORS: Record<string, number> = {
  red: 0xffff0000,
  green: 0xff00ff00,
  blue: 0xff0000ff,
  black: 0xff000000,
  white: 0xffffffff,
  gray: 0xff888888,
  grey: 0xff888888, // Alias for gray
  orange: 0xffffa500,
  yellow: 0xffffff00,
  purple: 0xff800080,
  cyan: 0xff00ffff,
  magenta: 0xffff00ff,
};

// =============================================================================
// Typography
// =============================================================================

/**
 * Default base font size in points (iOS) / SP (Android).
 */
export const DEFAULT_FONT_SIZE = 14;

/**
 * Font weight values that represent bold styling.
 * Matches CSS font-weight semantics where 700+ is bold.
 */
export const BOLD_WEIGHTS = ['bold', '700', '800', '900'] as const;

// =============================================================================
// List Styling
// =============================================================================

/**
 * Indent per nesting level for lists in Android pixels.
 */
export const LIST_INDENT_ANDROID_PX = 32;

/**
 * Indent per nesting level for lists in iOS points.
 */
export const LIST_INDENT_IOS_PT = 16;

/**
 * Maximum nesting depth for lists.
 */
export const MAX_LIST_NESTING_LEVEL = 3;

/**
 * Bullet marker for unordered lists.
 */
export const BULLET_MARKER = '\u2022 ';

// =============================================================================
// Links
// =============================================================================

/**
 * Default link color (Google Blue) as ARGB integer.
 */
export const LINK_COLOR = 0xff1a73e8;

// =============================================================================
// Spacing
// =============================================================================

/**
 * Paragraph spacing in iOS points.
 */
export const PARAGRAPH_SPACING_IOS_PT = 8;

/**
 * List marker width in iOS points.
 */
export const LIST_MARKER_WIDTH_IOS_PT = 4;
