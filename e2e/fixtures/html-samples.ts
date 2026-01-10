export interface ExpectedStyle {
  element: string;
  properties: {
    fontWeight?: 'normal' | 'bold';
    fontStyle?: 'normal' | 'italic';
    textDecoration?: 'none' | 'underline' | 'line-through';
  };
}

export interface TestFixture {
  id: string;
  name: string;
  category: 'basic' | 'nested' | 'edge-case';
  text: string;
  expectedStyles: ExpectedStyle[];
  description: string;
}

export const basicFixtures: TestFixture[] = [
  {
    id: 'hello-world',
    name: 'Hello World',
    category: 'basic',
    text: '<h1>Hello World</h1><p>This is <strong>bold</strong> and <em>italic</em> text.</p>',
    expectedStyles: [
      { element: 'h1', properties: { fontWeight: 'bold' } },
      { element: 'strong', properties: { fontWeight: 'bold' } },
      { element: 'em', properties: { fontStyle: 'italic' } },
    ],
    description: 'Basic heading with bold and italic text',
  },
  {
    id: 'plain-text',
    name: 'Plain Text',
    category: 'basic',
    text: '<p>Plain text paragraph</p>',
    expectedStyles: [
      {
        element: 'p',
        properties: { fontWeight: 'normal', fontStyle: 'normal' },
      },
    ],
    description: 'Simple paragraph with default styling',
  },
  {
    id: 'bold-only',
    name: 'Bold Text',
    category: 'basic',
    text: '<strong>Bold text</strong>',
    expectedStyles: [{ element: 'strong', properties: { fontWeight: 'bold' } }],
    description: 'Text with bold styling only',
  },
  {
    id: 'italic-only',
    name: 'Italic Text',
    category: 'basic',
    text: '<em>Italic text</em>',
    expectedStyles: [{ element: 'em', properties: { fontStyle: 'italic' } }],
    description: 'Text with italic styling only',
  },
  {
    id: 'underline-only',
    name: 'Underlined Text',
    category: 'basic',
    text: '<u>Underlined text</u>',
    expectedStyles: [
      { element: 'u', properties: { textDecoration: 'underline' } },
    ],
    description: 'Text with underline styling only',
  },
];

export const nestedFixtures: TestFixture[] = [
  {
    id: 'nested-2-bold-italic',
    name: 'Bold + Italic',
    category: 'nested',
    text: '<strong><em>Bold and italic</em></strong>',
    expectedStyles: [
      {
        element: 'strong>em',
        properties: { fontWeight: 'bold', fontStyle: 'italic' },
      },
    ],
    description: 'Text with both bold and italic (2-level nesting)',
  },
  {
    id: 'nested-2-italic-underline',
    name: 'Italic + Underline',
    category: 'nested',
    text: '<em><u>Italic and underlined</u></em>',
    expectedStyles: [
      {
        element: 'em>u',
        properties: { fontStyle: 'italic', textDecoration: 'underline' },
      },
    ],
    description: 'Text with both italic and underline (2-level nesting)',
  },
  {
    id: 'nested-3-bold-italic-underline',
    name: 'Bold + Italic + Underline',
    category: 'nested',
    text: '<strong><em><u>All three styles</u></em></strong>',
    expectedStyles: [
      {
        element: 'strong>em>u',
        properties: {
          fontWeight: 'bold',
          fontStyle: 'italic',
          textDecoration: 'underline',
        },
      },
    ],
    description: 'Text with bold, italic, and underline (3-level nesting)',
  },
  {
    id: 'nested-4-all',
    name: 'All Four Styles',
    category: 'nested',
    text: '<strong><em><u><s>Bold, italic, underlined, strikethrough</s></u></em></strong>',
    expectedStyles: [
      {
        element: 'strong>em>u>s',
        properties: {
          fontWeight: 'bold',
          fontStyle: 'italic',
          textDecoration: 'line-through',
        },
      },
    ],
    description: 'Text with all four styles (4-level nesting)',
  },
];

export const edgeCaseFixtures: TestFixture[] = [
  {
    id: 'long-text',
    name: 'Long Text',
    category: 'edge-case',
    text: '<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.</p>',
    expectedStyles: [{ element: 'p', properties: { fontWeight: 'normal' } }],
    description: 'Long text that should wrap correctly',
  },
  {
    id: 'special-chars',
    name: 'Special Characters',
    category: 'edge-case',
    text: '<p>Caf\u00e9, na\u00efve, &amp; &lt;tags&gt;</p>',
    expectedStyles: [{ element: 'p', properties: { fontWeight: 'normal' } }],
    description: 'Text with special characters and HTML entities',
  },
  {
    id: 'empty-tags',
    name: 'Empty Tags',
    category: 'edge-case',
    text: '<p><strong></strong>Text after empty</p>',
    expectedStyles: [{ element: 'p', properties: { fontWeight: 'normal' } }],
    description: 'Handles empty inline elements gracefully',
  },
  {
    id: 'mixed-nesting',
    name: 'Mixed Nesting',
    category: 'edge-case',
    text: '<p>Normal <strong>bold <em>bold-italic</em> bold</strong> normal</p>',
    expectedStyles: [
      { element: 'strong', properties: { fontWeight: 'bold' } },
      {
        element: 'strong>em',
        properties: { fontWeight: 'bold', fontStyle: 'italic' },
      },
    ],
    description: 'Mixed nesting with correct style boundaries',
  },
];

export const allFixtures: TestFixture[] = [
  ...basicFixtures,
  ...nestedFixtures,
  ...edgeCaseFixtures,
];

export function getFixtureById(id: string): TestFixture | undefined {
  return allFixtures.find((fixture) => fixture.id === id);
}

export function getFixturesByCategory(
  category: TestFixture['category']
): TestFixture[] {
  return allFixtures.filter((fixture) => fixture.category === category);
}
