'use client';

import RichText from 'react-native-fabric-rich-text';
import DemoSection from '@/components/DemoSection';

export default function StylingPage(): React.JSX.Element {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6 text-gray-900 dark:text-gray-100">
        Styling with className & Tailwind
      </h1>
      <p className="text-gray-600 dark:text-gray-400 mb-8">
        Demonstrations of applying custom styles via className prop and Tailwind
        CSS utilities. The className prop allows seamless integration with
        utility-first CSS frameworks.
      </p>

      <DemoSection
        title="Basic className"
        description="Apply a simple className to the container"
        code={`<RichText
  html="<p>Text with custom className</p>"
  className="text-blue-600 dark:text-blue-400"
/>`}
      >
        <RichText
          html="<p>Text with custom className</p>"
          className="text-blue-600 dark:text-blue-400"
        />
      </DemoSection>

      <DemoSection
        title="Multiple Tailwind Classes"
        description="Combine multiple Tailwind utilities"
        code={`<RichText
  html="<p>Styled text content</p>"
  className="text-lg font-semibold text-purple-700 dark:text-purple-300 bg-purple-50 dark:bg-purple-900/50 p-4 rounded-lg"
/>`}
      >
        <RichText
          html="<p>Styled text content</p>"
          className="text-lg font-semibold text-purple-700 dark:text-purple-300 bg-purple-50 dark:bg-purple-900/50 p-4 rounded-lg"
        />
      </DemoSection>

      <DemoSection
        title="Border and Shadow"
        description="Add borders and shadows via Tailwind"
        code={`<RichText
  html="<p>Card-like styling with border and shadow</p>"
  className="p-6 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl shadow-md"
/>`}
      >
        <RichText
          html="<p>Card-like styling with border and shadow</p>"
          className="p-6 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl shadow-md"
        />
      </DemoSection>

      <DemoSection
        title="Gradient Background"
        description="Apply gradient backgrounds"
        code={`<RichText
  html="<p>Text with gradient background</p>"
  className="p-4 bg-gradient-to-r from-cyan-500 to-blue-500 text-white rounded-lg"
/>`}
      >
        <RichText
          html="<p>Text with gradient background</p>"
          className="p-4 bg-gradient-to-r from-cyan-500 to-blue-500 text-white rounded-lg"
        />
      </DemoSection>

      <DemoSection
        title="Responsive Typography"
        description="Use responsive text sizes"
        code={`<RichText
  html="<p>Responsive text that scales with screen size</p>"
  className="text-sm md:text-base lg:text-xl"
/>`}
      >
        <RichText
          html="<p>Responsive text that scales with screen size</p>"
          className="text-sm md:text-base lg:text-xl"
        />
      </DemoSection>

      <DemoSection
        title="Hover Effects"
        description="Add hover states (inspect element to see)"
        code={`<RichText
  html="<p>Hover over me!</p>"
  className="p-4 bg-gray-100 dark:bg-gray-800 hover:bg-blue-100 dark:hover:bg-blue-900 transition-colors cursor-pointer rounded"
/>`}
      >
        <RichText
          html="<p>Hover over me!</p>"
          className="p-4 bg-gray-100 dark:bg-gray-800 hover:bg-blue-100 dark:hover:bg-blue-900 transition-colors cursor-pointer rounded"
        />
      </DemoSection>

      <DemoSection
        title="Combining with numberOfLines"
        description="Style truncated text"
        code={`<RichText
  html="<p>This is a long piece of text that will be truncated to 2 lines with custom styling applied. The truncation respects the styling context.</p>"
  numberOfLines={2}
  className="text-gray-600 dark:text-gray-300 bg-amber-50 dark:bg-amber-900/30 p-4 rounded border-l-4 border-amber-400 dark:border-amber-600"
/>`}
      >
        <RichText
          html="<p>This is a long piece of text that will be truncated to 2 lines with custom styling applied. The truncation respects the styling context.</p>"
          numberOfLines={2}
          className="text-gray-600 dark:text-gray-300 bg-amber-50 dark:bg-amber-900/30 p-4 rounded border-l-4 border-amber-400 dark:border-amber-600"
        />
      </DemoSection>

      <DemoSection
        title="Complex HTML with Styling"
        description="Style complex HTML content"
        code={`<RichText
  html="<h2>Styled Heading</h2><p>With <strong>formatted</strong> content.</p>"
  className="prose prose-blue dark:prose-invert max-w-none"
/>`}
      >
        <RichText
          html="<h2>Styled Heading</h2><p>With <strong>formatted</strong> content.</p>"
          className="prose prose-blue dark:prose-invert max-w-none"
        />
      </DemoSection>

      <h2 className="text-xl font-bold mt-10 mb-4 text-gray-900 dark:text-gray-100">
        Container Queries
      </h2>
      <p className="text-gray-600 dark:text-gray-400 mb-6">
        Container queries allow text to respond to container size instead of
        viewport. Use the{' '}
        <code className="bg-gray-100 dark:bg-gray-800 px-1 rounded">
          @container
        </code>{' '}
        class on a parent and{' '}
        <code className="bg-gray-100 dark:bg-gray-800 px-1 rounded">@sm:</code>,{' '}
        <code className="bg-gray-100 dark:bg-gray-800 px-1 rounded">@md:</code>,{' '}
        <code className="bg-gray-100 dark:bg-gray-800 px-1 rounded">@lg:</code>{' '}
        variants on children.
      </p>

      <DemoSection
        title="Container Query - Full Width"
        description="Text scales based on container width, not viewport"
        code={`<div className="@container w-full bg-slate-100 dark:bg-slate-800 p-2 rounded-lg">
  <RichText
    html="<p>Inside a <strong>full-width container</strong>. Text responds to container size.</p>"
    className="text-sm @sm:text-base @md:text-lg @lg:text-xl leading-relaxed text-slate-700 dark:text-slate-300"
  />
</div>`}
      >
        <div className="@container w-full bg-slate-100 dark:bg-slate-800 p-2 rounded-lg">
          <RichText
            html="<p>Inside a <strong>full-width container</strong>. Text responds to container size.</p>"
            className="text-sm @sm:text-base @md:text-lg @lg:text-xl leading-relaxed text-slate-700 dark:text-slate-300"
          />
        </div>
      </DemoSection>

      <DemoSection
        title="Container Query - Half Width"
        description="Same classes, smaller container = different result"
        code={`<div className="@container w-1/2 bg-amber-100 dark:bg-amber-900/50 p-2 rounded-lg">
  <RichText
    html="<p>Inside a <strong>half-width container</strong>. Same classes, different result!</p>"
    className="text-sm @sm:text-base @md:text-lg @lg:text-xl leading-relaxed text-amber-800 dark:text-amber-200"
  />
</div>`}
      >
        <div className="@container w-1/2 bg-amber-100 dark:bg-amber-900/50 p-2 rounded-lg">
          <RichText
            html="<p>Inside a <strong>half-width container</strong>. Same classes, different result!</p>"
            className="text-sm @sm:text-base @md:text-lg @lg:text-xl leading-relaxed text-amber-800 dark:text-amber-200"
          />
        </div>
      </DemoSection>

      <DemoSection
        title="Container Query - Side by Side"
        description="Two containers adapting independently"
        code={`<div className="flex gap-2">
  <div className="@container flex-1 bg-emerald-100 dark:bg-emerald-900/50 p-2 rounded-lg">
    <RichText
      html="<p><strong>Left</strong> container adapts independently.</p>"
      className="text-xs @sm:text-sm @md:text-base leading-snug text-emerald-800 dark:text-emerald-200"
    />
  </div>
  <div className="@container flex-1 bg-violet-100 dark:bg-violet-900/50 p-2 rounded-lg">
    <RichText
      html="<p><strong>Right</strong> container adapts independently.</p>"
      className="text-xs @sm:text-sm @md:text-base leading-snug text-violet-800 dark:text-violet-200"
    />
  </div>
</div>`}
      >
        <div className="flex gap-2">
          <div className="@container flex-1 bg-emerald-100 dark:bg-emerald-900/50 p-2 rounded-lg">
            <RichText
              html="<p><strong>Left</strong> container adapts independently.</p>"
              className="text-xs @sm:text-sm @md:text-base leading-snug text-emerald-800 dark:text-emerald-200"
            />
          </div>
          <div className="@container flex-1 bg-violet-100 dark:bg-violet-900/50 p-2 rounded-lg">
            <RichText
              html="<p><strong>Right</strong> container adapts independently.</p>"
              className="text-xs @sm:text-sm @md:text-base leading-snug text-violet-800 dark:text-violet-200"
            />
          </div>
        </div>
      </DemoSection>

      <DemoSection
        title="Container Query - Named"
        description="Named containers for precise targeting (@container/card)"
        code={`<div className="@container/card w-full bg-rose-100 dark:bg-rose-900/50 p-3 rounded-lg">
  <RichText
    html="<p>Uses a <strong>named container</strong> (@container/card) for precise targeting.</p>"
    className="text-sm @sm/card:text-base @md/card:text-lg leading-relaxed text-rose-800 dark:text-rose-200"
  />
</div>`}
      >
        <div className="@container/card w-full bg-rose-100 dark:bg-rose-900/50 p-3 rounded-lg">
          <RichText
            html="<p>Uses a <strong>named container</strong> (@container/card) for precise targeting.</p>"
            className="text-sm @sm/card:text-base @md/card:text-lg leading-relaxed text-rose-800 dark:text-rose-200"
          />
        </div>
      </DemoSection>

      <DemoSection
        title="Container Query - Nested"
        description="Nested containers each respond to their own size"
        code={`<div className="@container bg-sky-100 dark:bg-sky-900/50 p-3 rounded-lg">
  <RichText
    html="<p><strong>Outer</strong> container text.</p>"
    className="text-sm @md:text-base leading-relaxed text-sky-800 dark:text-sky-200 mb-2"
  />
  <div className="@container bg-sky-200 dark:bg-sky-800/50 p-2 rounded">
    <RichText
      html="<p><strong>Inner</strong> container responds to its own size.</p>"
      className="text-xs @sm:text-sm leading-snug text-sky-900 dark:text-sky-100"
    />
  </div>
</div>`}
      >
        <div className="@container bg-sky-100 dark:bg-sky-900/50 p-3 rounded-lg">
          <RichText
            html="<p><strong>Outer</strong> container text.</p>"
            className="text-sm @md:text-base leading-relaxed text-sky-800 dark:text-sky-200 mb-2"
          />
          <div className="@container bg-sky-200 dark:bg-sky-800/50 p-2 rounded">
            <RichText
              html="<p><strong>Inner</strong> container responds to its own size.</p>"
              className="text-xs @sm:text-sm leading-snug text-sky-900 dark:text-sky-100"
            />
          </div>
        </div>
      </DemoSection>
    </div>
  );
}
