import Link from 'next/link';

const demoPages = [
  {
    href: '/basic',
    title: 'Basic Rendering',
    description: 'Simple paragraphs, formatting, headings, lists, and links',
  },
  {
    href: '/truncation',
    title: 'Text Truncation',
    description: 'Line clamping with numberOfLines prop using CSS',
  },
  {
    href: '/styling',
    title: 'Styling',
    description: 'Inline styles, className, Tailwind CSS, and tagStyles',
  },
];

export default function HomePage() {
  return (
    <div>
      <section className="mb-12">
        <h1 className="text-3xl font-bold mb-4 text-gray-900 dark:text-gray-100">
          FabricRichText Web Demo
        </h1>
        <p className="text-lg text-gray-600 dark:text-gray-400 mb-6">
          A cross-platform HTML text renderer for React Native with full web
          support. Render sanitized HTML content with consistent styling across
          iOS, Android, and Web.
        </p>
      </section>

      <section className="mb-12">
        <h2 className="text-xl font-semibold mb-4 text-gray-900 dark:text-gray-100">
          Demo Pages
        </h2>
        <div className="grid gap-4 md:grid-cols-3">
          {demoPages.map((page) => (
            <Link
              key={page.href}
              href={page.href}
              className="block p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:border-blue-500 dark:hover:border-blue-400 transition-colors"
            >
              <h3 className="font-medium text-gray-900 dark:text-gray-100 mb-1">
                {page.title}
              </h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                {page.description}
              </p>
            </Link>
          ))}
        </div>
      </section>

      <section className="mb-12">
        <h2 className="text-xl font-semibold mb-4 text-gray-900 dark:text-gray-100">
          Installation
        </h2>
        <pre className="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto">
          <code>yarn add react-native-fabric-rich-text</code>
        </pre>
      </section>

      <section className="mb-12">
        <h2 className="text-xl font-semibold mb-4 text-gray-900 dark:text-gray-100">
          Next.js Configuration
        </h2>
        <p className="text-gray-600 dark:text-gray-400 mb-4">
          Add the following to your{' '}
          <code className="bg-gray-100 dark:bg-gray-800 px-1 rounded">
            next.config.js
          </code>
          :
        </p>
        <pre className="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto text-sm">
          <code>{`const nextConfig = {
  transpilePackages: ['react-native-fabric-rich-text'],
  webpack: (config) => {
    config.resolve.extensions = [
      '.web.tsx', '.web.ts', '.web.js',
      ...config.resolve.extensions,
    ];
    return config;
  },
};`}</code>
        </pre>
      </section>

      <section>
        <h2 className="text-xl font-semibold mb-4 text-gray-900 dark:text-gray-100">
          Basic Usage
        </h2>
        <pre className="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto text-sm">
          <code>{`'use client';

import { RichText } from 'react-native-fabric-rich-text';

export default function MyComponent() {
  return (
    <RichText
      text="<p>Hello <strong>world</strong>!</p>"
    />
  );
}`}</code>
        </pre>
      </section>
    </div>
  );
}
