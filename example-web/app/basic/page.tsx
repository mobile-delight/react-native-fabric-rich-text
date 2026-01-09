'use client';

import RichText from 'react-native-fabric-rich-text';
import DemoSection from '@/components/DemoSection';

export default function BasicPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6 text-gray-900 dark:text-gray-100">
        Basic HTML Rendering
      </h1>
      <p className="text-gray-600 dark:text-gray-400 mb-8">
        Demonstrations of basic HTML rendering capabilities including
        paragraphs, formatting, headings, lists, links, and more.
      </p>

      <DemoSection
        title="Simple Paragraph"
        description="Basic paragraph text rendering"
        code={`<RichText html="<p>Hello World! This is a simple paragraph.</p>" />`}
      >
        <RichText html="<p>Hello World! This is a simple paragraph.</p>" />
      </DemoSection>

      <DemoSection
        title="Nested Formatting"
        description="Bold, italic, underline, and strikethrough text"
        code={`<RichText html="<p>This text has <strong>bold</strong>, <em>italic</em>, <u>underline</u>, and <s>strikethrough</s> formatting.</p>" />`}
      >
        <RichText html="<p>This text has <strong>bold</strong>, <em>italic</em>, <u>underline</u>, and <s>strikethrough</s> formatting.</p>" />
      </DemoSection>

      <DemoSection
        title="Heading Levels"
        description="HTML heading elements h1 through h6"
        code={`<RichText html="<h1>Heading 1</h1><h2>Heading 2</h2><h3>Heading 3</h3><h4>Heading 4</h4><h5>Heading 5</h5><h6>Heading 6</h6>" />`}
      >
        <RichText html="<h1>Heading 1</h1><h2>Heading 2</h2><h3>Heading 3</h3><h4>Heading 4</h4><h5>Heading 5</h5><h6>Heading 6</h6>" />
      </DemoSection>

      <DemoSection
        title="Unordered List"
        description="Bulleted list items"
        code={`<RichText html="<ul><li>First item</li><li>Second item</li><li>Third item</li></ul>" />`}
      >
        <RichText html="<ul><li>First item</li><li>Second item</li><li>Third item</li></ul>" />
      </DemoSection>

      <DemoSection
        title="Ordered List"
        description="Numbered list items"
        code={`<RichText html="<ol><li>First step</li><li>Second step</li><li>Third step</li></ol>" />`}
      >
        <RichText html="<ol><li>First step</li><li>Second step</li><li>Third step</li></ol>" />
      </DemoSection>

      <DemoSection
        title="Links (Default Behavior)"
        description="Links navigate in the same tab by default"
        code={`<RichText html='<p>Visit <a href="https://github.com">GitHub</a> for more info.</p>' />`}
      >
        <RichText html='<p>Visit <a href="https://github.com">GitHub</a> for more info.</p>' />
      </DemoSection>

      <DemoSection
        title="Links (With onLinkPress)"
        description="Custom link handling with onLinkPress callback"
        code={`<RichText
  html='<p>Click <a href="https://example.com">this link</a> to trigger the callback.</p>'
  onLinkPress={(url, type) => {
    alert(\`Link clicked: \${url} (type: \${type})\`);
  }}
/>`}
      >
        <RichText
          html='<p>Click <a href="https://example.com">this link</a> to trigger the callback.</p>'
          onLinkPress={(url, type) => {
            alert(`Link clicked: ${url} (type: ${type})`);
          }}
        />
      </DemoSection>

      <DemoSection
        title="Blockquote"
        description="Quoted text block"
        code={`<RichText html="<blockquote>This is a blockquote. It's often used for citations or highlighting important text.</blockquote>" />`}
      >
        <RichText html="<blockquote>This is a blockquote. It's often used for citations or highlighting important text.</blockquote>" />
      </DemoSection>

      <DemoSection
        title="Preformatted Text"
        description="Code or preformatted content"
        code={`<RichText html="<pre>const greeting = 'Hello World';\\nconsole.log(greeting);</pre>" />`}
      >
        <RichText
          html="<pre>const greeting = 'Hello World';
console.log(greeting);</pre>"
        />
      </DemoSection>
    </div>
  );
}
