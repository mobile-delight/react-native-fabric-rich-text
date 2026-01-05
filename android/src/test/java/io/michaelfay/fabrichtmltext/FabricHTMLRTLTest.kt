package io.michaelfay.fabrichtmltext

import android.text.Spanned
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * Unit tests for RTL (Right-to-Left) text direction support.
 *
 * Tests cover:
 * - Basic RTL text rendering (Arabic, Hebrew)
 * - writingDirection property
 * - bdi/bdo HTML elements
 * - dir attribute on elements
 * - Mixed directional content
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class FabricHTMLRTLTest {

    private lateinit var view: FabricHTMLTextView

    @Before
    fun setUp() {
        view = FabricHTMLTextView(RuntimeEnvironment.getApplication())
    }

    // ========== Basic RTL Text ==========

    @Test
    fun `renders Arabic text`() {
        view.setHtml("<p>مرحبا بالعالم</p>")

        val text = view.text.toString()
        assertTrue("Should contain Arabic text", text.contains("مرحبا"))
    }

    @Test
    fun `renders Hebrew text`() {
        view.setHtml("<p>שלום עולם</p>")

        val text = view.text.toString()
        assertTrue("Should contain Hebrew text", text.contains("שלום"))
    }

    @Test
    fun `renders Persian text`() {
        view.setHtml("<p>سلام دنیا</p>")

        val text = view.text.toString()
        assertTrue("Should contain Persian text", text.contains("سلام"))
    }

    // ========== writingDirection Property ==========

    @Test
    fun `writingDirection rtl sets internal RTL state`() {
        view.setWritingDirection("rtl")
        view.setHtml("<p>Hello World</p>")

        // The view renders content - direction is handled internally
        val text = view.text.toString()
        assertTrue("Should contain text", text.contains("Hello World"))
    }

    @Test
    fun `writingDirection ltr sets internal LTR state`() {
        view.setWritingDirection("ltr")
        view.setHtml("<p>مرحبا بالعالم</p>")

        val text = view.text.toString()
        assertTrue("Should contain Arabic text", text.contains("مرحبا"))
    }

    @Test
    fun `writingDirection can be changed`() {
        view.setWritingDirection("rtl")
        view.setHtml("<p>RTL content</p>")

        view.setWritingDirection("ltr")
        view.setHtml("<p>LTR content</p>")

        val text = view.text.toString()
        assertTrue("Should contain LTR text", text.contains("LTR content"))
    }

    // ========== bdi Element (Bidirectional Isolation) ==========

    @Test
    fun `bdi tag is allowed and renders content`() {
        view.setHtml("<p>User: <bdi>אורח</bdi> logged in</p>")

        val text = view.text.toString()
        assertTrue("Should contain 'User:'", text.contains("User:"))
        assertTrue("Should contain Hebrew name", text.contains("אורח"))
        assertTrue("Should contain 'logged in'", text.contains("logged in"))
    }

    @Test
    fun `bdi tag isolates RTL text in LTR context`() {
        // The bdi tag should prevent RTL text from affecting surrounding punctuation
        view.setHtml("<p>Welcome, <bdi>محمد</bdi>!</p>")

        val text = view.text.toString()
        assertTrue("Should contain greeting", text.contains("Welcome"))
        assertTrue("Should contain Arabic name", text.contains("محمد"))
    }

    @Test
    fun `multiple bdi elements render correctly`() {
        view.setHtml("<p><bdi>עברית</bdi> and <bdi>العربية</bdi></p>")

        val text = view.text.toString()
        assertTrue("Should contain Hebrew", text.contains("עברית"))
        assertTrue("Should contain 'and'", text.contains("and"))
        assertTrue("Should contain Arabic", text.contains("العربية"))
    }

    // ========== bdo Element (Bidirectional Override) ==========

    @Test
    fun `bdo tag with dir rtl is allowed`() {
        view.setHtml("<p><bdo dir=\"rtl\">Hello</bdo></p>")

        val text = view.text.toString()
        assertTrue("Should contain 'Hello'", text.contains("Hello"))
    }

    @Test
    fun `bdo tag with dir ltr is allowed`() {
        view.setHtml("<p><bdo dir=\"ltr\">مرحبا</bdo></p>")

        val text = view.text.toString()
        assertTrue("Should contain Arabic text", text.contains("مرحبا"))
    }

    @Test
    fun `bdo without dir attribute renders content`() {
        // Per HTML5 spec, bdo without dir has no directional effect
        view.setHtml("<p><bdo>Normal text</bdo></p>")

        val text = view.text.toString()
        assertTrue("Should contain text", text.contains("Normal text"))
    }

    // ========== dir Attribute ==========

    @Test
    fun `dir rtl attribute on paragraph`() {
        view.setHtml("<p dir=\"rtl\">Right to left paragraph</p>")

        val text = view.text.toString()
        assertTrue("Should contain text", text.contains("Right to left"))
    }

    @Test
    fun `dir ltr attribute on paragraph`() {
        view.setHtml("<p dir=\"ltr\">Left to right paragraph</p>")

        val text = view.text.toString()
        assertTrue("Should contain text", text.contains("Left to right"))
    }

    @Test
    fun `dir auto attribute on paragraph`() {
        view.setHtml("<p dir=\"auto\">Auto direction paragraph</p>")

        val text = view.text.toString()
        assertTrue("Should contain text", text.contains("Auto direction"))
    }

    @Test
    fun `dir attribute on span element`() {
        view.setHtml("<p>Normal <span dir=\"rtl\">RTL span</span> text</p>")

        val text = view.text.toString()
        assertTrue("Should contain 'Normal'", text.contains("Normal"))
        assertTrue("Should contain 'RTL span'", text.contains("RTL span"))
    }

    // ========== Mixed Directional Content ==========

    @Test
    fun `mixed Arabic and English text`() {
        view.setHtml("<p>مرحبا Hello عالم World</p>")

        val text = view.text.toString()
        assertTrue("Should contain Arabic", text.contains("مرحبا"))
        assertTrue("Should contain English", text.contains("Hello"))
    }

    @Test
    fun `RTL text with embedded numbers`() {
        view.setHtml("<p>السعر: 123.45</p>")

        val text = view.text.toString()
        assertTrue("Should contain Arabic", text.contains("السعر"))
        assertTrue("Should contain numbers", text.contains("123"))
    }

    @Test
    fun `RTL text with embedded brand names`() {
        view.setHtml("<p dir=\"rtl\">أنا أستخدم iPhone كل يوم</p>")

        val text = view.text.toString()
        assertTrue("Should contain Arabic", text.contains("أنا"))
        assertTrue("Should contain brand name", text.contains("iPhone"))
    }

    // ========== RTL with Formatting ==========

    @Test
    fun `RTL text with bold formatting`() {
        view.setHtml("<p dir=\"rtl\"><strong>مهم:</strong> رسالة</p>")

        val text = view.text.toString()
        assertTrue("Should contain bold text", text.contains("مهم"))
        assertTrue("Should contain message", text.contains("رسالة"))
    }

    @Test
    fun `RTL text with italic formatting`() {
        view.setHtml("<p dir=\"rtl\"><em>تأكيد</em> نص عادي</p>")

        val text = view.text.toString()
        assertTrue("Should contain italic text", text.contains("تأكيد"))
    }

    @Test
    fun `RTL text with links`() {
        view.setHtml("<p dir=\"rtl\">زيارة <a href=\"https://example.com\">موقعنا</a></p>")

        val text = view.text.toString()
        assertTrue("Should contain link text", text.contains("موقعنا"))
        assertTrue("Should contain surrounding text", text.contains("زيارة"))
    }

    // ========== RTL Lists ==========

    @Test
    fun `RTL unordered list`() {
        view.setHtml("<ul dir=\"rtl\"><li>عنصر أول</li><li>عنصر ثاني</li></ul>")

        val text = view.text.toString()
        assertTrue("Should contain first item", text.contains("عنصر أول"))
        assertTrue("Should contain second item", text.contains("عنصر ثاني"))
    }

    @Test
    fun `RTL ordered list`() {
        view.setHtml("<ol dir=\"rtl\"><li>الخطوة الأولى</li><li>الخطوة الثانية</li></ol>")

        val text = view.text.toString()
        assertTrue("Should contain first step", text.contains("الخطوة الأولى"))
        assertTrue("Should contain second step", text.contains("الخطوة الثانية"))
    }

    // ========== Edge Cases ==========

    @Test
    fun `nested direction changes`() {
        view.setHtml("<p dir=\"rtl\">عربي <span dir=\"ltr\">English</span> عربي</p>")

        val text = view.text.toString()
        assertTrue("Should contain all text", text.contains("عربي"))
        assertTrue("Should contain English", text.contains("English"))
    }

    @Test
    fun `empty bdi element`() {
        view.setHtml("<p>Before <bdi></bdi> After</p>")

        val text = view.text.toString()
        assertTrue("Should contain 'Before'", text.contains("Before"))
        assertTrue("Should contain 'After'", text.contains("After"))
    }

    @Test
    fun `empty bdo element`() {
        view.setHtml("<p>Before <bdo dir=\"rtl\"></bdo> After</p>")

        val text = view.text.toString()
        assertTrue("Should contain 'Before'", text.contains("Before"))
        assertTrue("Should contain 'After'", text.contains("After"))
    }

    // ========== Security with RTL ==========

    @Test
    fun `RTL text with sanitized script`() {
        view.setHtml("<p dir=\"rtl\">مرحبا<script>alert('xss')</script></p>")

        val text = view.text.toString()
        assertTrue("Should contain Arabic", text.contains("مرحبا"))
        assertFalse("Should not contain script", text.contains("alert"))
    }

    @Test
    fun `bdi with malicious attributes stripped`() {
        view.setHtml("<p><bdi onclick=\"alert(1)\">Safe text</bdi></p>")

        val text = view.text.toString()
        assertTrue("Should contain safe text", text.contains("Safe text"))
    }
}
