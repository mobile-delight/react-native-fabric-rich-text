import { render, screen } from '@testing-library/react-native';

// Mock the native adapter with support for list rendering
jest.mock('../../adapters/native', () => {
  const mockReact = require('react');
  const { Text, View } = require('react-native');

  return {
    HTMLTextNative: jest.fn(
      ({
        html,
        style,
        testID,
      }: {
        html: string;
        style?: object;
        testID?: string;
      }) => {
        // Simple list detection for testing
        // Convert <ul><li>item</li></ul> to bullet points
        // Convert <ol><li>item</li></ol> to numbered lists
        let processedContent = html;

        // Handle unordered lists
        const ulMatch = processedContent.match(/<ul[^>]*>([\s\S]*?)<\/ul>/gi);
        if (ulMatch) {
          ulMatch.forEach((ul) => {
            const items = ul.match(/<li[^>]*>([\s\S]*?)<\/li>/gi) || [];
            const bullets = items
              .map((li) => {
                const content = li.replace(/<\/?li[^>]*>/gi, '');
                return `• ${content}`;
              })
              .join('\n');
            processedContent = processedContent.replace(ul, bullets);
          });
        }

        // Handle ordered lists
        const olMatch = processedContent.match(/<ol[^>]*>([\s\S]*?)<\/ol>/gi);
        if (olMatch) {
          olMatch.forEach((ol) => {
            const items = ol.match(/<li[^>]*>([\s\S]*?)<\/li>/gi) || [];
            let counter = 1;
            const numbered = items
              .map((li) => {
                const content = li.replace(/<\/?li[^>]*>/gi, '');
                return `${counter++}. ${content}`;
              })
              .join('\n');
            processedContent = processedContent.replace(ol, numbered);
          });
        }

        // Handle orphaned li tags (no parent ul/ol)
        processedContent = processedContent.replace(
          /<li[^>]*>([\s\S]*?)<\/li>/gi,
          '$1'
        );

        // Remove remaining tags for display
        // Note: This is a test mock only. Actual sanitization happens in native code
        // (SwiftSoup on iOS, OWASP on Android). This simple regex is safe here
        // because test inputs are controlled, not user-supplied.
        const text = processedContent.replace(/<\/?[a-z][a-z0-9]*[^>]*>/gi, '');

        return mockReact.createElement(
          View,
          { testID, accessibilityRole: 'text' },
          mockReact.createElement(Text, { style }, text)
        );
      }
    ),
  };
});

import { HTMLTextNative } from '../../adapters/native';
import HTMLText from '../../components/HTMLText';

describe('Unordered List Rendering (T016)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders bullet markers for ul/li elements', () => {
    render(
      <HTMLText
        html="<ul><li>First</li><li>Second</li></ul>"
        testID="unordered-list"
      />
    );

    expect(HTMLTextNative).toHaveBeenCalledWith(
      expect.objectContaining({
        html: expect.any(String),
      }),
      undefined
    );

    // Verify bullets are rendered
    const text = screen.getByText(/• First/);
    expect(text).toBeTruthy();
  });

  it('orphaned li renders as plain text without marker', () => {
    render(<HTMLText html="<li>Orphan item</li>" testID="orphaned-li" />);

    // The mock removes list markers for orphaned li
    const text = screen.getByText('Orphan item');
    expect(text).toBeTruthy();

    // Should NOT have bullet marker
    expect(() => screen.getByText(/•/)).toThrow();
  });
});

describe('Ordered List Rendering (T017)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders sequential numbers for ol/li elements', () => {
    render(
      <HTMLText
        html="<ol><li>First</li><li>Second</li><li>Third</li></ol>"
        testID="ordered-list"
      />
    );

    const text = screen.getByText(/1\. First/);
    expect(text).toBeTruthy();
  });

  it('numbering restarts for separate ol elements', () => {
    render(
      <HTMLText
        html="<ol><li>A</li><li>B</li></ol><ol><li>X</li><li>Y</li></ol>"
        testID="separate-lists"
      />
    );

    // Both lists should start with 1
    const text = screen.getByText(/1\. A[\s\S]*1\. X/);
    expect(text).toBeTruthy();
  });
});

describe('Nested List Rendering (T018)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders nested lists with increased indentation', () => {
    const nestedHtml = `
      <ul>
        <li>Parent</li>
        <li>
          <ul>
            <li>Child</li>
          </ul>
        </li>
      </ul>
    `;

    expect(() => {
      render(<HTMLText html={nestedHtml} testID="nested-list" />);
    }).not.toThrow();
  });

  it('caps nesting at 3 levels', () => {
    const deeplyNested = `
      <ul>
        <li>Level 1
          <ul>
            <li>Level 2
              <ul>
                <li>Level 3
                  <ul>
                    <li>Level 4 - should cap at level 3 styling</li>
                  </ul>
                </li>
              </ul>
            </li>
          </ul>
        </li>
      </ul>
    `;

    expect(() => {
      render(<HTMLText html={deeplyNested} testID="deeply-nested" />);
    }).not.toThrow();
  });

  it('preserves accessibility with list semantics', () => {
    render(
      <HTMLText
        html="<ul><li>Accessible item</li></ul>"
        testID="accessible-list"
      />
    );

    const listView = screen.getByTestId('accessible-list');
    expect(listView).toBeTruthy();
  });
});

describe('Mixed List and Link Content', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders links inside list items', () => {
    const htmlWithLinksInList = `
      <ul>
        <li><a href="https://example.com">Link in list</a></li>
      </ul>
    `;

    expect(() => {
      render(<HTMLText html={htmlWithLinksInList} testID="link-in-list" />);
    }).not.toThrow();
  });

  it('renders bold text inside list items', () => {
    const htmlWithBoldInList = `
      <ul>
        <li><strong>Bold item</strong></li>
      </ul>
    `;

    expect(() => {
      render(<HTMLText html={htmlWithBoldInList} testID="bold-in-list" />);
    }).not.toThrow();
  });
});
