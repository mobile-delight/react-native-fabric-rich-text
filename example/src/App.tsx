import { useState, useCallback } from 'react';
import {
  StyleSheet,
  ScrollView,
  Text,
  Alert,
  View,
  TouchableOpacity,
  useColorScheme,
} from 'react-native';
import {
  HTMLText,
  type DetectedContentType,
} from 'react-native-fabric-html-text';
import { HTMLText as NativeWindHTMLText } from 'react-native-fabric-html-text/nativewind';
import '../global.css';

type StylingMode = 'stylesheet' | 'nativewind';

function SegmentedControl({
  value,
  onChange,
}: {
  value: StylingMode;
  onChange: (mode: StylingMode) => void;
}): React.JSX.Element {
  return (
    <View style={styles.segmentedControl}>
      <TouchableOpacity
        style={[styles.segment, value === 'stylesheet' && styles.segmentActive]}
        onPress={() => onChange('stylesheet')}
      >
        <Text
          style={[
            styles.segmentText,
            value === 'stylesheet' && styles.segmentTextActive,
          ]}
        >
          StyleSheet
        </Text>
      </TouchableOpacity>
      <TouchableOpacity
        style={[styles.segment, value === 'nativewind' && styles.segmentActive]}
        onPress={() => onChange('nativewind')}
      >
        <Text
          style={[
            styles.segmentText,
            value === 'nativewind' && styles.segmentTextActive,
          ]}
        >
          NativeWind
        </Text>
      </TouchableOpacity>
    </View>
  );
}

function StyleSheetExamples({
  onLinkPress,
  expandedText,
  toggleExpanded,
  numberOfLinesDemo,
  cycleNumberOfLines,
}: {
  onLinkPress: (url: string, type: DetectedContentType) => void;
  expandedText: boolean;
  toggleExpanded: () => void;
  numberOfLinesDemo: number;
  cycleNumberOfLines: () => void;
}): React.JSX.Element {
  return (
    <>
      <Text style={styles.sectionTitle}>Basic Formatting</Text>
      <HTMLText
        html="<h1>Hello World</h1><p>This is <strong>bold</strong> and <em>italic</em> text.</p>"
        style={styles.text}
        testID="basic-formatting"
      />

      <Text style={styles.sectionTitle}>Links</Text>
      <HTMLText
        html='<p>Visit <a href="https://example.com">Example.com</a> or <a href="https://react-native.dev">React Native Docs</a>.</p>'
        style={styles.text}
        onLinkPress={onLinkPress}
        testID="links-example"
      />

      <Text style={styles.sectionTitle}>Unordered List</Text>
      <HTMLText
        html="<ul><li>First item</li><li>Second item</li><li>Third item</li></ul>"
        style={styles.text}
        testID="unordered-list"
      />

      <Text style={styles.sectionTitle}>Ordered List</Text>
      <HTMLText
        html="<ol><li>Step one</li><li>Step two</li><li>Step three</li></ol>"
        style={styles.text}
        testID="ordered-list"
      />

      <Text style={styles.sectionTitle}>Nested Lists</Text>
      <HTMLText
        html="<ul><li>Parent item<ul><li>Child item 1</li><li>Child item 2</li></ul></li><li>Another parent</li></ul>"
        style={styles.text}
        testID="nested-lists"
      />

      <Text style={styles.sectionTitle}>Custom Tag Styles</Text>
      <HTMLText
        html="<p>Normal text with <strong>custom red bold</strong> and <em>custom blue italic</em>.</p>"
        style={styles.text}
        tagStyles={{
          strong: { color: '#CC0000' },
          em: { color: '#0066CC' },
        }}
        testID="custom-tag-styles"
      />

      <Text style={styles.sectionTitle}>Native HTML Text Decoration</Text>
      <HTMLText
        html="<p>Text with <u>underline tag</u> and <s>strikethrough tag</s> using native HTML.</p>"
        style={styles.text}
        testID="native-text-decoration"
      />

      <Text style={styles.sectionTitle}>Phone Detection</Text>
      <HTMLText
        html="<p>Call us at 555-123-4567 for support.</p>"
        style={styles.text}
        detectPhoneNumbers
        onLinkPress={onLinkPress}
        testID="phone-detection"
      />

      <Text style={styles.sectionTitle}>Email Detection</Text>
      <HTMLText
        html="<p>Contact support@example.com for help.</p>"
        style={styles.text}
        detectEmails
        onLinkPress={onLinkPress}
        testID="email-detection"
      />

      <Text style={styles.sectionTitle}>All Detection Types</Text>
      <HTMLText
        html='<p>Visit <a href="https://example.com">our site</a>, call 555-987-6543, or email info@test.com.</p>'
        style={styles.text}
        detectLinks
        detectPhoneNumbers
        detectEmails
        onLinkPress={onLinkPress}
        testID="all-detection"
      />

      <Text style={styles.sectionTitle}>XSS Security Test</Text>
      <HTMLText
        html='<p>Malicious: <a href="javascript:alert(1)">javascript link</a> should be blocked.</p>'
        style={styles.text}
        onLinkPress={onLinkPress}
        testID="xss-security-test"
      />

      <Text style={styles.sectionTitle}>Complex Content</Text>
      <HTMLText
        html={`
          <h2>Feature Overview</h2>
          <p>The <strong>HTMLText</strong> component supports:</p>
          <ul>
            <li><strong>Links</strong> - Tappable with callbacks</li>
            <li><em>Lists</em> - Ordered and unordered</li>
            <li>Custom <a href="https://styles.example">styling</a></li>
          </ul>
        `}
        style={styles.text}
        onLinkPress={onLinkPress}
        tagStyles={{
          h2: { color: '#333333', fontSize: 20 },
          a: { color: '#007AFF' },
        }}
        testID="complex-content"
      />

      <Text style={styles.sectionTitle}>Expand/Collapse</Text>
      <TouchableOpacity onPress={toggleExpanded} activeOpacity={0.7}>
        <HTMLText
          html="<p>This is a <strong>longer paragraph</strong> that demonstrates the <em>numberOfLines</em> feature. When collapsed, only 2 lines show. Tap to expand or collapse.</p>"
          style={styles.text}
          numberOfLines={expandedText ? 0 : 2}
          animationDuration={0.3}
          testID="expand-collapse-demo"
        />
        <Text style={styles.tapHint}>
          Tap to {expandedText ? 'collapse' : 'expand'}
        </Text>
      </TouchableOpacity>

      <Text style={styles.sectionTitle}>Dynamic numberOfLines</Text>
      <TouchableOpacity onPress={cycleNumberOfLines} activeOpacity={0.7}>
        <HTMLText
          html="<p>This example cycles through <strong>numberOfLines</strong> values: 1, 2, 3, unlimited. Each tap changes the limit with smooth animation.</p>"
          style={styles.text}
          numberOfLines={numberOfLinesDemo}
          animationDuration={0.2}
          testID="dynamic-lines-demo"
        />
        <Text style={styles.tapHint}>
          Lines: {numberOfLinesDemo === 0 ? 'unlimited' : numberOfLinesDemo}{' '}
          (tap)
        </Text>
      </TouchableOpacity>

      {/* RTL Support Examples */}
      <Text style={styles.rtlSectionHeader}>RTL Support</Text>

      <Text style={styles.sectionTitle}>Arabic Text</Text>
      <HTMLText
        html="<p>مرحباً بالعالم! هذا نص عربي يعرض من اليمين إلى اليسار.</p>"
        style={styles.text}
        testID="rtl-arabic"
      />

      <Text style={styles.sectionTitle}>Hebrew Text</Text>
      <HTMLText
        html="<p>שלום עולם! זהו טקסט בעברית המוצג מימין לשמאל.</p>"
        style={styles.text}
        testID="rtl-hebrew"
      />

      <Text style={styles.sectionTitle}>Persian Text</Text>
      <HTMLText
        html="<p>سلام دنیا! این یک متن فارسی است که از راست به چپ نمایش داده می‌شود.</p>"
        style={styles.text}
        testID="rtl-persian"
      />

      <Text style={styles.sectionTitle}>Mixed Directional Content</Text>
      <HTMLText
        html="<p>مرحباً Hello عالم World!</p>"
        style={styles.text}
        testID="rtl-mixed"
      />

      <Text style={styles.sectionTitle}>RTL with Embedded Numbers</Text>
      <HTMLText
        html="<p dir='rtl'>السعر: 123.45 دولار</p>"
        style={styles.text}
        testID="rtl-numbers"
      />

      <Text style={styles.sectionTitle}>BDI Isolation</Text>
      <HTMLText
        html="<p>User: <bdi>محمد</bdi> logged in at 10:30 AM</p>"
        style={styles.text}
        testID="rtl-bdi"
      />

      <Text style={styles.sectionTitle}>BDO Override (RTL)</Text>
      <HTMLText
        html="<p>Normal text, <bdo dir='rtl'>forced RTL</bdo>, back to normal</p>"
        style={styles.text}
        testID="rtl-bdo-rtl"
      />

      <Text style={styles.sectionTitle}>BDO Override (LTR)</Text>
      <HTMLText
        html="<p dir='rtl'>نص عربي، <bdo dir='ltr'>forced LTR</bdo>، عودة للعربي</p>"
        style={styles.text}
        testID="rtl-bdo-ltr"
      />

      <Text style={styles.sectionTitle}>Direction Attribute</Text>
      <HTMLText
        html="<p dir='rtl'>هذا فقرة باللغة العربية مع محاذاة صحيحة.</p>"
        style={styles.text}
        testID="rtl-dir-attr"
      />

      <Text style={styles.sectionTitle}>writingDirection Prop (RTL)</Text>
      <HTMLText
        html="<p>This English text is forced RTL via writingDirection prop.</p>"
        style={styles.text}
        writingDirection="rtl"
        testID="rtl-writing-direction"
      />

      <Text style={styles.sectionTitle}>RTL with Formatting</Text>
      <HTMLText
        html="<p dir='rtl'><strong>مهم:</strong> هذا نص <em>مائل</em> و<u>تحته خط</u>.</p>"
        style={styles.text}
        testID="rtl-formatting"
      />

      <Text style={styles.sectionTitle}>RTL with Links</Text>
      <HTMLText
        html='<p dir="rtl">زيارة <a href="https://example.com">موقعنا</a> للمزيد من المعلومات.</p>'
        style={styles.text}
        onLinkPress={onLinkPress}
        testID="rtl-links"
      />

      <Text style={styles.sectionTitle}>RTL Unordered List</Text>
      <HTMLText
        html="<ul dir='rtl'><li>العنصر الأول</li><li>العنصر الثاني</li><li>العنصر الثالث</li></ul>"
        style={styles.text}
        testID="rtl-ul"
      />

      <Text style={styles.sectionTitle}>RTL Ordered List</Text>
      <HTMLText
        html="<ol dir='rtl'><li>الخطوة الأولى</li><li>الخطوة الثانية</li><li>الخطوة الثالثة</li></ol>"
        style={styles.text}
        testID="rtl-ol"
      />
    </>
  );
}

function NativeWindExamples({
  onLinkPress,
  expandedText,
  toggleExpanded,
  numberOfLinesDemo,
  cycleNumberOfLines,
  colorScheme,
}: {
  onLinkPress: (url: string, type: DetectedContentType) => void;
  expandedText: boolean;
  toggleExpanded: () => void;
  numberOfLinesDemo: number;
  cycleNumberOfLines: () => void;
  colorScheme: string | null | undefined;
}): React.JSX.Element {
  return (
    <>
      <Text style={styles.sectionTitle}>Basic Formatting</Text>
      <NativeWindHTMLText
        html="<h1>Hello World</h1><p>This is <strong>bold</strong> and <em>italic</em> text.</p>"
        className="text-base leading-6"
        testID="nw-basic-formatting"
      />

      <Text style={styles.sectionTitle}>Links</Text>
      <NativeWindHTMLText
        html='<p>Visit <a href="https://example.com">Example.com</a> or <a href="https://react-native.dev">React Native Docs</a>.</p>'
        className="text-base leading-6"
        onLinkPress={onLinkPress}
        testID="nw-links-example"
      />

      <Text style={styles.sectionTitle}>Unordered List</Text>
      <NativeWindHTMLText
        html="<ul><li>First item</li><li>Second item</li><li>Third item</li></ul>"
        className="text-base leading-6"
        testID="nw-unordered-list"
      />

      <Text style={styles.sectionTitle}>Ordered List</Text>
      <NativeWindHTMLText
        html="<ol><li>Step one</li><li>Step two</li><li>Step three</li></ol>"
        className="text-base leading-6"
        testID="nw-ordered-list"
      />

      <Text style={styles.sectionTitle}>Nested Lists</Text>
      <NativeWindHTMLText
        html="<ul><li>Parent item<ul><li>Child item 1</li><li>Child item 2</li></ul></li><li>Another parent</li></ul>"
        className="text-base leading-6"
        testID="nw-nested-lists"
      />

      <Text style={styles.sectionTitle}>
        Custom Tag Styles (tagStyles prop)
      </Text>
      <NativeWindHTMLText
        html="<p>Normal text with <strong>custom red bold</strong> and <em>custom blue italic</em>.</p>"
        className="text-base leading-6"
        tagStyles={{
          strong: { color: '#CC0000' },
          em: { color: '#0066CC' },
        }}
        testID="nw-custom-tag-styles"
      />

      <Text style={styles.sectionTitle}>Native HTML Text Decoration</Text>
      <NativeWindHTMLText
        html="<p>Text with <u>underline tag</u> and <s>strikethrough tag</s> using native HTML.</p>"
        className="text-base leading-6"
        testID="nw-native-text-decoration"
      />

      <Text style={styles.sectionTitle}>Phone Detection</Text>
      <NativeWindHTMLText
        html="<p>Call us at 555-123-4567 for support.</p>"
        className="text-base leading-6"
        detectPhoneNumbers
        onLinkPress={onLinkPress}
        testID="nw-phone-detection"
      />

      <Text style={styles.sectionTitle}>Email Detection</Text>
      <NativeWindHTMLText
        html="<p>Contact support@example.com for help.</p>"
        className="text-base leading-6"
        detectEmails
        onLinkPress={onLinkPress}
        testID="nw-email-detection"
      />

      <Text style={styles.sectionTitle}>All Detection Types</Text>
      <NativeWindHTMLText
        html='<p>Visit <a href="https://example.com">our site</a>, call 555-987-6543, or email info@test.com.</p>'
        className="text-base leading-6"
        detectLinks
        detectPhoneNumbers
        detectEmails
        onLinkPress={onLinkPress}
        testID="nw-all-detection"
      />

      <Text style={styles.sectionTitle}>XSS Security Test</Text>
      <NativeWindHTMLText
        html='<p>Malicious: <a href="javascript:alert(1)">javascript link</a> should be blocked.</p>'
        className="text-base leading-6"
        onLinkPress={onLinkPress}
        testID="nw-xss-security-test"
      />

      <Text style={styles.sectionTitle}>Complex Content</Text>
      <NativeWindHTMLText
        html={`
          <h2>Feature Overview</h2>
          <p>The <strong>HTMLText</strong> component supports:</p>
          <ul>
            <li><strong>Links</strong> - Tappable with callbacks</li>
            <li><em>Lists</em> - Ordered and unordered</li>
            <li>Custom <a href="https://styles.example">styling</a></li>
          </ul>
        `}
        className="text-base leading-6"
        onLinkPress={onLinkPress}
        tagStyles={{
          h2: { color: '#333333', fontSize: 20 },
          a: { color: '#007AFF' },
        }}
        testID="nw-complex-content"
      />

      <Text style={styles.sectionTitle}>Expand/Collapse</Text>
      <TouchableOpacity onPress={toggleExpanded} activeOpacity={0.7}>
        <NativeWindHTMLText
          html="<p>This is a <strong>longer paragraph</strong> that demonstrates the <em>numberOfLines</em> feature. When collapsed, only 2 lines show. Tap to expand or collapse.</p>"
          className="text-base leading-6"
          numberOfLines={expandedText ? 0 : 2}
          animationDuration={0.3}
          testID="nw-expand-collapse-demo"
        />
        <Text style={styles.tapHint}>
          Tap to {expandedText ? 'collapse' : 'expand'}
        </Text>
      </TouchableOpacity>

      <Text style={styles.sectionTitle}>Dynamic numberOfLines</Text>
      <TouchableOpacity onPress={cycleNumberOfLines} activeOpacity={0.7}>
        <NativeWindHTMLText
          html="<p>This example cycles through <strong>numberOfLines</strong> values: 1, 2, 3, unlimited. Each tap changes the limit with smooth animation.</p>"
          className="text-base leading-6"
          numberOfLines={numberOfLinesDemo}
          animationDuration={0.2}
          testID="nw-dynamic-lines-demo"
        />
        <Text style={styles.tapHint}>
          Lines: {numberOfLinesDemo === 0 ? 'unlimited' : numberOfLinesDemo}{' '}
          (tap)
        </Text>
      </TouchableOpacity>

      <Text style={styles.nativeWindOnlyTitle}>NativeWind-Only Features</Text>

      <Text style={styles.sectionTitle}>Viewport Responsive Text</Text>
      <NativeWindHTMLText
        html="<p>This text scales based on <strong>viewport width</strong>: small on phones, medium on tablets, larger on desktop.</p>"
        className="text-sm md:text-base lg:text-lg leading-relaxed text-gray-700"
        testID="nw-responsive"
      />

      <Text style={styles.sectionTitle}>Container Query - Full Width</Text>
      <View className="@container w-full bg-slate-100 p-2 rounded-lg">
        <NativeWindHTMLText
          html="<p>Inside a <strong>full-width container</strong>. Text responds to container size, not viewport.</p>"
          className="text-sm @sm:text-base @md:text-lg @lg:text-xl leading-relaxed text-slate-700"
          testID="nw-container-full"
        />
      </View>

      <Text style={styles.sectionTitle}>Container Query - Half Width</Text>
      <View className="@container w-1/2 bg-amber-100 p-2 rounded-lg">
        <NativeWindHTMLText
          html="<p>Inside a <strong>half-width container</strong>. Same classes, different result!</p>"
          className="text-sm @sm:text-base @md:text-lg @lg:text-xl leading-relaxed text-amber-800"
          testID="nw-container-half"
        />
      </View>

      <Text style={styles.sectionTitle}>Container Query - Side by Side</Text>
      <View className="flex-row gap-2">
        <View className="@container flex-1 bg-emerald-100 p-2 rounded-lg">
          <NativeWindHTMLText
            html="<p><strong>Left</strong> container adapts independently.</p>"
            className="text-xs @sm:text-sm @md:text-base leading-snug text-emerald-800"
            testID="nw-container-left"
          />
        </View>
        <View className="@container flex-1 bg-violet-100 p-2 rounded-lg">
          <NativeWindHTMLText
            html="<p><strong>Right</strong> container adapts independently.</p>"
            className="text-xs @sm:text-sm @md:text-base leading-snug text-violet-800"
            testID="nw-container-right"
          />
        </View>
      </View>

      <Text style={styles.sectionTitle}>Container Query - Named</Text>
      <View className="@container/card w-full bg-rose-100 p-3 rounded-lg">
        <NativeWindHTMLText
          html="<p>This uses a <strong>named container</strong> (@container/card) for more precise targeting.</p>"
          className="text-sm @sm/card:text-base @md/card:text-lg leading-relaxed text-rose-800"
          testID="nw-container-named"
        />
      </View>

      <Text style={styles.sectionTitle}>Container Query - Nested</Text>
      <View className="@container bg-sky-100 p-3 rounded-lg">
        <NativeWindHTMLText
          html="<p><strong>Outer</strong> container text.</p>"
          className="text-sm @md:text-base leading-relaxed text-sky-800 mb-2"
          testID="nw-container-outer"
        />
        <View className="@container bg-sky-200 p-2 rounded">
          <NativeWindHTMLText
            html="<p><strong>Inner</strong> container responds to its own size.</p>"
            className="text-xs @sm:text-sm leading-snug text-sky-900"
            testID="nw-container-inner"
          />
        </View>
      </View>

      <Text style={styles.sectionTitle}>
        Dark Mode (current: {colorScheme ?? 'light'})
      </Text>
      <NativeWindHTMLText
        html="<p>This text adapts to <strong>dark mode</strong>. Toggle your system theme to see colors change.</p>"
        className="text-base leading-6 text-gray-900 dark:text-gray-100"
        testID="nw-dark-mode"
      />

      <Text style={styles.sectionTitle}>Color Utilities</Text>
      <NativeWindHTMLText
        html="<p><strong>Primary theme:</strong> Using Tailwind's color palette for consistent styling.</p>"
        className="text-base leading-6 text-blue-600 bg-blue-50 p-3 rounded-lg"
        testID="nw-colors"
      />

      <Text style={styles.sectionTitle}>Spacing Utilities</Text>
      <NativeWindHTMLText
        html="<p>This text has <em>padding</em> and <strong>margin</strong> via Tailwind classes.</p>"
        className="text-base leading-6 text-gray-800 p-4 m-2 bg-amber-100 rounded"
        testID="nw-spacing"
      />

      <Text style={styles.sectionTitle}>Typography Variants</Text>
      <NativeWindHTMLText
        html="<p>Large, bold, indigo text with tracking.</p>"
        className="text-xl font-bold text-indigo-600 tracking-wide"
        testID="nw-typography"
      />

      {/* RTL Support Examples */}
      <Text style={styles.rtlSectionHeader}>RTL Support</Text>

      <Text style={styles.sectionTitle}>Arabic Text</Text>
      <NativeWindHTMLText
        html="<p>مرحباً بالعالم! هذا نص عربي يعرض من اليمين إلى اليسار.</p>"
        className="text-base leading-6"
        testID="nw-rtl-arabic"
      />

      <Text style={styles.sectionTitle}>Hebrew Text</Text>
      <NativeWindHTMLText
        html="<p>שלום עולם! זהו טקסט בעברית המוצג מימין לשמאל.</p>"
        className="text-base leading-6"
        testID="nw-rtl-hebrew"
      />

      <Text style={styles.sectionTitle}>Persian Text</Text>
      <NativeWindHTMLText
        html="<p>سلام دنیا! این یک متن فارسی است که از راست به چپ نمایش داده می‌شود.</p>"
        className="text-base leading-6"
        testID="nw-rtl-persian"
      />

      <Text style={styles.sectionTitle}>Mixed Directional Content</Text>
      <NativeWindHTMLText
        html="<p>مرحباً Hello عالم World!</p>"
        className="text-base leading-6"
        testID="nw-rtl-mixed"
      />

      <Text style={styles.sectionTitle}>RTL with Embedded Numbers</Text>
      <NativeWindHTMLText
        html="<p dir='rtl'>السعر: 123.45 دولار</p>"
        className="text-base leading-6"
        testID="nw-rtl-numbers"
      />

      <Text style={styles.sectionTitle}>BDI Isolation</Text>
      <NativeWindHTMLText
        html="<p>User: <bdi>محمد</bdi> logged in at 10:30 AM</p>"
        className="text-base leading-6"
        testID="nw-rtl-bdi"
      />

      <Text style={styles.sectionTitle}>BDO Override (RTL)</Text>
      <NativeWindHTMLText
        html="<p>Normal text, <bdo dir='rtl'>forced RTL</bdo>, back to normal</p>"
        className="text-base leading-6"
        testID="nw-rtl-bdo-rtl"
      />

      <Text style={styles.sectionTitle}>BDO Override (LTR)</Text>
      <NativeWindHTMLText
        html="<p dir='rtl'>نص عربي، <bdo dir='ltr'>forced LTR</bdo>، عودة للعربي</p>"
        className="text-base leading-6"
        testID="nw-rtl-bdo-ltr"
      />

      <Text style={styles.sectionTitle}>Direction Attribute</Text>
      <NativeWindHTMLText
        html="<p dir='rtl'>هذا فقرة باللغة العربية مع محاذاة صحيحة.</p>"
        className="text-base leading-6"
        testID="nw-rtl-dir-attr"
      />

      <Text style={styles.sectionTitle}>writingDirection Prop (RTL)</Text>
      <NativeWindHTMLText
        html="<p>This English text is forced RTL via writingDirection prop.</p>"
        className="text-base leading-6"
        writingDirection="rtl"
        testID="nw-rtl-writing-direction"
      />

      <Text style={styles.sectionTitle}>RTL with Formatting</Text>
      <NativeWindHTMLText
        html="<p dir='rtl'><strong>مهم:</strong> هذا نص <em>مائل</em> و<u>تحته خط</u>.</p>"
        className="text-base leading-6"
        testID="nw-rtl-formatting"
      />

      <Text style={styles.sectionTitle}>RTL with Links</Text>
      <NativeWindHTMLText
        html='<p dir="rtl">زيارة <a href="https://example.com">موقعنا</a> للمزيد من المعلومات.</p>'
        className="text-base leading-6"
        onLinkPress={onLinkPress}
        testID="nw-rtl-links"
      />

      <Text style={styles.sectionTitle}>RTL Unordered List</Text>
      <NativeWindHTMLText
        html="<ul dir='rtl'><li>العنصر الأول</li><li>العنصر الثاني</li><li>العنصر الثالث</li></ul>"
        className="text-base leading-6"
        testID="nw-rtl-ul"
      />

      <Text style={styles.sectionTitle}>RTL Ordered List</Text>
      <NativeWindHTMLText
        html="<ol dir='rtl'><li>الخطوة الأولى</li><li>الخطوة الثانية</li><li>الخطوة الثالثة</li></ol>"
        className="text-base leading-6"
        testID="nw-rtl-ol"
      />
    </>
  );
}

export default function App(): React.JSX.Element {
  const [stylingMode, setStylingMode] = useState<StylingMode>('stylesheet');
  const [lastLinkPressed, setLastLinkPressed] = useState<string | null>(null);
  const [expandedText, setExpandedText] = useState(false);
  const [numberOfLinesDemo, setNumberOfLinesDemo] = useState(2);
  const colorScheme = useColorScheme();

  const handleLinkPress = useCallback(
    (url: string, type: DetectedContentType) => {
      setLastLinkPressed(`${url} (${type})`);
      Alert.alert('Link Pressed', `URL: ${url}\nType: ${type}`);
    },
    []
  );

  const toggleExpanded = useCallback(() => {
    setExpandedText((prev) => !prev);
  }, []);

  const cycleNumberOfLines = useCallback(() => {
    setNumberOfLinesDemo((prev) => {
      if (prev === 0) return 1;
      if (prev === 1) return 2;
      if (prev === 2) return 3;
      return 0;
    });
  }, []);

  return (
    <View style={styles.root}>
      <View style={styles.header}>
        <Text style={styles.title}>HTMLText Examples</Text>
        <SegmentedControl value={stylingMode} onChange={setStylingMode} />
        {lastLinkPressed && (
          <Text style={styles.linkStatus}>Last link: {lastLinkPressed}</Text>
        )}
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.container}
      >
        {stylingMode === 'stylesheet' ? (
          <StyleSheetExamples
            onLinkPress={handleLinkPress}
            expandedText={expandedText}
            toggleExpanded={toggleExpanded}
            numberOfLinesDemo={numberOfLinesDemo}
            cycleNumberOfLines={cycleNumberOfLines}
          />
        ) : (
          <NativeWindExamples
            onLinkPress={handleLinkPress}
            expandedText={expandedText}
            toggleExpanded={toggleExpanded}
            numberOfLinesDemo={numberOfLinesDemo}
            cycleNumberOfLines={cycleNumberOfLines}
            colorScheme={colorScheme}
          />
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  header: {
    paddingTop: 60,
    paddingHorizontal: 16,
    paddingBottom: 12,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E5E5',
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: '#000000',
    textAlign: 'center',
    marginBottom: 12,
  },
  segmentedControl: {
    flexDirection: 'row',
    backgroundColor: '#F0F0F0',
    borderRadius: 8,
    padding: 2,
  },
  segment: {
    flex: 1,
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 6,
    alignItems: 'center',
  },
  segmentActive: {
    backgroundColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  segmentText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#666666',
  },
  segmentTextActive: {
    color: '#007AFF',
  },
  scrollView: {
    flex: 1,
  },
  container: {
    padding: 16,
    paddingBottom: 40,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#666666',
    marginTop: 24,
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  nativeWindOnlyTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: '#0066CC',
    marginTop: 32,
    marginBottom: 4,
    textAlign: 'center',
  },
  rtlSectionHeader: {
    fontSize: 16,
    fontWeight: '700',
    color: '#00AA66',
    marginTop: 32,
    marginBottom: 4,
    textAlign: 'center',
  },
  text: {
    fontSize: 16,
    lineHeight: 24,
  },
  linkStatus: {
    fontSize: 12,
    color: '#888888',
    marginTop: 8,
    fontStyle: 'italic',
    textAlign: 'center',
  },
  tapHint: {
    fontSize: 12,
    color: '#007AFF',
    marginTop: 4,
    fontStyle: 'italic',
  },
});
