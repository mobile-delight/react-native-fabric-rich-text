# react-native-fabric-rich-text

Fabric-first HTML text renderer for React Native with iOS, Android, and web support.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [NativeWind Integration](#nativewind-integration)
- [RTL Support](#rtl-right-to-left-support)
- [Props](#props)
- [Events](#events)
- [Type Exports](#type-exports)
- [Error Handling](#error-handling)
- [Testing](#testing)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)

## Features

- Native Fabric component for optimal performance
- HTML parsing and rendering (bold, italic, lists, links)
- Link detection (URLs, emails, phone numbers)
- Custom tag styles via `tagStyles` prop
- XSS protection with built-in sanitization
- NativeWind/Tailwind CSS integration via `/nativewind` export
- RTL (Right-to-Left) text support with `bdi`, `bdo`, and `dir` attributes

## Installation

```sh
npm install react-native-fabric-rich-text
# or
yarn add react-native-fabric-rich-text
```

### iOS

```sh
cd ios && pod install
```

## Usage

```tsx
import { RichText } from 'react-native-fabric-rich-text';

export default function App() {
  return (
    <RichText
      text="<p>Hello <strong>world</strong></p>"
      style={{ fontSize: 16 }}
    />
  );
}
```

### With Links

```tsx
<RichText
  text='<p>Visit <a href="https://example.com">our site</a></p>'
  onLinkPress={(url, type) => {
    console.log(`Pressed ${type}: ${url}`);
  }}
/>
```

### With Custom Styles

```tsx
<RichText
  text="<p>Normal <strong>bold red</strong> and <em>italic blue</em></p>"
  tagStyles={{
    strong: { color: '#CC0000' },
    em: { color: '#0066CC' },
  }}
/>
```

### Auto-Detection

```tsx
<RichText
  text="<p>Call 555-123-4567 or email support@example.com</p>"
  detectPhoneNumbers
  detectEmails
  onLinkPress={(url, type) => {
    // type will be 'phone' or 'email'
  }}
/>
```

## NativeWind Integration

This library supports [NativeWind](https://www.nativewind.dev/) for Tailwind CSS styling in React Native.

> **Full setup guide**: See [docs/nativewind-setup.md](docs/nativewind-setup.md) for complete babel, metro, and tailwind configuration instructions.

### Installation

```sh
# Install NativeWind and Tailwind CSS (3.x required)
npm install nativewind
npm install -D tailwindcss@">=3.3.0 <4.0.0"
```

### Pre-configured Export (Recommended)

Import from the `/nativewind` subpath for zero-config Tailwind CSS support:

```tsx
import { RichText } from 'react-native-fabric-rich-text/nativewind';

function MyComponent() {
  return (
    <RichText
      text="<p>Hello <strong>World</strong></p>"
      className="text-blue-500 text-lg font-medium p-4"
    />
  );
}
```

### Responsive Variants

```tsx
<RichText
  text="<p>Responsive text</p>"
  className="text-sm md:text-base lg:text-lg"
/>
```

### Dark Mode

```tsx
<RichText
  text="<p>Theme-aware text</p>"
  className="text-gray-900 dark:text-gray-100"
/>
```

### Manual Integration

For more control, apply `cssInterop` yourself:

```tsx
import { RichText } from 'react-native-fabric-rich-text';
import { cssInterop } from 'nativewind';

// Apply once at app startup
cssInterop(RichText, { className: 'style' });

function MyComponent() {
  return (
    <RichText
      text="<p>Hello World</p>"
      className="text-blue-500"
    />
  );
}
```

### TypeScript Setup

Add NativeWind types to your project:

```typescript
// nativewind-env.d.ts
/// <reference types="nativewind/types" />
```

### Requirements

- NativeWind ^4.1.0
- Tailwind CSS 3.x

## RTL (Right-to-Left) Support

Full support for RTL languages including Arabic, Hebrew, and Persian.

### Basic RTL Text

RTL scripts are automatically detected and rendered correctly:

```tsx
<RichText text="<p>مرحباً بالعالم!</p>" />
<RichText text="<p>שלום עולם!</p>" />
```

### Direction Attribute

Use the `dir` attribute to control text direction:

```tsx
// Explicit RTL
<RichText text="<p dir='rtl'>Right-to-left paragraph</p>" />

// Explicit LTR
<RichText text="<p dir='ltr'>Left-to-right paragraph</p>" />

// Auto-detect from first strong character
<RichText text="<p dir='auto'>مرحباً - detects as RTL</p>" />
```

### writingDirection Prop

Control direction at the component level:

```tsx
// Force RTL for entire component
<RichText
  text="<p>This will render RTL</p>"
  writingDirection="rtl"
/>

// Force LTR
<RichText
  text="<p>مرحباً</p>"
  writingDirection="ltr"
/>

// Auto-detect (default)
<RichText
  text="<p>Text</p>"
  writingDirection="auto"
/>
```

### BDI Element (Bidirectional Isolation)

The `<bdi>` tag isolates bidirectional text to prevent it from affecting surrounding content. Useful for user-generated content:

```tsx
<RichText text="<p>User: <bdi>محمد</bdi> logged in</p>" />
<RichText text="<p>Winners: <bdi>אברהם</bdi>, <bdi>محمد</bdi></p>" />
```

### BDO Element (Bidirectional Override)

The `<bdo>` tag forces text direction, overriding the natural direction:

```tsx
// Force RTL
<RichText text="<p>Normal <bdo dir='rtl'>forced RTL</bdo> normal</p>" />

// Force LTR within RTL context
<RichText text="<p dir='rtl'>عربي <bdo dir='ltr'>forced LTR</bdo> عربي</p>" />
```

### Mixed Content

RTL text with embedded LTR content (numbers, brand names) is handled automatically:

```tsx
<RichText text="<p dir='rtl'>السعر: 123.45 دولار</p>" />
<RichText text="<p dir='rtl'>أنا أستخدم iPhone كل يوم</p>" />
```

### RTL with Formatting

All text formatting works with RTL:

```tsx
<RichText
  text="<p dir='rtl'><strong>مهم:</strong> نص <em>مائل</em> و<u>تحته خط</u></p>"
/>
```

### I18nManager Integration

On React Native, the component respects `I18nManager.isRTL` as the default base direction when `writingDirection="auto"` (the default).

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `text` | `string` | - | HTML markup to render (required) |
| `style` | `TextStyle` | - | Style applied to the text |
| `className` | `string` | - | Tailwind CSS classes (requires `/nativewind` import) |
| `testID` | `string` | - | Test identifier for testing frameworks |
| `tagStyles` | `Record<string, TextStyle>` | - | Custom styles per HTML tag |
| `onLinkPress` | `(url: string, type: DetectedContentType) => void` | - | Callback when a link is pressed |
| `onLinkFocusChange` | `(event: LinkFocusEvent) => void` | - | Callback when accessibility focus changes between links |
| `onRichTextMeasurement` | `(data: RichTextMeasurementData) => void` | - | Callback with line count data after layout |
| `detectLinks` | `boolean` | `false` | Auto-detect URLs in text |
| `detectPhoneNumbers` | `boolean` | `false` | Auto-detect phone numbers |
| `detectEmails` | `boolean` | `false` | Auto-detect email addresses |
| `numberOfLines` | `number` | `0` | Limit text to specified lines (0 = unlimited) |
| `animationDuration` | `number` | `0.2` | Height animation duration in seconds |
| `writingDirection` | `'auto' \| 'ltr' \| 'rtl'` | `'auto'` | Text direction |
| `allowFontScaling` | `boolean` | `true` | Enable font scaling for accessibility |
| `maxFontSizeMultiplier` | `number` | `0` | Maximum font scale (0 = unlimited) |
| `includeFontPadding` | `boolean` | `true` | Android: include font padding |

> **Note:** On iOS, enabling `detectEmails` also enables URL detection due to platform limitations.

## Events

### onLinkPress

Fired when the user taps a link, phone number, or email.

```tsx
<RichText
  text='<p>Visit <a href="https://example.com">our site</a></p>'
  onLinkPress={(url, type) => {
    // type: 'link' | 'email' | 'phone'
    console.log(`Pressed ${type}: ${url}`);
  }}
/>
```

### onLinkFocusChange

Fired when accessibility focus moves between links (screen readers, keyboard navigation).

```tsx
import type { LinkFocusEvent } from 'react-native-fabric-rich-text';

<RichText
  text='<p><a href="#1">Link 1</a> and <a href="#2">Link 2</a></p>'
  onLinkFocusChange={(event: LinkFocusEvent) => {
    // event.focusedLinkIndex: -1 (container), 0+ (link index), null (lost focus)
    // event.url: string | null
    // event.type: 'link' | 'email' | 'phone' | 'detected' | null
    // event.totalLinks: number
    console.log(`Focused link ${event.focusedLinkIndex} of ${event.totalLinks}`);
  }}
/>
```

### onRichTextMeasurement

Fired after text layout with line count information. Useful for "Read more" patterns.

```tsx
import type { RichTextMeasurementData } from 'react-native-fabric-rich-text';

const [isTruncated, setIsTruncated] = useState(false);

<RichText
  text="<p>Long text content...</p>"
  numberOfLines={2}
  onRichTextMeasurement={(data: RichTextMeasurementData) => {
    // data.measuredLineCount: total lines without truncation
    // data.visibleLineCount: lines actually displayed
    setIsTruncated(data.measuredLineCount > data.visibleLineCount);
  }}
/>
{isTruncated && <Text>Show more</Text>}
```

## Type Exports

```tsx
import {
  RichText,
  FabricRichText,
  sanitize,
  ALLOWED_TAGS,
  ALLOWED_ATTR,
} from 'react-native-fabric-rich-text';

import type {
  RichTextProps,
  DetectedContentType,      // 'link' | 'email' | 'phone'
  LinkFocusEvent,
  LinkFocusType,            // DetectedContentType | 'detected'
  RichTextMeasurementData,
  WritingDirection,         // 'auto' | 'ltr' | 'rtl'
} from 'react-native-fabric-rich-text';
```

## Error Handling

### Empty or Whitespace Content

Returns `null` if `text` is empty or contains only whitespace:

```tsx
<RichText text="" />          // Returns null
<RichText text="   " />       // Returns null
<RichText text="<p></p>" />   // Renders empty paragraph
```

### HTML Sanitization

All HTML is sanitized before rendering. Dangerous content is automatically removed:

```tsx
// Script tags are removed
<RichText text='<p>Safe</p><script>alert("xss")</script>' />
// Renders: Safe

// Event handlers are stripped
<RichText text='<p onclick="alert(1)">Click me</p>' />
// Renders: Click me

// javascript: URLs are blocked
<RichText text='<a href="javascript:alert(1)">Link</a>' />
// Renders: Link (href removed)
```

### Allowed Tags and Attributes

Access the sanitization allowlists:

```tsx
import { ALLOWED_TAGS, ALLOWED_ATTR } from 'react-native-fabric-rich-text';

console.log(ALLOWED_TAGS);
// ['p', 'div', 'h1', ..., 'bdi', 'bdo', 'ul', 'ol', 'li', ...]

console.log(ALLOWED_ATTR);
// ['href', 'class', 'dir']
```

## Testing

### Unit Testing

The library includes comprehensive test coverage:

```sh
# Run all tests
yarn test

# Run tests with coverage
yarn test --coverage
```

### Test IDs

Use the `testID` prop for testing:

```tsx
<RichText
  text="<p>Test content</p>"
  testID="my-rich-text"
/>
```

On native platforms, this sets the accessibility identifier. On web, it sets `data-testid`.

### E2E Testing

See the `/e2e` directory for Maestro-based end-to-end tests.

## Requirements

- React Native >= 0.81 (New Architecture / Fabric required)
- iOS >= 15.1
- Android API >= 21

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
