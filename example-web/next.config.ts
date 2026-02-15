import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  transpilePackages: ['react-native-fabric-rich-text'],
  serverExternalPackages: ['sanitize-html'],
  turbopack: {
    // Resolve .web extensions before standard extensions
    resolveExtensions: [
      '.web.tsx',
      '.web.ts',
      '.web.js',
      '.web.jsx',
      '.tsx',
      '.ts',
      '.js',
      '.jsx',
      '.mjs',
      '.json',
    ],
    resolveAlias: {
      // Alias the package to use the web-specific entry point
      'react-native-fabric-rich-text': '../lib/module/index.web.js',
      // Don't bundle sanitize-html on client (it's server-only)
      'sanitize-html': {
        browser: './empty.js',
      },
    },
  },
};

export default nextConfig;
