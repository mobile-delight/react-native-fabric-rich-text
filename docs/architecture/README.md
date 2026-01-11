# FabricRichText Architecture

This document describes the architecture of `react-native-fabric-rich-text`, a React Native Fabric component for rendering HTML as styled native text across iOS, Android, and Web platforms.

> For comprehensive technical details on each subsystem, see [SYSTEM-SPECIFICATION.md](./SYSTEM-SPECIFICATION.md).

## Architecture Overview

The library is built on React Native's Fabric architecture with five main layers:

1. **JavaScript Layer** - React component API and TypeScript types
2. **C++ Shared Layer** - Cross-platform HTML parsing and measurement
3. **iOS Native Layer** - Swift/Objective-C rendering with CoreText
4. **Android Native Layer** - Kotlin rendering with StaticLayout/Spannable
5. **Web Layer** - SSR-compatible rendering with DOMPurify

![Architecture Overview](./architecture-overview.svg)

### Key Design Principles

| Principle | Description |
|-----------|-------------|
| **Single Parse** | HTML is parsed once in C++ and the result is shared via Fabric state |
| **Measurement/Rendering Alignment** | The same `AttributedString` is used for both measurement and rendering |
| **Security First** | HTML is sanitized using industry-standard libraries (SwiftSoup, OWASP, DOMPurify) |
| **Cross-Platform Consistency** | Shared C++ parser ensures identical parsing on iOS and Android |
| **Web Compatibility** | Same API works on React Native Web and Next.js with SSR support |

## Diagram Index

| Diagram | Description |
|---------|-------------|
| [architecture-overview.svg](./architecture-overview.svg) | High-level system architecture showing all platforms |
| [component-interaction.svg](./component-interaction.svg) | Sequence diagram of component lifecycle phases |
| [data-flow.svg](./data-flow.svg) | Data transformation from HTML input to rendered pixels |
| [file-structure.svg](./file-structure.svg) | Codebase organization by layer |
| [native-bridge.svg](./native-bridge.svg) | Fabric state transfer mechanisms |
| [security-architecture.svg](./security-architecture.svg) | XSS prevention and defense-in-depth layers |
| [truncation-system.svg](./truncation-system.svg) | numberOfLines implementation across platforms |
| [web-architecture.svg](./web-architecture.svg) | Web/Next.js SSR implementation |
| [nativewind-integration.svg](./nativewind-integration.svg) | Tailwind CSS styling integration flow |

## Component Lifecycle

![Component Interaction](./component-interaction.svg)

### Lifecycle Phases

1. **Props Phase**: JavaScript passes `text` and styling props to the native component
2. **Layout Phase**: C++ ShadowNode measures content using `TextLayoutManager`
3. **Commit Phase**: Parsed `AttributedString` is passed to view via Fabric state
4. **Mount Phase**: Platform view converts fragments to native text and renders

## Data Flow

![Data Flow](./data-flow.svg)

### Transformation Pipeline

| Stage | Input | Output | Location |
|-------|-------|--------|----------|
| 1. Component | HTML string + style | Props object | `src/components/RichText.tsx` |
| 2. Adapter | Props | Native props | `src/adapters/native.tsx` |
| 3. Sanitize | Raw HTML | Safe HTML | Platform-specific sanitizers |
| 4. Parse | Safe markup | Text segments | `cpp/parsing/MarkupSegmentParser.cpp` |
| 5. Build | Segments | `AttributedString` | `cpp/parsing/AttributedStringBuilder.cpp` |
| 6. Measure | `AttributedString` | Size | `TextLayoutManager` |
| 7. State | `AttributedString` + URLs | State data | Platform ShadowNode |
| 8. Convert | State data | Platform text | `FabricRichFragmentParser` |
| 9. Render | Platform text | Pixels | CoreText / StaticLayout / DOM |

## Fabric Shadow Tree

One of the key challenges in rendering HTML in React Native is that the content size is **dynamic and unknown at layout time**. The Fabric architecture solves this through the **Shadow Tree**.

### Shadow Tree Architecture

```
React Tree (JS)          Shadow Tree (C++)           Native Views
+--------------+         +------------------+         +--------------+
|  <RichText>  | ------> | FabricRichText   | ------> | UIView /     |
|   text="..." |         |   ShadowNode     |         | Android View |
+--------------+         +------------------+         +--------------+
```

### Custom Measurement

The `FabricRichTextShadowNode` implements `measureContent()` which Yoga calls during layout:

```cpp
Size FabricRichTextShadowNode::measureContent(
    const LayoutContext& layoutContext,
    const LayoutConstraints& layoutConstraints) const {

  // 1. Parse HTML to AttributedString
  auto parseResult = parseMarkupWithLinkUrls(props.text, fontSizeMultiplier);

  // 2. Use TextLayoutManager to measure
  auto measuredSize = textLayoutManager->measure(
      AttributedStringBox{parseResult.attributedString},
      paragraphAttributes,
      layoutConstraints);

  return measuredSize.size;
}
```

## Native Bridge

![Native Bridge](./native-bridge.svg)

### State Transfer

After measurement, the parsed `AttributedString` is stored in Fabric State:

- **iOS**: Direct C++ state passed to Objective-C++ view
- **Android**: State serialized to `MapBuffer` (binary format), deserialized in Kotlin

## Security Architecture

![Security Architecture](./security-architecture.svg)

### Defense in Depth

| Layer | Description |
|-------|-------------|
| **Platform Sanitization** | SwiftSoup (iOS), OWASP (Android), DOMPurify (Web) |
| **Allowlist Filtering** | Only allowed tags, attributes, and protocols pass through |
| **C++ URL Validation** | Blocks `javascript:`, `data:`, `vbscript:` protocols |
| **Native URL Validation** | Additional validation at render time |
| **Output Format** | Styled text only - no JavaScript execution possible |

### Allowed Content

| Category | Values |
|----------|--------|
| **Tags** | `p`, `div`, `h1`-`h6`, `strong`, `b`, `em`, `i`, `u`, `s`, `del`, `span`, `br`, `a`, `ul`, `ol`, `li`, `blockquote`, `pre`, `bdi`, `bdo` |
| **Attributes** | `href`, `class`, `dir` |
| **Protocols** | `http`, `https`, `mailto`, `tel` |

## File Structure

![File Structure](./file-structure.svg)

### Key Files by Layer

#### JavaScript Layer (`src/`)

| File | Purpose |
|------|---------|
| `index.tsx` | Native platform exports |
| `index.web.tsx` | Web platform exports |
| `nativewind.ts` | NativeWind-compatible exports with `cssInterop` |
| `FabricRichTextNativeComponent.ts` | Codegen native component spec |
| `components/RichText.tsx` | Main React component |
| `components/RichText.web.tsx` | Web React component |
| `adapters/native.tsx` | Native platform adapter |
| `adapters/web/StyleConverter.ts` | TextStyle to CSS conversion |
| `core/constants.ts` | Single source of truth for allowed HTML |
| `types/RichTextNativeProps.ts` | TypeScript type definitions |

#### C++ Shared Layer (`cpp/`)

| File | Purpose |
|------|---------|
| `FabricMarkupParser.cpp` | Main parser interface |
| `parsing/MarkupSegmentParser.cpp` | HTML to text segments |
| `parsing/AttributedStringBuilder.cpp` | Segments to AttributedString |
| `parsing/StyleParser.cpp` | Tag style parsing |
| `parsing/DirectionContext.cpp` | RTL/BiDi text support |
| `parsing/TextNormalizer.cpp` | Whitespace normalization |

#### iOS Native Layer (`ios/`)

| File | Purpose |
|------|---------|
| `FabricRichText.mm` | Fabric component view |
| `FabricRichTextShadowNode.mm` | Measurement and state management |
| `FabricRichCoreTextView.m` | CoreText-based rendering |
| `FabricRichFragmentParser.mm` | C++ to NSAttributedString conversion |
| `FabricRichSanitizer.swift` | SwiftSoup HTML sanitizer |

#### Android Native Layer (`android/`)

**React Layer (`src/main/react/`)**

| File | Purpose |
|------|---------|
| `FabricHTMLTextViewManager.kt` | React Native view manager |
| `FabricHTMLFragmentParser.kt` | MapBuffer to Spannable conversion |
| `FabricHTMLLayoutManager.kt` | Layout management |

**Java Layer (`src/main/java/`)**

| File | Purpose |
|------|---------|
| `FabricRichTextView.kt` | Custom TextView with state-based rendering |
| `FabricRichSpannableBuilder.kt` | Spannable construction |
| `FabricRichSanitizer.kt` | OWASP HTML sanitizer |
| `TextTruncationEngine.kt` | Word-boundary truncation |
| `LinkDetectionManager.kt` | URL/email/phone detection |
| `TextAccessibilityHelper.kt` | Accessibility calculations |
| `HeightAnimationController.kt` | Height animation |

**JNI Layer (`src/main/jni/`)**

| File | Purpose |
|------|---------|
| `ShadowNodes.cpp` | C++ shadow node with measurement |
| `FabricRichTextState.cpp` | State serialization to MapBuffer |

## Truncation System

![Truncation System](./truncation-system.svg)

The `numberOfLines` prop is implemented across all platforms:

| Platform | Implementation |
|----------|----------------|
| **C++** | `ParagraphAttributes.maximumNumberOfLines` for constrained measurement |
| **iOS** | `CTLineCreateTruncatedLine` with ellipsis |
| **Android** | `StaticLayout.Builder.setMaxLines()` with `TruncateAt.END` |
| **Web** | CSS `-webkit-line-clamp` |

Height animation via `animationDuration` prop uses ease-in-out timing.

## Web Architecture

![Web Architecture](./web-architecture.svg)

### SSR-Compatible Dual Sanitizer

| Environment | Sanitizer |
|-------------|-----------|
| Browser | DOMPurify (client-side) |
| Node.js/SSR | sanitize-html (lazy loaded) |

### Web Features

- **Style Conversion**: React Native `TextStyle` to CSS
- **Semantic HTML**: Uses `dangerouslySetInnerHTML` with sanitized content
- **Accessibility**: `aria-describedby` for "Link X of Y" screen reader support
- **Truncation**: CSS `line-clamp` for `numberOfLines`

## NativeWind Integration

![NativeWind Integration](./nativewind-integration.svg)

Import from the `/nativewind` subpath for zero-config Tailwind CSS support:

```tsx
import { RichText } from 'react-native-fabric-rich-text/nativewind';

<RichText
  text="<p>Hello <strong>World</strong></p>"
  className="text-blue-500 text-lg p-4"
/>
```

The `cssInterop` function maps `className` to `style` at build time with zero runtime overhead.

## Core Concepts

### AttributedString

React Native's cross-platform representation of styled text:

- **Fragments**: Runs of text with consistent styling
- **TextAttributes**: Font size, weight, style, color, decorations
- **ParagraphAttributes**: Maximum lines, text alignment, writing direction

### Fragment-Based Rendering

1. HTML is parsed to `AttributedString` in C++ during measurement
2. `AttributedString` is stored in Fabric state
3. Native view receives state on commit
4. View converts fragments to platform text (NSAttributedString/Spannable)

This eliminates measurement/rendering misalignment.

### Link Handling

1. **Parsing**: `<a href="...">` tags extracted, URLs validated
2. **State**: Link URLs stored alongside fragments
3. **Rendering**: Links rendered with underline and blue color
4. **Interaction**: Taps trigger `onLinkPress(url, type)` callback
5. **Detection**: Optional auto-detection of URLs, emails, phone numbers

## Performance

| Optimization | Benefit |
|--------------|---------|
| **Fabric Sync Layer** | No async bridge overhead |
| **Single Parse** | HTML parsed once, cached in state |
| **Native Rendering** | CoreText (iOS), StaticLayout (Android) |
| **Lazy Sanitization** | Only when HTML changes |
| **MapBuffer** | Efficient binary serialization (Android) |
| **NativeWind** | Build-time style compilation |

## Further Reading

- [SYSTEM-SPECIFICATION.md](./SYSTEM-SPECIFICATION.md) - Comprehensive technical reference
- [../nativewind-setup.md](../nativewind-setup.md) - NativeWind configuration guide
- [../web-integration.md](../web-integration.md) - Web/Next.js integration guide
