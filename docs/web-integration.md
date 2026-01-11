# Web Integration Guide

This guide covers the configuration required to use `react-native-fabric-rich-text` in web applications built with Next.js, Create React App, or other React web frameworks.

## Prerequisites

- React 18.0+
- Next.js 14+ (for SSR support) or any React web bundler
- Node.js 18+ (for SSR with sanitize-html)

## Installation

### 1. Install the Library

```bash
npm install react-native-fabric-rich-text

# Or with yarn
yarn add react-native-fabric-rich-text
```

### 2. Install Sanitization Dependencies

The library uses a dual-sanitizer approach for optimal performance:
- **Browser**: DOMPurify (uses native DOM APIs)
- **Server/SSR**: sanitize-html (Node.js native, no jsdom required)

```bash
# Install both sanitizers
npm install dompurify sanitize-html

# Or with yarn
yarn add dompurify sanitize-html
```

For TypeScript projects, also install the type definitions:

```bash
npm install -D @types/dompurify @types/sanitize-html

# Or with yarn
yarn add -D @types/dompurify @types/sanitize-html
```

> **Why two sanitizers?**
> - `DOMPurify` is fastest in browsers because it uses native DOM APIs
> - `sanitize-html` runs natively in Node.js without bundling jsdom (~2MB)
> - This keeps your client bundle small while enabling SSR

## Next.js Configuration

### Basic Setup

Create or update your `next.config.js`:

```javascript
// next.config.js
const path = require('path');

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,

  // Transpile the library for Next.js
  transpilePackages: ['react-native-fabric-rich-text'],

  // Keep sanitize-html as external for server components (Node.js native)
  experimental: {
    serverComponentsExternalPackages: ['sanitize-html'],
  },

  webpack: (config, { isServer }) => {
    // Resolve .web extensions before standard extensions
    config.resolve.extensions = [
      '.web.tsx',
      '.web.ts',
      '.web.js',
      '.web.jsx',
      ...config.resolve.extensions,
    ];

    // Alias the package to use the web-specific entry point
    config.resolve.alias = {
      ...config.resolve.alias,
      'react-native-fabric-rich-text': path.resolve(
        __dirname,
        'node_modules/react-native-fabric-rich-text/lib/module/index.web.js'
      ),
    };

    // Don't bundle sanitize-html on client (it's server-only)
    if (!isServer) {
      config.resolve.alias['sanitize-html'] = false;
    }

    return config;
  },
};

module.exports = nextConfig;
```

### With App Router (Recommended)

For Next.js App Router, components using `RichText` should be Client Components:

```tsx
// app/page.tsx
'use client';

import { RichText } from 'react-native-fabric-rich-text';

export default function Page() {
  return (
    <RichText
      text="<p>Hello <strong>World</strong></p>"
      className="text-blue-500"
    />
  );
}
```

### With Pages Router

For Pages Router, no special configuration is needed beyond the webpack config:

```tsx
// pages/index.tsx
import { RichText } from 'react-native-fabric-rich-text';

export default function Home() {
  return (
    <RichText text="<p>Hello World</p>" />
  );
}
```

## Create React App Configuration

For Create React App, you'll need to customize the webpack config using `craco` or `react-app-rewired`:

```javascript
// craco.config.js
const path = require('path');

module.exports = {
  webpack: {
    configure: (config) => {
      // Add .web extensions
      config.resolve.extensions = [
        '.web.tsx',
        '.web.ts',
        '.web.js',
        '.web.jsx',
        ...config.resolve.extensions,
      ];

      // Alias to web entry point
      config.resolve.alias = {
        ...config.resolve.alias,
        'react-native-fabric-rich-text': path.resolve(
          __dirname,
          'node_modules/react-native-fabric-rich-text/lib/module/index.web.js'
        ),
      };

      return config;
    },
  },
};
```

## Usage

### Basic HTML Rendering

```tsx
import { RichText } from 'react-native-fabric-rich-text';

function MyComponent() {
  return (
    <RichText text="<p>Hello <strong>World</strong></p>" />
  );
}
```

### With Tailwind CSS / className

The `className` prop is fully supported on web:

```tsx
<RichText
  text="<p>Styled content</p>"
  className="text-lg font-semibold text-blue-600 bg-blue-50 p-4 rounded-lg"
/>
```

### Text Truncation

Use `numberOfLines` to truncate text with CSS `-webkit-line-clamp`:

```tsx
// Single line with ellipsis
<RichText
  text="<p>Very long text that will be truncated...</p>"
  numberOfLines={1}
/>

// Multiple lines
<RichText
  text="<p>Long paragraph that spans multiple lines...</p>"
  numberOfLines={3}
/>
```

### Link Handling

Handle link clicks with the `onLinkPress` callback:

```tsx
<RichText
  text='<p>Visit <a href="https://example.com">our site</a></p>'
  onLinkPress={(url, type) => {
    console.log(`Link clicked: ${url} (type: ${type})`);
    // Prevent default navigation, handle custom behavior
  }}
/>
```

Without `onLinkPress`, links navigate normally using the browser's default behavior.

### Combining Features

```tsx
<RichText
  text="<p>This is a <strong>styled</strong> and <em>truncated</em> piece of content with custom link handling.</p>"
  className="text-gray-700 bg-amber-50 p-4 rounded border-l-4 border-amber-400"
  numberOfLines={2}
  onLinkPress={(url) => window.open(url, '_blank')}
  testID="my-rich-text"
/>
```

## Features

### Responsive Variants (Tailwind)

```tsx
<RichText
  text="<p>Responsive text</p>"
  className="text-sm md:text-base lg:text-xl"
/>
```

### Dark Mode

```tsx
<RichText
  text="<p>Theme-aware text</p>"
  className="text-gray-900 dark:text-gray-100 bg-white dark:bg-gray-800"
/>
```

### Hover Effects

```tsx
<RichText
  text="<p>Interactive text</p>"
  className="bg-gray-100 hover:bg-blue-100 transition-colors cursor-pointer"
/>
```

### Gradient Backgrounds

```tsx
<RichText
  text="<p>Gradient text</p>"
  className="p-4 bg-gradient-to-r from-cyan-500 to-blue-500 text-white rounded-lg"
/>
```

## SSR Considerations

### How It Works

The library automatically detects the environment and uses the appropriate sanitizer:

```typescript
// Simplified internal logic
if (typeof window !== 'undefined') {
  // Browser: Use DOMPurify (fast, native DOM)
  return DOMPurify.sanitize(html, options);
} else {
  // Server: Use sanitize-html (Node.js native)
  return sanitizeHtml(html, options);
}
```

### Hydration

Both sanitizers are configured with the same allowed tags and attribute allowlists. The sanitize-html configuration includes additional tag-specific attributes (e.g., `target`, `rel` for links; `src`, `alt`, `width`, `height` for images) that are stripped on the server but allowed through DOMPurify on the client. In practice, the library's test content doesn't use these extra attributes, preventing hydration mismatches.

### Client Bundle Size

With the webpack configuration above:
- `sanitize-html` is excluded from the client bundle
- Only `DOMPurify` (~15KB minified) is included client-side
- No jsdom dependency (would add ~2MB)

## XSS Protection

The library sanitizes all HTML input to prevent XSS attacks:

```tsx
// Script tags are removed
<RichText text='<p>Safe</p><script>alert("xss")</script>' />
// Renders: <p>Safe</p>

// Event handlers are stripped
<RichText text='<p onclick="alert(1)">Click me</p>' />
// Renders: <p>Click me</p>

// javascript: URLs are removed
<RichText text='<a href="javascript:alert(1)">Link</a>' />
// Renders: <a>Link</a> (href removed)
```

### Allowed Tags

By default, the following tags are allowed:
- Text: `p`, `span`, `br`, `strong`, `b`, `em`, `i`, `u`, `s`, `del`, `ins`, `mark`, `small`, `sub`, `sup`
- Headings: `h1`, `h2`, `h3`, `h4`, `h5`, `h6`
- Lists: `ul`, `ol`, `li`
- Links: `a`
- Blocks: `div`, `blockquote`, `pre`, `code`, `hr`

### Allowed Attributes

- Global: `class`, `id`, `style`
- Links: `href`, `target`, `rel`
- All elements inherit global attributes

You can access the allowed lists:

```tsx
import { ALLOWED_TAGS, ALLOWED_ATTR } from 'react-native-fabric-rich-text';

console.log(ALLOWED_TAGS); // ['p', 'span', 'br', ...]
console.log(ALLOWED_ATTR); // ['class', 'href', ...]
```

## Troubleshooting

### "Cannot find module 'react-native'"

This error occurs when the web bundler tries to import the native entry point. Ensure your webpack config:

1. Includes `.web` extensions first in `resolve.extensions`
2. Has the alias pointing to `index.web.js`

```javascript
config.resolve.alias = {
  'react-native-fabric-rich-text': path.resolve(
    __dirname,
    'node_modules/react-native-fabric-rich-text/lib/module/index.web.js'
  ),
};
```

### "sanitize is not a function"

This happens when importing from the wrong entry point. Make sure your alias points to `index.web.js`, not `RichText.web.js`.

### SSR Errors with sanitize-html

If you see errors about missing CSS files or node modules during SSR:

1. Add `sanitize-html` to `serverComponentsExternalPackages`:

```javascript
experimental: {
  serverComponentsExternalPackages: ['sanitize-html'],
},
```

2. Alias `sanitize-html` to `false` for client builds:

```javascript
if (!isServer) {
  config.resolve.alias['sanitize-html'] = false;
}
```

### Hydration Mismatch

If you see hydration warnings, ensure both sanitizers produce identical output:

1. Check that you're using compatible versions (dompurify ^3.2.0, sanitize-html ^2.13.0)
2. Don't modify the sanitizer options - the library configures them for consistency

### Truncation Not Working

CSS `-webkit-line-clamp` requires:
- `overflow: hidden`
- `display: -webkit-box`
- `-webkit-box-orient: vertical`

These are automatically applied when `numberOfLines > 0`. If truncation isn't working:

1. Check that no parent element overrides `overflow`
2. Ensure the container has a defined width
3. Test in Chrome/Safari (best support for line-clamp)

### Styles Not Applying

1. **Tailwind not processing**: Ensure your `tailwind.config.js` content paths include the library:

```javascript
content: [
  './app/**/*.{js,ts,jsx,tsx}',
  './node_modules/react-native-fabric-rich-text/**/*.{js,ts,jsx,tsx}',
],
```

2. **className prop empty**: The wrapper div only gets the className if provided - check your component props.

## Example Project

See the [example-web](../example-web/) directory for a complete Next.js implementation with:

- Basic HTML rendering demos
- Text truncation examples
- Tailwind CSS styling
- Dark mode support
- SSR configuration

## API Reference

### RichText Props (Web)

| Prop | Type | Description |
|------|------|-------------|
| `text` | `string` | HTML content to render (required) |
| `className` | `string` | CSS classes to apply to the container |
| `style` | `CSSProperties` | Inline styles for the container |
| `numberOfLines` | `number` | Max lines before truncation (0 = no limit) |
| `onLinkPress` | `(url: string, type: DetectedContentType) => void` | Callback when a link is clicked |
| `testID` | `string` | Sets `data-testid` attribute for testing |

### Exports

```tsx
import {
  RichText,           // Main component
  sanitize,           // Sanitization function
  ALLOWED_TAGS,       // Array of allowed HTML tags
  ALLOWED_ATTR,       // Array of allowed attributes
} from 'react-native-fabric-rich-text';

// Type imports
import type {
  RichTextProps,
  DetectedContentType,
} from 'react-native-fabric-rich-text';
```

## Additional Resources

- [DOMPurify Documentation](https://github.com/cure53/DOMPurify)
- [sanitize-html Documentation](https://github.com/apostrophecms/sanitize-html)
- [Next.js Documentation](https://nextjs.org/docs)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
