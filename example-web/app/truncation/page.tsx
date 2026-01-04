'use client';

import HTMLText from 'react-native-fabric-html-text';
import DemoSection from '@/components/DemoSection';

const longParagraph = `<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>`;

const formattedContent = `<p>This is a <strong>bold</strong> and <em>italic</em> text that spans multiple lines. It includes various <u>formatting</u> options to demonstrate that truncation works correctly with nested HTML elements and preserves the formatting up to the truncation point.</p>`;

const multiParagraph = `<p>First paragraph with some content.</p><p>Second paragraph that continues the content.</p><p>Third paragraph with even more text to demonstrate multi-paragraph truncation.</p>`;

export default function TruncationPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6 text-gray-900 dark:text-gray-100">
        Text Truncation
      </h1>
      <p className="text-gray-600 dark:text-gray-400 mb-8">
        Demonstrations of the numberOfLines prop for truncating text content.
        Uses CSS -webkit-line-clamp for cross-browser support.
      </p>

      <DemoSection
        title="Single Line Truncation"
        description="Limit text to exactly 1 line with ellipsis"
        code={`<HTMLText
  html="${longParagraph}"
  numberOfLines={1}
/>`}
      >
        <HTMLText html={longParagraph} numberOfLines={1} />
      </DemoSection>

      <DemoSection
        title="Two Line Truncation"
        description="Limit text to 2 lines"
        code={`<HTMLText
  html="${longParagraph}"
  numberOfLines={2}
/>`}
      >
        <HTMLText html={longParagraph} numberOfLines={2} />
      </DemoSection>

      <DemoSection
        title="Three Line Truncation"
        description="Limit text to 3 lines"
        code={`<HTMLText
  html="${longParagraph}"
  numberOfLines={3}
/>`}
      >
        <HTMLText html={longParagraph} numberOfLines={3} />
      </DemoSection>

      <DemoSection
        title="No Truncation (Full Text)"
        description="Without numberOfLines prop, text displays fully"
        code={`<HTMLText
  html="${longParagraph}"
/>`}
      >
        <HTMLText html={longParagraph} />
      </DemoSection>

      <DemoSection
        title="Truncation with Formatted Text"
        description="Truncation preserves HTML formatting"
        code={`<HTMLText
  html="${formattedContent}"
  numberOfLines={2}
/>`}
      >
        <HTMLText html={formattedContent} numberOfLines={2} />
      </DemoSection>

      <DemoSection
        title="Truncation with Multiple Paragraphs"
        description="Truncation works across multiple paragraph elements"
        code={`<HTMLText
  html="${multiParagraph}"
  numberOfLines={2}
/>`}
      >
        <HTMLText html={multiParagraph} numberOfLines={2} />
      </DemoSection>

      <DemoSection
        title="numberOfLines={0} (No Truncation)"
        description="Setting numberOfLines to 0 disables truncation"
        code={`<HTMLText
  html="${longParagraph}"
  numberOfLines={0}
/>`}
      >
        <HTMLText html={longParagraph} numberOfLines={0} />
      </DemoSection>
    </div>
  );
}
