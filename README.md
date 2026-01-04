# react-native-fabric-html-text

Fabric-first HTML text renderer for React Native with iOS, Android, and web support.

## Features

- Native Fabric component for optimal performance
- HTML parsing and rendering (bold, italic, lists, links)
- Link detection (URLs, emails, phone numbers)
- Custom tag styles via `tagStyles` prop
- XSS protection with built-in sanitization

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

## Props

| Prop | Type | Description |
|------|------|-------------|
| `html` | `string` | HTML content to render |
| `style` | `TextStyle` | Style applied to the text |
| `tagStyles` | `Record<string, TextStyle>` | Custom styles per HTML tag |
| `onLinkPress` | `(url: string, type: DetectedContentType) => void` | Callback when a link is pressed |
| `detectLinks` | `boolean` | Auto-detect URLs in text |
| `detectPhoneNumbers` | `boolean` | Auto-detect phone numbers |
| `detectEmails` | `boolean` | Auto-detect email addresses |
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
