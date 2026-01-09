const path = require('path');

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  transpilePackages: ['react-native-fabric-rich-text'],
  experimental: {
    // Keep sanitize-html as external for server components (Node.js native)
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
        '../lib/module/index.web.js'
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
