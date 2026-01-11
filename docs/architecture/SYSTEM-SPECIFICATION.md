# FabricRichText System Specification

A comprehensive technical reference for the `react-native-fabric-rich-text` library - a cross-platform HTML text rendering solution for React Native Fabric, React Native Web, and Next.js.

---

## Table of Contents

1. [Core RichText Component](#1-core-richtext-component)
2. [HTML Parsing & Sanitization](#2-html-parsing--sanitization)
3. [Fabric Architecture Integration](#3-fabric-architecture-integration)
4. [C++ Shared Parsing Layer](#4-c-shared-parsing-layer)
5. [iOS Native Rendering](#5-ios-native-rendering)
6. [Android Native Rendering](#6-android-native-rendering)
7. [Web Implementation](#7-web-implementation)
8. [Text Truncation System](#8-text-truncation-system)
9. [Link Handling System](#9-link-handling-system)
10. [Accessibility Implementation](#10-accessibility-implementation)
11. [NativeWind Integration](#11-nativewind-integration)
12. [Security Model](#12-security-model)

---

## 1. Core RichText Component

### What It Is

The `RichText` component is the public API for rendering sanitized HTML content as styled native text. It provides a React component interface that works identically across iOS, Android, and Web platforms.

### Why We Need It

React Native lacks built-in HTML rendering support. Existing solutions either:
- Use WebViews (slow, inconsistent sizing, security concerns)
- Implement custom JS parsers (don't integrate with native text systems)
- Require bridge crossing for measurement (async, causes layout jumps)

RichText solves this by providing a true native text component that:
- Renders HTML as native `Text` (not a WebView)
- Measures synchronously in the Fabric Shadow Tree
- Integrates with accessibility, fonts, and theming systems

### How It Works

```tsx
import { RichText } from 'react-native-fabric-rich-text';

<RichText
  text="<p>Hello <strong>World</strong></p>"
  style={{ fontSize: 16, color: '#333' }}
  numberOfLines={3}
  onLinkPress={(url, type) => Linking.openURL(url)}
/>
```

The component:
1. Accepts `text` (HTML string) and React Native TextStyle props
2. Routes to platform-specific adapters (native vs web)
3. Passes props through Fabric's codegen-generated native component spec
4. Renders as native styled text with full accessibility support

### Props Interface

```typescript
interface RichTextProps {
  // Content
  text: string;                              // HTML markup to render (required)

  // Styling
  style?: TextStyle;                         // React Native text styles
  className?: string;                        // NativeWind/Tailwind classes
  tagStyles?: Record<string, TextStyle>;     // Per-tag style overrides

  // Link handling
  onLinkPress?: (url: string, type: DetectedContentType) => void;
  detectLinks?: boolean;                     // Auto-detect URLs
  detectPhoneNumbers?: boolean;              // Auto-detect phone numbers
  detectEmails?: boolean;                    // Auto-detect emails

  // Layout
  numberOfLines?: number;                    // Truncation (0 = unlimited)
  animationDuration?: number;                // Height animation (default: 0.2s)
  writingDirection?: 'auto' | 'ltr' | 'rtl'; // Text direction

  // Accessibility
  onLinkFocusChange?: (event: LinkFocusEvent) => void;
  onRichTextMeasurement?: (data: RichTextMeasurementData) => void;

  // Font scaling
  allowFontScaling?: boolean;                // Enable accessibility scaling
  maxFontSizeMultiplier?: number;            // Max scale factor (0 = unlimited)
  includeFontPadding?: boolean;              // Android font padding

  // Testing
  testID?: string;
}
```

### Key Files

| File | Purpose |
|------|---------|
| `src/components/RichText.tsx` | Main React component |
| `src/components/RichText.web.tsx` | Web-specific implementation |
| `src/adapters/native.tsx` | Native platform adapter |
| `src/FabricRichTextNativeComponent.ts` | Codegen native component spec |
| `src/types/RichTextNativeProps.ts` | TypeScript type definitions |

---

## 2. HTML Parsing & Sanitization

### What It Is

A multi-layer HTML processing pipeline that safely transforms untrusted HTML input into platform-specific styled text representations.

### Why We Need It

HTML from external sources (APIs, CMS, user input) can contain:
- XSS attack vectors (`<script>`, `onclick`, `javascript:` URLs)
- Unsupported tags that would break rendering
- Malformed markup that causes parser errors

### How It Works

**Platform-Specific Sanitizers:**

| Platform | Library | Location |
|----------|---------|----------|
| iOS | SwiftSoup | `ios/FabricRichSanitizer.swift` |
| Android | OWASP Java HTML Sanitizer | `android/.../FabricRichSanitizer.kt` |
| Web (Browser) | DOMPurify | `src/core/sanitize.web.ts` |
| Web (SSR) | sanitize-html | `src/core/sanitize.web.ts` |

**Processing Pipeline:**

```
Raw HTML → Whitespace Normalization → Allowlist Sanitization → C++ Parsing → AttributedString
```

1. **Whitespace Normalization**: Remove inter-tag whitespace from JSX formatting
2. **Allowlist Sanitization**: Only allowed tags/attributes pass through
3. **C++ Parsing**: `FabricMarkupParser` converts to React Native's `AttributedString`
4. **Platform Rendering**: Convert to NSAttributedString (iOS) or Spannable (Android)

**Allowed Content (defined in `src/core/constants.ts`):**

```typescript
ALLOWED_TAGS = [
  'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'strong', 'b', 'em', 'i', 'u', 's', 'del',
  'span', 'br', 'a',
  'bdi', 'bdo',  // Bidirectional text support
  'blockquote', 'pre',
  'ul', 'ol', 'li'
]

ALLOWED_ATTRIBUTES = ['href', 'class', 'dir']
ALLOWED_PROTOCOLS = ['http', 'https', 'mailto', 'tel']
ALLOWED_DIR_VALUES = ['ltr', 'rtl', 'auto']
```

### Key Files

| File | Purpose |
|------|---------|
| `src/core/constants.ts` | Single source of truth for allowlists |
| `src/core/sanitize.ts` | Native pass-through (sanitization in native layer) |
| `src/core/sanitize.web.ts` | DOMPurify/sanitize-html web sanitization |
| `ios/FabricRichSanitizer.swift` | SwiftSoup iOS sanitizer |
| `android/.../FabricRichSanitizer.kt` | OWASP Android sanitizer |

---

## 3. Fabric Architecture Integration

### What It Is

The integration layer between React and native platforms using React Native's Fabric renderer (the "New Architecture").

### Why We Need It

The legacy React Native architecture has limitations:
- Async bridge causes layout jumps with dynamic content
- No synchronous measurement for custom content
- JSON serialization overhead for props
- No type safety across JS/native boundary

Fabric provides:
- Synchronous C++ Shadow Tree for layout
- Direct JSI communication (no bridge)
- Codegen-generated type-safe bindings
- Custom `measureContent()` for dynamic sizing

### How It Works

**Shadow Tree Flow:**

```
React Component → Props → ShadowNode → measureContent() → Yoga → Native View
                                ↓
                          setStateData()
                                ↓
                          updateState()
```

1. **Props Phase**: JS passes props via codegen-generated spec
2. **Layout Phase**: `FabricRichTextShadowNode::measureContent()` parses HTML and measures
3. **Commit Phase**: `layout()` calls `setStateData()` with parsed `AttributedString`
4. **Mount Phase**: Native view receives state and renders

**Codegen Specification:**

```typescript
// FabricRichTextNativeComponent.ts
export interface NativeProps extends ViewProps {
  text: string;
  fontSize?: Float;
  color?: ColorValue;
  numberOfLines?: Int32;
  onLinkPress?: DirectEventHandler<{ url: string; type: string }>;
  onLinkFocusChange?: DirectEventHandler<LinkFocusEventData>;
  onRichTextMeasurement?: DirectEventHandler<MeasurementData>;
  // ... more props
}

export default codegenNativeComponent<NativeProps>('FabricRichText');
```

This generates:
- C++ `FabricRichTextProps` struct
- C++ `FabricRichTextEventEmitter` for callbacks
- Swift/Kotlin view protocol/interface

### Key Files

| File | Purpose |
|------|---------|
| `src/FabricRichTextNativeComponent.ts` | Codegen component specification |
| `ios/FabricRichTextShadowNode.mm` | iOS shadow node with measureContent |
| `ios/FabricRichTextComponentDescriptor.h` | Fabric component descriptor |
| `android/.../jni/ShadowNodes.cpp` | Android shadow node with measureContent |
| `android/.../jni/FabricRichTextState.cpp` | State serialization to MapBuffer |

---

## 4. C++ Shared Parsing Layer

### What It Is

A cross-platform C++17 module that provides HTML parsing logic shared between iOS and Android, ensuring identical text measurement on both platforms.

### Why We Need It

Without shared parsing:
- iOS and Android would parse HTML differently
- Text would measure to different sizes
- Layout would be inconsistent across platforms

The shared C++ layer ensures:
- Identical parsing logic on both platforms
- Consistent `AttributedString` structure
- Same text measurement input to `TextLayoutManager`

### Module Architecture

The C++ parsing layer is organized into specialized modules:

```
cpp/
├── FabricMarkupParser.h/cpp        # Main entry point
└── parsing/
    ├── MarkupSegmentParser.h/cpp   # HTML → text segments
    ├── AttributedStringBuilder.h/cpp # Segments → AttributedString
    ├── StyleParser.h/cpp           # Tag style parsing
    ├── DirectionContext.h/cpp      # RTL/BiDi text support
    ├── TextNormalizer.h/cpp        # Whitespace normalization
    └── UnicodeUtils.h/cpp          # Unicode utilities
```

### FabricMarkupParser Interface

```cpp
// FabricMarkupParser.h
namespace facebook::react {

struct ParseResult {
  AttributedString attributedString;
  std::vector<std::string> linkUrls;
  std::string accessibilityLabel;
};

class FabricMarkupParser {
public:
  static std::string stripMarkupTags(const std::string& markup);
  static std::string normalizeInterTagWhitespace(const std::string& markup);

  static ParseResult parseMarkupWithLinkUrls(
    const std::string& markup,
    Float baseFontSize,
    Float fontSizeMultiplier,
    bool allowFontScaling,
    Float maxFontSizeMultiplier,
    Float lineHeight,
    const std::string& fontWeight,
    const std::string& fontFamily,
    const std::string& fontStyle,
    Float letterSpacing,
    int32_t color,
    const std::string& tagStylesJson,
    WritingDirection writingDirection
  );
};

} // namespace
```

### Parsing Modules

**MarkupSegmentParser**: Converts HTML markup to text segments with style information.

```cpp
struct FabricRichTextSegment {
  std::string text;
  float fontScale;          // Heading scale (h1=2.0, h2=1.5, etc.)
  bool isBold;
  bool isItalic;
  bool isUnderline;
  bool isStrikethrough;
  bool isLink;
  std::string linkUrl;
  std::string parentTag;
  WritingDirection writingDirection;
  bool isBdiIsolated;       // <bdi> isolation
  bool isBdoOverride;       // <bdo> direction override
};
```

**AttributedStringBuilder**: Converts segments to React Native's `AttributedString` format with:
- Font scaling (respects accessibility settings)
- Text decorations (underline, strikethrough)
- Colors (foreground, background)
- Line height and letter spacing
- Link URL indexing

**DirectionContext**: State machine for bidirectional text:
- Tracks `dir` attribute changes
- Handles `<bdi>` isolation
- Handles `<bdo>` direction override
- Generates Unicode BiDi characters (FSI/PDI)

**StyleParser**: Parses `tagStyles` JSON prop to apply custom styles per HTML tag.

### Key Files

| File | Purpose |
|------|---------|
| `cpp/FabricMarkupParser.cpp` | Main parser interface |
| `cpp/parsing/MarkupSegmentParser.cpp` | HTML to segments |
| `cpp/parsing/AttributedStringBuilder.cpp` | Segments to AttributedString |
| `cpp/parsing/StyleParser.cpp` | Tag style JSON parsing |
| `cpp/parsing/DirectionContext.cpp` | RTL/BiDi state machine |
| `cpp/parsing/TextNormalizer.cpp` | Whitespace cleanup |

---

## 5. iOS Native Rendering

### What It Is

The iOS-specific rendering layer that converts C++ `AttributedString` to `NSAttributedString` and renders using CoreText.

### How It Works

**Rendering Pipeline:**

```
C++ AttributedString → FabricRichFragmentParser → NSAttributedString → CoreText
                                                         ↓
                                              FabricRichCoreTextView
                                                         ↓
                                                   CTFrameDraw
```

**Component Structure:**

```objc
// FabricRichText.mm - Fabric Component View
@implementation FabricRichText

- (void)updateState:(const State::Shared&)state {
  auto stateData = std::static_pointer_cast<const FabricRichTextState>(state->getData());

  // Convert C++ fragments to NSAttributedString
  NSAttributedString *nsAttrString = [FabricRichFragmentParser
    buildAttributedStringFromCppAttributedString:stateData->attributedString
    withLinkUrls:stateData->linkUrls];

  _coreTextView.attributedText = nsAttrString;
  _coreTextView.accessibilityLabel = stateData->accessibilityLabel;
}

@end
```

**CoreText Rendering:**

```objc
// FabricRichCoreTextView.m
- (void)drawRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();

  // Flip coordinate system (CoreText uses bottom-left origin)
  CGContextTranslateCTM(context, 0, self.bounds.size.height);
  CGContextScaleCTM(context, 1.0, -1.0);

  CTFrameRef frame = [self ctFrame];

  if (_numberOfLines > 0) {
    [self drawTruncatedFrame:frame inContext:context maxLines:_numberOfLines];
  } else {
    CTFrameDraw(frame, context);
  }
}
```

### Key Files

| File | Purpose |
|------|---------|
| `ios/FabricRichText.mm` | Fabric component view |
| `ios/FabricRichTextShadowNode.mm` | Shadow node with measurement |
| `ios/FabricRichFragmentParser.mm` | C++ to NSAttributedString conversion |
| `ios/FabricRichCoreTextView.m` | CoreText-based rendering view |
| `ios/FabricRichSanitizer.swift` | SwiftSoup HTML sanitizer |
| `ios/FabricRichLinkAccessibilityElement.m` | Link accessibility |

---

## 6. Android Native Rendering

### What It Is

The Android-specific rendering layer that converts C++ state (via MapBuffer) to Spannable and renders using StaticLayout.

### How It Works

**State Transfer via MapBuffer:**

```cpp
// FabricRichTextState.cpp
MapBuffer FabricRichTextState::getMapBuffer() const {
  auto builder = MapBufferBuilder();
  builder.putMapBuffer(HTML_STATE_KEY_ATTRIBUTED_STRING,
                       toMapBuffer(attributedString));
  builder.putMapBuffer(HTML_STATE_KEY_LINK_URLS, linkUrlsBuffer);
  builder.putInt(HTML_STATE_KEY_NUMBER_OF_LINES, numberOfLines);
  builder.putDouble(HTML_STATE_KEY_ANIMATION_DURATION, animationDuration);
  builder.putString(HTML_STATE_KEY_ACCESSIBILITY_LABEL, accessibilityLabel);
  return builder.build();
}
```

**Kotlin Fragment Parser:**

```kotlin
// FabricHTMLFragmentParser.kt
fun buildSpannableFromFragments(fragments: List<TextFragment>): Spannable {
  val builder = SpannableStringBuilder()

  for (fragment in fragments) {
    val start = builder.length
    builder.append(fragment.text)
    val end = builder.length

    // Apply spans for styling
    builder.setSpan(AbsoluteSizeSpan(fragment.fontSize.toInt(), true), start, end, ...)
    if (isBold) builder.setSpan(StyleSpan(Typeface.BOLD), start, end, ...)
    if (fragment.linkUrl != null) builder.setSpan(HrefClickableSpan(fragment.linkUrl), ...)
  }
  return builder
}
```

**Architecture Pattern: Single Responsibility**

The Android implementation uses a thin orchestrator pattern:

```kotlin
// FabricRichTextView.kt delegates to specialized modules:
class FabricRichTextView : AppCompatTextView {
  private val truncationEngine: TextTruncationEngine
  private val linkDetectionManager: LinkDetectionManager
  private val accessibilityHelper: TextAccessibilityHelper
  private val layoutProvider: TextLayoutProvider
  private val styleApplier: TextStyleApplier
  private val heightAnimationController: HeightAnimationController
}
```

### Key Files

| File | Purpose |
|------|---------|
| `android/.../react/FabricHTMLTextViewManager.kt` | React Native view manager |
| `android/.../react/FabricHTMLFragmentParser.kt` | MapBuffer to Spannable |
| `android/.../react/FabricHTMLLayoutManager.kt` | Layout management |
| `android/.../java/FabricRichTextView.kt` | Custom rendering view |
| `android/.../java/FabricRichSpannableBuilder.kt` | Spannable construction |
| `android/.../java/FabricRichSanitizer.kt` | OWASP HTML sanitizer |
| `android/.../java/TextTruncationEngine.kt` | Word-boundary truncation |
| `android/.../java/LinkDetectionManager.kt` | URL/email/phone detection |
| `android/.../java/TextAccessibilityHelper.kt` | Accessibility calculations |
| `android/.../java/HeightAnimationController.kt` | Height animation |
| `android/.../jni/ShadowNodes.cpp` | C++ shadow node |
| `android/.../jni/FabricRichTextState.cpp` | State serialization |

---

## 7. Web Implementation

### What It Is

A Next.js/SSR-compatible web implementation that renders sanitized HTML using native browser capabilities.

### How It Works

**Environment Detection:**

```typescript
// sanitize.web.ts
const isBrowser = typeof window !== 'undefined';

if (isBrowser) {
  // Use DOMPurify (client-side)
  return DOMPurify.sanitize(html, config);
} else {
  // Use sanitize-html (SSR/Node.js)
  const sanitizeHtml = require('sanitize-html');
  return sanitizeHtml(html, nodeConfig);
}
```

**Web Component:**

```tsx
// RichText.web.tsx
export const RichText: React.FC<RichTextProps> = ({
  text,
  style,
  numberOfLines,
  onLinkPress,
}) => {
  const sanitizedHtml = useMemo(() => sanitize(text), [text]);
  const cssStyle = useMemo(() => StyleConverter.convert(style), [style]);

  const truncationStyle = numberOfLines ? {
    display: '-webkit-box',
    WebkitLineClamp: numberOfLines,
    WebkitBoxOrient: 'vertical',
    overflow: 'hidden',
  } : {};

  return (
    <div
      style={{ ...cssStyle, ...truncationStyle }}
      dangerouslySetInnerHTML={{ __html: sanitizedHtml }}
      onClick={handleLinkClick}
      aria-describedby={linkCount > 0 ? descriptionId : undefined}
    />
  );
};
```

**Style Conversion:**

```typescript
// StyleConverter.ts
export function convert(style?: TextStyle): CSSProperties {
  return {
    fontSize: style?.fontSize ? `${style.fontSize}px` : undefined,
    fontWeight: style?.fontWeight,
    color: style?.color,
    lineHeight: style?.lineHeight ? `${style.lineHeight}px` : undefined,
    letterSpacing: style?.letterSpacing ? `${style.letterSpacing}px` : undefined,
    fontFamily: style?.fontFamily,
    textAlign: style?.textAlign,
  };
}
```

### Key Files

| File | Purpose |
|------|---------|
| `src/index.web.tsx` | Web-specific exports |
| `src/components/RichText.web.tsx` | Web component implementation |
| `src/core/sanitize.web.ts` | DOMPurify/sanitize-html sanitization |
| `src/adapters/web/StyleConverter.ts` | TextStyle to CSS conversion |

---

## 8. Text Truncation System

### What It Is

A cross-platform text truncation feature that limits displayed lines and adds ellipsis, with optional animated height transitions.

### How It Works

**Props:**

```tsx
<RichText
  text={longContent}
  numberOfLines={3}        // 0 = unlimited
  animationDuration={0.2}  // Height animation in seconds
  onRichTextMeasurement={(data) => {
    // data.measuredLineCount - total lines without truncation
    // data.visibleLineCount - lines actually displayed
  }}
/>
```

**Platform Implementations:**

| Platform | Implementation |
|----------|----------------|
| C++ | `ParagraphAttributes.maximumNumberOfLines` for constrained measurement |
| iOS | `CTLineCreateTruncatedLine()` with ellipsis |
| Android | `StaticLayout.Builder.setMaxLines()` with `TruncateAt.END` |
| Web | CSS `-webkit-line-clamp` |

**Height Animation:**

Both iOS and Android animate height changes when `animationDuration > 0`:
- iOS: `UIView.animate(withDuration:)` with ease-in-out
- Android: `ValueAnimator` with `AccelerateDecelerateInterpolator`

---

## 9. Link Handling System

### What It Is

A system for detecting, rendering, and handling taps on links, emails, and phone numbers.

### How It Works

**Link Sources:**

1. **Explicit Links**: `<a href="...">` tags in HTML
2. **Auto-Detected**: URLs, emails, phone numbers (via `detect*` props)

**Processing Flow:**

```
HTML Parsing → URL Extraction → State Storage → Native Rendering → Tap Handling
```

1. **Parsing**: C++ parser extracts URLs and validates protocols
2. **State**: Link URLs stored in Fabric state indexed by fragment position
3. **Rendering**: Links rendered with underline style
4. **Interaction**: Native touch handling invokes `onLinkPress(url, type)`

**DetectedContentType:**

```typescript
type DetectedContentType = 'link' | 'email' | 'phone';
```

### Key Files

| File | Purpose |
|------|---------|
| `cpp/parsing/MarkupSegmentParser.cpp` | URL extraction during parsing |
| `ios/FabricRichCoreTextView.m` | iOS tap handling |
| `android/.../LinkDetectionManager.kt` | Android link detection |
| `android/.../FabricRichTextView.kt` | Android tap handling |

---

## 10. Accessibility Implementation

### What It Is

Full accessibility support for VoiceOver (iOS), TalkBack (Android), and screen readers (web).

### How It Works

**Accessibility Label Generation:**

The C++ parser generates accessibility-friendly labels:
- List items separated by pauses
- Links announced with position ("Link 1 of 3")
- Headings announced with level

**Link Focus Events:**

```typescript
interface LinkFocusEvent {
  focusedLinkIndex: number | null;  // -1 = container, 0+ = link index
  url: string | null;
  type: LinkFocusType | null;       // 'link' | 'email' | 'phone' | 'detected'
  totalLinks: number;
}
```

**Platform Support:**

| Platform | Implementation |
|----------|----------------|
| iOS | `FabricRichLinkAccessibilityElement` for link navigation |
| Android | `FabricRichTextAccessibilityDelegate` with ExploreByTouch |
| Web | `aria-describedby` with hidden "Link X of Y" descriptions |

### Key Files

| File | Purpose |
|------|---------|
| `ios/FabricRichLinkAccessibilityElement.m` | iOS link accessibility |
| `android/.../TextAccessibilityHelper.kt` | Android accessibility calculations |
| `android/.../FabricRichTextAccessibilityDelegate.kt` | Android delegate |
| `src/components/RichText.web.tsx` | Web ARIA attributes |

---

## 11. NativeWind Integration

### What It Is

Optional integration with NativeWind (Tailwind CSS for React Native) that enables `className`-based styling.

### How It Works

**Pre-configured Export:**

```typescript
// src/nativewind.ts
import { cssInterop } from 'nativewind';
import { RichText as BaseRichText, FabricRichText } from './index';

cssInterop(BaseRichText, { className: 'style' });
cssInterop(FabricRichText, { className: 'style' });

export { BaseRichText as RichText, FabricRichText };
```

**Usage:**

```tsx
import { RichText } from 'react-native-fabric-rich-text/nativewind';

<RichText
  text="<p>Hello World</p>"
  className="text-lg text-blue-500 p-4"
/>
```

**Build-Time Processing:**

1. Babel plugin processes JSX with className
2. Metro transformer processes CSS with Tailwind
3. `cssInterop` maps className to style object at runtime
4. Style object passed to native component

### Key Files

| File | Purpose |
|------|---------|
| `src/nativewind.ts` | Pre-configured NativeWind exports |
| `docs/nativewind-setup.md` | Configuration guide |

---

## 12. Security Model

### What It Is

A defense-in-depth security architecture that prevents XSS and other injection attacks at multiple layers.

### Security Layers

**Layer 1: Platform-Specific Sanitization**

| Platform | Library | Configuration |
|----------|---------|---------------|
| iOS | SwiftSoup | `Whitelist.none()` + explicit allowlist |
| Android | OWASP Java HTML Sanitizer | `HtmlPolicyBuilder` with allowlist |
| Web | DOMPurify | Custom config matching native allowlists |

**Layer 2: Allowlist Configuration**

All platforms use the same allowlist (from `constants.ts`):

```typescript
ALLOWED_TAGS = ['p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
                'strong', 'b', 'em', 'i', 'u', 's', 'del',
                'a', 'ul', 'ol', 'li', 'br', 'span',
                'blockquote', 'pre', 'bdi', 'bdo']
ALLOWED_ATTRIBUTES = ['href', 'class', 'dir']
ALLOWED_PROTOCOLS = ['http', 'https', 'mailto', 'tel']
```

**Layer 3: URL Validation (Defense in Depth)**

URLs are validated at multiple points:

```cpp
// C++ Parser - blocks dangerous schemes
bool isAllowedUrlScheme(const std::string& url) {
  // Block javascript:, data:, vbscript:
  return startsWithAllowedProtocol(url);
}
```

**Layer 4: No Script Execution**

The rendered output is styled text only:
- iOS: `NSAttributedString` rendered via CoreText
- Android: `Spannable` rendered via StaticLayout
- Web: `dangerouslySetInnerHTML` with sanitized content

None of these can execute JavaScript.

**Blocked Attack Vectors:**

| Attack | Prevention |
|--------|------------|
| `<script>alert(1)</script>` | Tag not in allowlist |
| `<img onerror="alert(1)">` | Tag not allowed, events stripped |
| `<a href="javascript:...">` | Protocol not allowed |
| `<a href="data:text/html,...">` | Protocol not allowed |
| `<div style="...">` | `style` attribute not allowed |
| `<style>...</style>` | Tag not in allowlist |

### Key Files

| File | Purpose |
|------|---------|
| `src/core/constants.ts` | Single source of truth for allowlists |
| `ios/FabricRichSanitizer.swift` | SwiftSoup configuration |
| `android/.../FabricRichSanitizer.kt` | OWASP configuration |
| `src/core/sanitize.web.ts` | DOMPurify configuration |

---

## Summary

The `react-native-fabric-rich-text` library provides:

1. **Fabric-First Architecture**: Synchronous measurement, no bridge overhead
2. **Shared C++ Parsing**: Identical behavior on iOS and Android
3. **Defense-in-Depth Security**: Multiple validation layers prevent XSS
4. **Full Platform Support**: iOS, Android, React Native Web, Next.js SSR
5. **Accessibility**: VoiceOver, TalkBack, and ARIA support
6. **Modern Tooling**: NativeWind/Tailwind CSS integration
7. **Rich Features**: Truncation, animations, link detection, RTL support
