# FabricHTMLText System Specification

A comprehensive technical reference for the `react-native-fabric-html-text` library - a cross-platform HTML text rendering solution for React Native Fabric, React Native Web, and Next.js.

---

## Table of Contents

1. [Core HTMLText Component](#1-core-htmltext-component)
2. [HTML Parsing & Sanitization](#2-html-parsing--sanitization)
3. [Fabric/TurboModule Architecture](#3-fabricturbomodule-architecture)
4. [C++ Shared Layer](#4-c-shared-layer)
5. [iOS Native Rendering](#5-ios-native-rendering)
6. [Android Native Rendering](#6-android-native-rendering)
7. [Web Implementation](#7-web-implementation)
8. [NativeWind Integration](#8-nativewind-integration)
9. [Text Truncation System](#9-text-truncation-system)
10. [Security Model](#10-security-model)

---

## 1. Core HTMLText Component

### What It Is

The `HTMLText` component is the public API for rendering sanitized HTML content as styled native text. It provides a React component interface that works identically across iOS, Android, and Web platforms.

### Why We Need It

React Native lacks built-in HTML rendering support. Existing solutions either:
- Use WebViews (slow, inconsistent sizing, security concerns)
- Implement custom JS parsers (don't integrate with native text systems)
- Require bridge crossing for measurement (async, causes layout jumps)

HTMLText solves this by providing a true native text component that:
- Renders HTML as native `Text` (not a WebView)
- Measures synchronously in the Fabric Shadow Tree
- Integrates with accessibility, fonts, and theming systems

### How It Works

```tsx
import { HTMLText } from 'react-native-fabric-html-text';

<HTMLText
  html="<p>Hello <strong>World</strong></p>"
  style={{ fontSize: 16, color: '#333' }}
  numberOfLines={3}
  onLinkPress={({ url, type }) => Linking.openURL(url)}
/>
```

The component:
1. Accepts HTML string and React Native TextStyle props
2. Routes to platform-specific adapters (native vs web)
3. Passes props through Fabric's codegen-generated native component spec
4. Renders as native styled text with full accessibility support

### Why This Approach

- **Fabric-First**: Built for React Native's New Architecture from the ground up
- **Type-Safe**: Full TypeScript support with codegen-generated specs
- **Unified API**: Same component works across all platforms
- **Declarative**: Standard React patterns, no imperative APIs

### Key Files

| File | Purpose |
|------|---------|
| `/src/components/HTMLText.tsx` | Main React component implementation |
| `/src/components/HTMLText.web.tsx` | Web-specific implementation |
| `/src/index.tsx` | Public API exports for native |
| `/src/index.web.tsx` | Public API exports for web |
| `/src/FabricHTMLTextNativeComponent.ts` | Codegen native component specification |
| `/src/types/HTMLTextNativeProps.ts` | TypeScript type definitions |

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
| iOS | SwiftSoup | `/ios/FabricHTMLSanitizer.swift` |
| Android | OWASP Java HTML Sanitizer | `/android/src/main/java/.../FabricHTMLSanitizer.kt` |
| Web | DOMPurify 3.3.1 | `/src/core/sanitize.web.ts` |

**Processing Pipeline:**

```
Raw HTML → Whitespace Normalization → Allowlist Sanitization → C++ Parsing → AttributedString
```

1. **Whitespace Normalization**: Remove inter-tag whitespace from JSX formatting
2. **Allowlist Sanitization**: Only allowed tags/attributes pass through
3. **C++ Parsing**: `FabricHTMLParser` converts to React Native's `AttributedString`
4. **Platform Rendering**: Convert to NSAttributedString (iOS) or Spannable (Android)

**Allowed Content (defined in `/src/core/constants.ts`):**

```typescript
ALLOWED_TAGS = ['p', 'div', 'h1-h6', 'strong', 'b', 'em', 'i', 'u', 's', 'del',
                'span', 'br', 'a', 'blockquote', 'pre', 'ul', 'ol', 'li']
ALLOWED_ATTRIBUTES = ['href', 'class']
ALLOWED_PROTOCOLS = ['http', 'https', 'mailto', 'tel']
```

### Why This Approach

- **Defense in Depth**: Multiple validation layers prevent XSS
- **Industry-Standard Libraries**: SwiftSoup, OWASP, and DOMPurify are battle-tested
- **Single Source of Truth**: Allowlist defined once in TypeScript, codegen'd to native
- **Native Sanitization**: Runs in native code for performance, not JS

### Key Files

| File | Purpose |
|------|---------|
| `/src/core/constants.ts` | Single source of truth for allowed tags/protocols |
| `/src/core/sanitize.ts` | Native pass-through (sanitization in native layer) |
| `/src/core/sanitize.web.ts` | DOMPurify-based web sanitization |
| `/ios/FabricHTMLSanitizer.swift` | SwiftSoup iOS sanitizer |
| `/android/.../FabricHTMLSanitizer.kt` | OWASP Android sanitizer |
| `/ios/FabricGeneratedConstants.swift` | Generated constants for iOS |
| `/android/.../FabricGeneratedConstants.kt` | Generated constants for Android |

---

## 3. Fabric/TurboModule Architecture

### What It Is

The integration layer between React and native platforms using React Native's Fabric renderer and TurboModules architecture (the "New Architecture").

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
2. **Layout Phase**: `FabricHTMLTextShadowNode::measureContent()` parses HTML and measures
3. **Commit Phase**: `layout()` calls `setStateData()` with parsed `AttributedString`
4. **Mount Phase**: Native view receives state and renders

**Codegen Specification:**

```typescript
// FabricHTMLTextNativeComponent.ts
export interface NativeProps extends ViewProps {
  html: string;
  fontSize?: Float;
  color?: ColorValue;
  numberOfLines?: Int32;
  onLinkPress?: DirectEventHandler<{ url: string; type: string }>;
  // ... more props
}

export default codegenNativeComponent<NativeProps>('FabricHTMLText');
```

This generates:
- C++ `FabricHTMLTextProps` struct
- C++ `FabricHTMLTextEventEmitter` for callbacks
- Swift/Kotlin view protocol/interface

### Why This Approach

- **Zero Bridge Overhead**: JSI enables direct C++ communication
- **Synchronous Measurement**: No layout jumps with dynamic content
- **Type Safety**: Codegen catches mismatches at build time
- **Single Parse**: HTML parsed once in C++, shared via state

### Key Files

| File | Purpose |
|------|---------|
| `/src/FabricHTMLTextNativeComponent.ts` | Codegen component specification |
| `/ios/FabricHTMLTextShadowNode.mm` | iOS shadow node with measureContent |
| `/ios/FabricHTMLTextComponentDescriptor.h` | Fabric component descriptor |
| `/android/.../jni/.../ShadowNodes.cpp` | Android shadow node with measureContent |
| `/android/.../jni/.../FabricHTMLTextState.cpp` | State serialization to MapBuffer |

---

## 4. C++ Shared Layer

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

### How It Works

**FabricHTMLParser Interface:**

```cpp
// FabricHTMLParser.h
class FabricHTMLParser {
public:
  static std::string stripHtmlTags(const std::string& html);

  static ParseResult parseHtmlWithLinkUrls(
    const std::string& html,
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
    const std::string& tagStylesJson
  );
};

struct ParseResult {
  AttributedString attributedString;
  std::vector<std::string> linkUrls;
};
```

**Parsing Process:**

1. Tokenize HTML into tags and text
2. Maintain style stack for nested elements
3. Apply tag-specific styles (headings, bold, italic, links)
4. Build `AttributedString` with `TextFragment` objects
5. Extract link URLs for tap handling

**AttributedString Structure:**

```cpp
// React Native's AttributedString
struct AttributedString {
  std::vector<Fragment> fragments;

  struct Fragment {
    std::string string;
    TextAttributes textAttributes;  // fontSize, fontWeight, color, etc.
  };
};
```

### Why This Approach

- **Cross-Platform Consistency**: Same code runs on iOS and Android
- **React Native Integration**: Uses RN's native `AttributedString` format
- **Performance**: C++ parsing is faster than JS
- **TextLayoutManager Compatible**: Output plugs directly into RN's text measurement

### Key Files

| File | Purpose |
|------|---------|
| `/cpp/FabricHTMLParser.h` | Parser interface and types |
| `/cpp/FabricHTMLParser.cpp` | HTML parsing implementation |

---

## 5. iOS Native Rendering

### What It Is

The iOS-specific rendering layer that converts C++ `AttributedString` to `NSAttributedString` and renders using CoreText.

### Why We Need It

iOS requires:
- Native `NSAttributedString` for text rendering
- CoreText `CTFrameDraw` for precise text layout
- UIKit gesture handling for link taps
- Integration with iOS accessibility

### How It Works

**Rendering Pipeline:**

```
C++ AttributedString → FabricHTMLFragmentParser → NSAttributedString → CoreText
                                                         ↓
                                              FabricHTMLCoreTextView
                                                         ↓
                                                   CTFrameDraw
```

**Component Structure:**

```objc
// FabricHTMLText.mm - Fabric Component View
@implementation FabricHTMLText
- (void)updateState:(const State::Shared&)state {
  // Convert C++ fragments to NSAttributedString
  NSAttributedString *nsAttrString = [FabricHTMLFragmentParser
    buildAttributedStringFromCppAttributedString:stateData.attributedString
    withLinkUrls:stateData.linkUrls];

  _coreTextView.attributedText = nsAttrString;
}
@end
```

**CoreText Rendering:**

```objc
// FabricHTMLCoreTextView.m
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

### Why This Approach

- **CoreText Performance**: Lower-level than UILabel, more control
- **Fragment-Based**: Avoids re-parsing HTML in view layer
- **State-Driven**: Leverages Fabric's state management
- **Native Feel**: Uses iOS-standard text rendering

### Key Files

| File | Purpose |
|------|---------|
| `/ios/FabricHTMLText.mm` | Fabric component view |
| `/ios/FabricHTMLTextShadowNode.mm` | Shadow node with measurement |
| `/ios/FabricHTMLFragmentParser.mm` | C++ to NSAttributedString conversion |
| `/ios/FabricHTMLCoreTextView.m` | CoreText-based rendering view |
| `/ios/FabricHTMLSanitizer.swift` | SwiftSoup HTML sanitizer |

---

## 6. Android Native Rendering

### What It Is

The Android-specific rendering layer that converts C++ state (via MapBuffer) to Spannable and renders using custom StaticLayout.

### Why We Need It

Android requires:
- `Spannable` with style spans for rich text
- `StaticLayout` for text measurement and rendering
- Custom drawing to match C++ measurement exactly
- JNI bridge for C++ to Kotlin state transfer

### How It Works

**State Transfer via MapBuffer:**

```cpp
// FabricHTMLTextState.cpp
MapBuffer FabricHTMLTextState::getMapBuffer() const {
  auto builder = MapBufferBuilder();
  builder.putMapBuffer(HTML_STATE_KEY_ATTRIBUTED_STRING,
                       toMapBuffer(attributedString));
  builder.putMapBuffer(HTML_STATE_KEY_LINK_URLS, linkUrlsBuffer);
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

**Custom Layout Creation:**

```kotlin
// FabricHTMLTextView.kt
private fun createCustomLayout(text: Spannable, availableWidth: Int): Layout {
  // Must match TextLayoutManager.createLayout() parameters exactly
  return StaticLayout.Builder.obtain(text, 0, text.length, customTextPaint, layoutWidth)
    .setAlignment(alignment)
    .setLineSpacing(0f, 1f)  // CRITICAL: Must match measurement
    .setMaxLines(numberOfLines)
    .setEllipsize(TextUtils.TruncateAt.END)
    .build()
}
```

### Why This Approach

- **MapBuffer Efficiency**: Binary serialization is faster than JSON
- **Measurement Alignment**: Custom StaticLayout matches TextLayoutManager exactly
- **State-Based**: No duplicate HTML parsing in view layer
- **Direct Draw**: Bypasses AppCompatTextView for precise control

### Key Files

| File | Purpose |
|------|---------|
| `/android/.../jni/.../ShadowNodes.cpp` | Shadow node with measureContent |
| `/android/.../jni/.../FabricHTMLTextState.cpp` | MapBuffer serialization |
| `/android/.../react/.../FabricHTMLFragmentParser.kt` | MapBuffer to Spannable |
| `/android/.../java/.../FabricHTMLTextView.kt` | Custom rendering view |
| `/android/.../java/.../FabricHTMLSanitizer.kt` | OWASP HTML sanitizer |
| `/android/.../react/.../FabricHTMLTextViewManager.kt` | React Native view manager |

---

## 7. Web Implementation

### What It Is

A Next.js/SSR-compatible web implementation that renders sanitized HTML using native browser capabilities.

### Why We Need It

For universal React Native apps (via React Native Web or shared codebases), we need:
- Web-compatible HTMLText component
- SSR support for Next.js
- Same API as native implementation
- Consistent security model

### How It Works

**Platform Resolution:**

```json
// package.json exports
{
  "exports": {
    ".": {
      "react-native": "./lib/index.js",
      "default": "./lib/index.web.js"
    }
  }
}
```

**Web Component:**

```tsx
// HTMLText.web.tsx
export const HTMLText: React.FC<HTMLTextProps> = ({
  html,
  style,
  numberOfLines,
  onLinkPress,
}) => {
  // Sanitize with DOMPurify (SSR-compatible)
  const sanitizedHtml = useMemo(() => sanitize(html), [html]);

  // Convert RN style to CSS
  const cssStyle = useMemo(() => convertStyle(style), [style]);

  // Apply line clamp for truncation
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
    />
  );
};
```

**Style Conversion:**

```typescript
// StyleConverter.ts
export function convertStyle(style?: TextStyle): CSSProperties {
  return {
    fontSize: style?.fontSize ? `${style.fontSize}px` : undefined,
    fontWeight: style?.fontWeight,
    color: style?.color,
    lineHeight: style?.lineHeight ? `${style.lineHeight}px` : undefined,
    // ... more conversions
  };
}
```

### Why This Approach

- **Native Browser Rendering**: Uses browser's HTML/CSS engine
- **SSR Compatible**: DOMPurify works in Node.js
- **Same API**: Identical props as native component
- **CSS Truncation**: Uses `-webkit-line-clamp` for numberOfLines

### Key Files

| File | Purpose |
|------|---------|
| `/src/index.web.tsx` | Web-specific exports |
| `/src/components/HTMLText.web.tsx` | Web component implementation |
| `/src/core/sanitize.web.ts` | DOMPurify sanitization |
| `/src/adapters/web/StyleConverter.ts` | RN TextStyle to CSS conversion |
| `/example-web/` | Next.js demo application |

---

## 8. NativeWind Integration

### What It Is

Optional integration with NativeWind (Tailwind CSS for React Native) that enables `className`-based styling.

### Why We Need It

Many React Native apps use NativeWind for:
- Familiar Tailwind CSS syntax
- Utility-first styling approach
- Consistent styling with web codebases

HTMLText should work seamlessly in NativeWind projects.

### How It Works

**Pre-configured Export:**

```typescript
// src/nativewind.ts
import { cssInterop } from 'nativewind';
import { HTMLText as BaseHTMLText } from './index';

// Apply cssInterop to map className to style
cssInterop(BaseHTMLText, { className: 'style' });

export { BaseHTMLText as HTMLText };
```

**Usage:**

```tsx
import { HTMLText } from 'react-native-fabric-html-text/nativewind';

<HTMLText
  html="<p>Hello World</p>"
  className="text-lg text-blue-500 p-4"
/>
```

**Build-Time Processing:**

1. Babel plugin processes JSX with className
2. Metro plugin processes CSS with Tailwind
3. Runtime `cssInterop` maps className to style object
4. Style object passed to native component

### Why This Approach

- **Zero Config for Users**: Import from `/nativewind` subpath
- **Build-Time Performance**: Styles compiled, not interpreted at runtime
- **Standard NativeWind**: Uses official `cssInterop` API
- **Optional**: Regular import still works without NativeWind

### Key Files

| File | Purpose |
|------|---------|
| `/src/nativewind.ts` | Pre-configured NativeWind exports |
| `/docs/nativewind-setup.md` | Configuration guide |

---

## 9. Text Truncation System

### What It Is

A cross-platform text truncation feature that limits displayed lines and adds ellipsis, with optional animated height transitions.

### Why We Need It

Long HTML content often needs truncation for:
- "Read more" UI patterns
- Card previews with limited space
- Consistent layout regardless of content length

### How It Works

**Props:**

```tsx
<HTMLText
  html={longContent}
  numberOfLines={3}        // 0 = unlimited
  animationDuration={0.2}  // Height animation in seconds
/>
```

**C++ Measurement (applies to both platforms):**

```cpp
// ShadowNode measureContent()
auto paragraphAttributes = ParagraphAttributes{};
paragraphAttributes.maximumNumberOfLines = numberOfLines;
paragraphAttributes.ellipsizeMode = EllipsizeMode::Tail;

auto measuredSize = textLayoutManager->measure(
  AttributedStringBox{attributedString},
  paragraphAttributes,  // Line limit applied here
  textLayoutContext,
  layoutConstraints
);
```

**iOS Rendering:**

```objc
// FabricHTMLCoreTextView.m
- (void)drawTruncatedFrame:(CTFrameRef)frame maxLines:(NSInteger)maxLines {
  // Get all lines, draw all but last
  for (i = 0; i < lineCount - 1; i++) {
    CTLineDraw(line, context);
  }

  // Truncate last line with ellipsis
  CTLineRef truncatedLine = CTLineCreateTruncatedLine(
    continuousLine, availableWidth, kCTLineTruncationEnd, ellipsisLine);
  CTLineDraw(truncatedLine, context);
}
```

**Android Rendering:**

```kotlin
// FabricHTMLTextView.kt
val builder = StaticLayout.Builder.obtain(text, 0, text.length, paint, width)
  .setMaxLines(numberOfLines)
  .setEllipsize(TextUtils.TruncateAt.END)
  .build()
```

**Web Rendering:**

```css
/* Applied via inline style */
display: -webkit-box;
-webkit-line-clamp: 3;
-webkit-box-orient: vertical;
overflow: hidden;
```

**Height Animation:**

Both iOS and Android animate height changes when `animationDuration > 0`:

- iOS: `UIView.animateWithDuration`
- Android: `ValueAnimator` with `AccelerateDecelerateInterpolator`

### Why This Approach

- **Native Truncation**: Each platform uses its native ellipsis handling
- **Measurement-Aware**: Constrained height calculated in C++ shadow node
- **Smooth Transitions**: Native animations for expand/collapse
- **Accessibility**: Full text available to screen readers

### Key Files

| File | Purpose |
|------|---------|
| `/ios/FabricHTMLCoreTextView.m` | `drawTruncatedFrame:` implementation |
| `/android/.../FabricHTMLTextView.kt` | StaticLayout with maxLines |
| `/src/components/HTMLText.web.tsx` | CSS line-clamp |

---

## 10. Security Model

### What It Is

A defense-in-depth security architecture that prevents XSS and other injection attacks at multiple layers.

### Why We Need It

HTML rendering is a primary XSS attack vector. Without proper sanitization:
- `<script>` tags could execute arbitrary code
- Event handlers (`onclick`) could trigger malicious actions
- `javascript:` URLs could execute code on click
- Style injection could enable UI redressing attacks

### How It Works

**Layer 1: Platform-Specific Sanitization**

| Platform | Library | Configuration |
|----------|---------|---------------|
| iOS | SwiftSoup | `Whitelist.none()` + explicit allowlist |
| Android | OWASP Java HTML Sanitizer | `HtmlPolicyBuilder` with allowlist |
| Web | DOMPurify | Custom config matching native allowlists |

**Layer 2: Allowlist Configuration**

All platforms use the same allowlist (generated from `constants.ts`):

```typescript
// Only these pass through
ALLOWED_TAGS = ['p', 'h1-h6', 'strong', 'b', 'em', 'i', 'u', 's',
                'a', 'ul', 'ol', 'li', 'br', 'span', 'div', 'blockquote', 'pre', 'del']
ALLOWED_ATTRIBUTES = ['href', 'class']  // No 'id', 'style', 'onclick', etc.
ALLOWED_PROTOCOLS = ['http', 'https', 'mailto', 'tel']  // No 'javascript:', 'data:'
```

**Layer 3: URL Validation (Defense in Depth)**

URLs are validated at multiple points even after sanitization:

```cpp
// C++ Parser - blocks dangerous schemes
if (scheme == "javascript" || scheme == "data" || scheme == "vbscript") {
  continue; // Skip this link
}
```

```objc
// iOS Fragment Parser
static NSSet *allowedSchemes = [NSSet setWithObjects:@"http", @"https", @"mailto", @"tel", nil];
if (![allowedSchemes containsObject:scheme]) {
  // Skip setting NSLinkAttributeName
}
```

```kotlin
// Android LinkClickMovementMethod
val allowedSchemes = setOf("http", "https", "mailto", "tel")
if (scheme !in allowedSchemes) {
  return true  // Consume event, don't invoke callback
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
| `<script>alert(1)</script>` | Tag not in allowlist, stripped |
| `<img onerror="alert(1)">` | Tag not allowed, event handlers stripped |
| `<a href="javascript:alert(1)">` | Protocol not allowed, URL blocked |
| `<a href="data:text/html,<script>...">` | Protocol not allowed |
| `<div style="...">` | `style` attribute not allowed |
| `<style>...</style>` | Tag not in allowlist |

### Why This Approach

- **Industry-Standard Libraries**: SwiftSoup, OWASP, DOMPurify are widely vetted
- **Defense in Depth**: Multiple layers catch different attack vectors
- **Allowlist, Not Blocklist**: Only known-safe content passes through
- **Consistent Cross-Platform**: Same security policy on all platforms
- **No Execution Context**: Output format cannot run scripts

### Key Files

| File | Purpose |
|------|---------|
| `/src/core/constants.ts` | Single source of truth for allowlists |
| `/ios/FabricHTMLSanitizer.swift` | SwiftSoup configuration |
| `/android/.../FabricHTMLSanitizer.kt` | OWASP configuration |
| `/src/core/sanitize.web.ts` | DOMPurify configuration |
| `/ios/FabricHTMLFragmentParser.mm` | URL scheme validation |
| `/android/.../FabricHTMLFragmentParser.kt` | URL scheme validation |
| `/ios/FabricHTMLCoreTextView.m` | Final URL validation on tap |
| `/android/.../FabricHTMLTextView.kt` | Final URL validation on tap |

---

## Architecture Diagrams

For visual reference, see the SVG diagrams in this directory:

| Diagram | Description |
|---------|-------------|
| [architecture-overview.svg](./architecture-overview.svg) | High-level system architecture showing all platforms |
| [component-interaction.svg](./component-interaction.svg) | Sequence diagram of component lifecycle |
| [data-flow.svg](./data-flow.svg) | Data transformation from HTML to pixels |
| [file-structure.svg](./file-structure.svg) | Codebase organization |
| [native-bridge.svg](./native-bridge.svg) | Fabric/TurboModule architecture detail |
| [security-architecture.svg](./security-architecture.svg) | XSS prevention layers |
| [truncation-system.svg](./truncation-system.svg) | numberOfLines implementation |
| [web-architecture.svg](./web-architecture.svg) | Web/Next.js implementation |
| [nativewind-integration.svg](./nativewind-integration.svg) | Tailwind CSS styling flow |

---

## Summary

The `react-native-fabric-html-text` library is a modern, secure, cross-platform HTML rendering solution that:

1. **Leverages Fabric Architecture**: Synchronous measurement, no bridge overhead, type-safe codegen
2. **Shares C++ Logic**: Identical parsing on iOS and Android ensures consistency
3. **Prioritizes Security**: Industry-standard sanitization libraries with defense-in-depth
4. **Supports All Platforms**: Native mobile, React Native Web, and Next.js SSR
5. **Integrates Modern Tools**: NativeWind support for Tailwind CSS styling
6. **Handles Edge Cases**: Truncation, animations, accessibility, link detection

By building on established standards (Fabric, CoreText, StaticLayout, DOMPurify) rather than reinventing solutions, the library provides reliable, maintainable, and secure HTML rendering for React Native applications.
