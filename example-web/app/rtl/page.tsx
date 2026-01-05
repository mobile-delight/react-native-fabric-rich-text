'use client';

import HTMLText from 'react-native-fabric-html-text';
import DemoSection from '@/components/DemoSection';

export default function RTLPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6 text-gray-900 dark:text-gray-100">
        RTL (Right-to-Left) Support
      </h1>
      <p className="text-gray-600 dark:text-gray-400 mb-8">
        Demonstrations of RTL text direction support including Arabic, Hebrew,
        Persian, bidirectional elements, and the writingDirection prop.
      </p>

      {/* Basic RTL Text */}
      <h2 className="text-xl font-semibold mb-4 text-gray-800 dark:text-gray-200">
        Basic RTL Text
      </h2>

      <DemoSection
        title="Arabic Text"
        description="Arabic text renders right-to-left automatically"
        code={`<HTMLText html="<p>مرحباً بالعالم! هذا نص عربي يعرض من اليمين إلى اليسار.</p>" />`}
      >
        <HTMLText html="<p>مرحباً بالعالم! هذا نص عربي يعرض من اليمين إلى اليسار.</p>" />
      </DemoSection>

      <DemoSection
        title="Hebrew Text"
        description="Hebrew text renders right-to-left automatically"
        code={`<HTMLText html="<p>שלום עולם! זהו טקסט בעברית המוצג מימין לשמאל.</p>" />`}
      >
        <HTMLText html="<p>שלום עולם! זהו טקסט בעברית המוצג מימין לשמאל.</p>" />
      </DemoSection>

      <DemoSection
        title="Persian Text"
        description="Persian (Farsi) text renders right-to-left automatically"
        code={`<HTMLText html="<p>سلام دنیا! این یک متن فارسی است که از راست به چپ نمایش داده می‌شود.</p>" />`}
      >
        <HTMLText html="<p>سلام دنیا! این یک متن فارسی است که از راست به چپ نمایش داده می‌شود.</p>" />
      </DemoSection>

      {/* Mixed Directional Content */}
      <h2 className="text-xl font-semibold mb-4 mt-8 text-gray-800 dark:text-gray-200">
        Mixed Directional Content
      </h2>

      <DemoSection
        title="Mixed Arabic and English"
        description="Arabic and English text mixed in the same paragraph"
        code={`<HTMLText html="<p>مرحباً Hello عالم World!</p>" />`}
      >
        <HTMLText html="<p>مرحباً Hello عالم World!</p>" />
      </DemoSection>

      <DemoSection
        title="RTL with Embedded Numbers"
        description="Numbers within RTL text (dir attribute sets paragraph direction)"
        code={`<HTMLText html="<p dir='rtl'>السعر: 123.45 دولار</p>" />`}
      >
        <HTMLText html="<p dir='rtl'>السعر: 123.45 دولار</p>" />
      </DemoSection>

      <DemoSection
        title="RTL with Brand Names"
        description="English brand names embedded in Arabic text"
        code={`<HTMLText html="<p dir='rtl'>أنا أستخدم iPhone كل يوم</p>" />`}
      >
        <HTMLText html="<p dir='rtl'>أنا أستخدم iPhone كل يوم</p>" />
      </DemoSection>

      {/* BDI Isolation */}
      <h2 className="text-xl font-semibold mb-4 mt-8 text-gray-800 dark:text-gray-200">
        BDI Isolation
      </h2>

      <DemoSection
        title="BDI for User Names"
        description="The <bdi> tag isolates bidirectional text, preventing it from affecting surrounding punctuation"
        code={`<HTMLText html="<p>User: <bdi>محمد</bdi> logged in at 10:30 AM</p>" />`}
      >
        <HTMLText html="<p>User: <bdi>محمد</bdi> logged in at 10:30 AM</p>" />
      </DemoSection>

      <DemoSection
        title="Multiple BDI Elements"
        description="Multiple isolated bidirectional text segments"
        code={`<HTMLText html="<p>Winners: <bdi>אברהם</bdi>, <bdi>محمد</bdi>, and <bdi>יעקב</bdi></p>" />`}
      >
        <HTMLText html="<p>Winners: <bdi>אברהם</bdi>, <bdi>محمد</bdi>, and <bdi>יעקב</bdi></p>" />
      </DemoSection>

      {/* BDO Override */}
      <h2 className="text-xl font-semibold mb-4 mt-8 text-gray-800 dark:text-gray-200">
        BDO Override
      </h2>

      <DemoSection
        title="BDO with dir='rtl'"
        description="The <bdo> tag forces text direction, overriding the natural direction"
        code={`<HTMLText html="<p>Normal text, <bdo dir='rtl'>forced RTL</bdo>, back to normal</p>" />`}
      >
        <HTMLText html="<p>Normal text, <bdo dir='rtl'>forced RTL</bdo>, back to normal</p>" />
      </DemoSection>

      <DemoSection
        title="BDO with dir='ltr'"
        description="Force LTR direction within RTL context"
        code={`<HTMLText html="<p dir='rtl'>نص عربي، <bdo dir='ltr'>forced LTR</bdo>، عودة للعربي</p>" />`}
      >
        <HTMLText html="<p dir='rtl'>نص عربي، <bdo dir='ltr'>forced LTR</bdo>، عودة للعربي</p>" />
      </DemoSection>

      {/* Direction Attribute */}
      <h2 className="text-xl font-semibold mb-4 mt-8 text-gray-800 dark:text-gray-200">
        Direction Attribute
      </h2>

      <DemoSection
        title="dir='rtl' on Paragraph"
        description="Set paragraph-level text direction with dir attribute"
        code={`<HTMLText html="<p dir='rtl'>هذا فقرة باللغة العربية مع محاذاة صحيحة.</p>" />`}
      >
        <HTMLText html="<p dir='rtl'>هذا فقرة باللغة العربية مع محاذاة صحيحة.</p>" />
      </DemoSection>

      <DemoSection
        title="dir='ltr' on Paragraph"
        description="Explicit LTR direction (useful for forcing direction)"
        code={`<HTMLText html="<p dir='ltr'>Left to right paragraph with explicit direction.</p>" />`}
      >
        <HTMLText html="<p dir='ltr'>Left to right paragraph with explicit direction.</p>" />
      </DemoSection>

      <DemoSection
        title="dir='auto' (Auto-detection)"
        description="Direction is automatically detected from first strong character"
        code={`<HTMLText html="<p dir='auto'>مرحباً - this will be RTL because first strong char is Arabic</p>" />`}
      >
        <HTMLText html="<p dir='auto'>مرحباً - this will be RTL because first strong char is Arabic</p>" />
      </DemoSection>

      {/* Component-Level Direction */}
      <h2 className="text-xl font-semibold mb-4 mt-8 text-gray-800 dark:text-gray-200">
        Component-Level Direction (writingDirection prop)
      </h2>

      <DemoSection
        title="writingDirection='rtl'"
        description="Force RTL at the component level via writingDirection prop"
        code={`<HTMLText
  html="<p>This English text is forced RTL via writingDirection prop.</p>"
  writingDirection="rtl"
/>`}
      >
        <HTMLText
          html="<p>This English text is forced RTL via writingDirection prop.</p>"
          writingDirection="rtl"
        />
      </DemoSection>

      <DemoSection
        title="writingDirection='ltr'"
        description="Force LTR at the component level via writingDirection prop"
        code={`<HTMLText
  html="<p>مرحباً - forced LTR despite Arabic content</p>"
  writingDirection="ltr"
/>`}
      >
        <HTMLText
          html="<p>مرحباً - forced LTR despite Arabic content</p>"
          writingDirection="ltr"
        />
      </DemoSection>

      <DemoSection
        title="writingDirection='auto'"
        description="Auto-detect direction at component level (default behavior)"
        code={`<HTMLText
  html="<p>שלום עולם - auto detects Hebrew as RTL</p>"
  writingDirection="auto"
/>`}
      >
        <HTMLText
          html="<p>שלום עולם - auto detects Hebrew as RTL</p>"
          writingDirection="auto"
        />
      </DemoSection>

      {/* RTL + Features */}
      <h2 className="text-xl font-semibold mb-4 mt-8 text-gray-800 dark:text-gray-200">
        RTL + Features
      </h2>

      <DemoSection
        title="RTL with Formatting"
        description="Bold, italic, and underline in RTL text"
        code={`<HTMLText html="<p dir='rtl'><strong>مهم:</strong> هذا نص <em>مائل</em> و<u>تحته خط</u>.</p>" />`}
      >
        <HTMLText html="<p dir='rtl'><strong>مهم:</strong> هذا نص <em>مائل</em> و<u>تحته خط</u>.</p>" />
      </DemoSection>

      <DemoSection
        title="RTL with Links"
        description="Clickable links in RTL text"
        code={`<HTMLText
  html='<p dir="rtl">زيارة <a href="https://example.com">موقعنا</a> للمزيد من المعلومات.</p>'
  onLinkPress={(url, type) => alert(\`Clicked: \${url}\`)}
/>`}
      >
        <HTMLText
          html='<p dir="rtl">زيارة <a href="https://example.com">موقعنا</a> للمزيد من المعلومات.</p>'
          onLinkPress={(url) => alert(`Clicked: ${url}`)}
        />
      </DemoSection>

      <DemoSection
        title="RTL Unordered List"
        description="Bulleted list with RTL text"
        code={`<HTMLText html="<ul dir='rtl'><li>العنصر الأول</li><li>العنصر الثاني</li><li>العنصر الثالث</li></ul>" />`}
      >
        <HTMLText html="<ul dir='rtl'><li>العنصر الأول</li><li>العنصر الثاني</li><li>العنصر الثالث</li></ul>" />
      </DemoSection>

      <DemoSection
        title="RTL Ordered List"
        description="Numbered list with RTL text"
        code={`<HTMLText html="<ol dir='rtl'><li>الخطوة الأولى</li><li>الخطوة الثانية</li><li>الخطوة الثالثة</li></ol>" />`}
      >
        <HTMLText html="<ol dir='rtl'><li>الخطوة الأولى</li><li>الخطوة الثانية</li><li>الخطوة الثالثة</li></ol>" />
      </DemoSection>

      <DemoSection
        title="RTL with Truncation"
        description="Truncated RTL text with numberOfLines"
        code={`<HTMLText
  html="<p dir='rtl'>هذا نص طويل جداً سيتم اقتطاعه. يحتوي على محتوى عربي كثير لإظهار كيف يعمل الاقتطاع مع النص من اليمين إلى اليسار.</p>"
  numberOfLines={2}
/>`}
      >
        <HTMLText
          html="<p dir='rtl'>هذا نص طويل جداً سيتم اقتطاعه. يحتوي على محتوى عربي كثير لإظهار كيف يعمل الاقتطاع مع النص من اليمين إلى اليسار.</p>"
          numberOfLines={2}
        />
      </DemoSection>

      <DemoSection
        title="RTL with Custom Styles"
        description="Styled RTL text using tagStyles prop"
        code={`<HTMLText
  html="<p dir='rtl'><strong>مهم</strong> و <em>ملاحظة</em></p>"
  tagStyles={{
    strong: { color: '#CC0000' },
    em: { color: '#0066CC' },
  }}
/>`}
      >
        <HTMLText
          html="<p dir='rtl'><strong>مهم</strong> و <em>ملاحظة</em></p>"
          tagStyles={{
            strong: { color: '#CC0000' },
            em: { color: '#0066CC' },
          }}
        />
      </DemoSection>
    </div>
  );
}
