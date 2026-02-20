/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './index.js',
    './src/**/*.{js,jsx,ts,tsx}',
    // Include the library for class scanning
    '../src/**/*.{js,jsx,ts,tsx}',
  ],
  presets: [require('nativewind/preset')],
  theme: {
    // Override fontSize with px values for React Native
    // NativeWind's default rem-based values are smaller than expected
    fontSize: {
      xs: ['12px', { lineHeight: '16px' }],
      sm: ['14px', { lineHeight: '20px' }],
      base: ['16px', { lineHeight: '24px' }],
      lg: ['18px', { lineHeight: '28px' }],
      xl: ['20px', { lineHeight: '28px' }],
      '2xl': ['24px', { lineHeight: '32px' }],
      '3xl': ['30px', { lineHeight: '36px' }],
      '4xl': ['36px', { lineHeight: '40px' }],
      '5xl': ['48px', { lineHeight: '48px' }],
    },
    // Override lineHeight (leading-*) with px values
    lineHeight: {
      none: '1',
      tight: '16px',
      snug: '20px',
      normal: '24px',
      relaxed: '26px',
      loose: '32px',
      3: '12px',
      4: '16px',
      5: '20px',
      6: '24px',
      7: '28px',
      8: '32px',
      9: '36px',
      10: '40px',
    },
    extend: {},
  },
  plugins: [],
};
