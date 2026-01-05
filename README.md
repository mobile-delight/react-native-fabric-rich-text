# react-native-fabric-html-text

Fabric-first HTML text renderer for React Native with iOS, Android, and web support.

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
npm install react-native-fabric-html-text
# or
yarn add react-native-fabric-html-text
```

### iOS

```sh
cd ios && pod install
```

## Usage

```tsx
import { HTMLText } from 'react-native-fabric-html-text';

export default function App() {
  return (
    <HTMLText
      html="<p>Hello <strong>world</strong></p>"
      style={{ fontSize: 16 }}
    />
  );
}
```

### With Links

```tsx
<HTMLText
  html='<p>Visit <a href="https://example.com">our site</a></p>'
  onLinkPress={(url, type) => {
    console.log(`Pressed ${type}: ${url}`);
  }}
/>
```

### With Custom Styles

```tsx
<HTMLText
  html="<p>Normal <strong>bold red</strong> and <em>italic blue</em></p>"
  tagStyles={{
    strong: { color: '#CC0000' },
    em: { color: '#0066CC' },
  }}
/>
```

### Auto-Detection

```tsx
<HTMLText
  html="<p>Call 555-123-4567 or email support@example.com</p>"
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
import { HTMLText } from 'react-native-fabric-html-text/nativewind';

function MyComponent() {
  return (
    <HTMLText
      html="<p>Hello <strong>World</strong></p>"
      className="text-blue-500 text-lg font-medium p-4"
    />
  );
}
```

### Responsive Variants

```tsx
<HTMLText
  html="<p>Responsive text</p>"
  className="text-sm md:text-base lg:text-lg"
/>
```

### Dark Mode

```tsx
<HTMLText
  html="<p>Theme-aware text</p>"
  className="text-gray-900 dark:text-gray-100"
/>
```

### Manual Integration

For more control, apply `cssInterop` yourself:

```tsx
import { HTMLText } from 'react-native-fabric-html-text';
import { cssInterop } from 'nativewind';

// Apply once at app startup
cssInterop(HTMLText, { className: 'style' });

function MyComponent() {
  return (
    <HTMLText
      html="<p>Hello World</p>"
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
<HTMLText html="<p>مرحباً بالعالم!</p>" />
<HTMLText html="<p>שלום עולם!</p>" />
```

### Direction Attribute

Use the `dir` attribute to control text direction:

```tsx
// Explicit RTL
<HTMLText html="<p dir='rtl'>Right-to-left paragraph</p>" />

// Explicit LTR
<HTMLText html="<p dir='ltr'>Left-to-right paragraph</p>" />

// Auto-detect from first strong character
<HTMLText html="<p dir='auto'>مرحباً - detects as RTL</p>" />
```

### writingDirection Prop

Control direction at the component level:

```tsx
// Force RTL for entire component
<HTMLText
  html="<p>This will render RTL</p>"
  writingDirection="rtl"
/>

// Force LTR
<HTMLText
  html="<p>مرحباً</p>"
  writingDirection="ltr"
/>

// Auto-detect (default)
<HTMLText
  html="<p>Text</p>"
  writingDirection="auto"
/>
```

### BDI Element (Bidirectional Isolation)

The `<bdi>` tag isolates bidirectional text to prevent it from affecting surrounding content. Useful for user-generated content:

```tsx
<HTMLText html="<p>User: <bdi>محمد</bdi> logged in</p>" />
<HTMLText html="<p>Winners: <bdi>אברהם</bdi>, <bdi>محمد</bdi></p>" />
```

### BDO Element (Bidirectional Override)

The `<bdo>` tag forces text direction, overriding the natural direction:

```tsx
// Force RTL
<HTMLText html="<p>Normal <bdo dir='rtl'>forced RTL</bdo> normal</p>" />

// Force LTR within RTL context
<HTMLText html="<p dir='rtl'>عربي <bdo dir='ltr'>forced LTR</bdo> عربي</p>" />
```

### Mixed Content

RTL text with embedded LTR content (numbers, brand names) is handled automatically:

```tsx
<HTMLText html="<p dir='rtl'>السعر: 123.45 دولار</p>" />
<HTMLText html="<p dir='rtl'>أنا أستخدم iPhone كل يوم</p>" />
```

### RTL with Formatting

All text formatting works with RTL:

```tsx
<HTMLText
  html="<p dir='rtl'><strong>مهم:</strong> نص <em>مائل</em> و<u>تحته خط</u></p>"
/>
```

### I18nManager Integration

On React Native, the component respects `I18nManager.isRTL` as the default base direction when `writingDirection="auto"` (the default).

## Props

| Prop | Type | Description |
|------|------|-------------|
| `html` | `string` | HTML content to render |
| `style` | `TextStyle` | Style applied to the text |
| `className` | `string` | Tailwind CSS classes (requires `/nativewind` import) |
| `tagStyles` | `Record<string, TextStyle>` | Custom styles per HTML tag |
| `onLinkPress` | `(url: string, type: DetectedContentType) => void` | Callback when a link is pressed |
| `detectLinks` | `boolean` | Auto-detect URLs in text |
| `detectPhoneNumbers` | `boolean` | Auto-detect phone numbers |
| `detectEmails` | `boolean` | Auto-detect email addresses |
| `numberOfLines` | `number` | Limit text to specified number of lines with animated height transitions (0 = no limit) |
| `animationDuration` | `number` | Height animation duration in seconds (default: 0.2) |
| `writingDirection` | `'auto' \| 'ltr' \| 'rtl'` | Text direction: auto-detect (default), left-to-right, or right-to-left |
| `includeFontPadding` | `boolean` | Android: include font padding |

## Requirements

- React Native >= 0.80 (New Architecture / Fabric)
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
