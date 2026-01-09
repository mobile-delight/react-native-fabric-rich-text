package io.michaelfay.fabricrichtext

import android.graphics.Typeface
import android.text.Spanned
import android.text.style.AbsoluteSizeSpan
import android.text.style.StyleSpan
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * Unit tests for FabricRichTextView.
 *
 * Verifies that the view correctly integrates sanitizer and builder
 * to render HTML as styled text.
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class FabricRichTextViewTest {

    private lateinit var view: FabricRichTextView

    @Before
    fun setUp() {
        view = FabricRichTextView(RuntimeEnvironment.getApplication())
    }

    // ========== Basic Rendering ==========

    @Test
    fun `setHtml renders plain text`() {
        view.setHtml("Hello World")

        assertEquals("Hello World", view.text.toString())
    }

    @Test
    fun `setHtml renders bold text`() {
        view.setHtml("<strong>Bold</strong>")

        assertEquals("Bold", view.text.toString())

        val spannable = view.text as Spanned
        val spans = spannable.getSpans(0, spannable.length, StyleSpan::class.java)
        assertTrue("Should have bold style", spans.any { it.style == Typeface.BOLD })
    }

    @Test
    fun `setHtml renders italic text`() {
        view.setHtml("<em>Italic</em>")

        assertEquals("Italic", view.text.toString())

        val spannable = view.text as Spanned
        val spans = spannable.getSpans(0, spannable.length, StyleSpan::class.java)
        assertTrue("Should have italic style", spans.any { it.style == Typeface.ITALIC })
    }

    @Test
    fun `setHtml renders heading with size`() {
        view.setHtml("<h1>Title</h1>")

        assertTrue(view.text.toString().contains("Title"))

        val spannable = view.text as Spanned
        val sizeSpans = spannable.getSpans(0, spannable.length, AbsoluteSizeSpan::class.java)
        assertTrue("H1 should have size span", sizeSpans.isNotEmpty())
        // H1 scale is 2.0, default base font is 14sp, so absolute size = 28sp
        assertEquals("H1 should be 28sp", 28, sizeSpans[0].size)
    }

    // ========== Null/Empty Input ==========

    @Test
    fun `setHtml handles null input`() {
        view.setHtml(null)

        assertEquals("", view.text.toString())
    }

    @Test
    fun `setHtml handles empty string`() {
        view.setHtml("")

        assertEquals("", view.text.toString())
    }

    @Test
    fun `setHtml handles whitespace only`() {
        view.setHtml("   ")

        assertTrue(view.text.toString().isBlank())
    }

    // ========== Security Integration ==========

    @Test
    fun `setHtml sanitizes script tags`() {
        view.setHtml("<p>Safe<script>alert(1)</script></p>")

        val text = view.text.toString()
        assertTrue("Should contain Safe", text.contains("Safe"))
        assertFalse("Should not contain script content", text.contains("alert"))
    }

    @Test
    fun `setHtml renders text content from elements with event handlers`() {
        view.setHtml("<div onclick=\"alert(1)\">Click me</div>")

        val text = view.text.toString()
        assertEquals("Click me", text)
    }

    @Test
    fun `setHtml removes javascript URL spans`() {
        view.setHtml("<a href=\"javascript:alert(1)\">Link</a>")

        val text = view.text.toString()
        assertTrue("Should render link text", text.contains("Link"))

        // Verify no URLSpan references javascript: protocol
        val spanned = view.text as? android.text.Spanned
        if (spanned != null) {
            val urlSpans = spanned.getSpans(0, spanned.length, android.text.style.URLSpan::class.java)
            assertTrue("Should have no javascript: URLs in spans", urlSpans.none {
                it.url.lowercase().startsWith("javascript:")
            })
        }
        // If text is not Spanned, there are no spans to check - test passes
    }

    @Test
    fun `setHtml removes iframe tags`() {
        view.setHtml("<p>Before</p><iframe src=\"evil.com\"></iframe><p>After</p>")

        val text = view.text.toString()
        assertTrue("Should contain Before", text.contains("Before"))
        assertTrue("Should contain After", text.contains("After"))
        assertFalse("Should not contain iframe", text.contains("iframe"))
    }

    // ========== Complex Content ==========

    @Test
    fun `setHtml renders nested formatting`() {
        view.setHtml("<p><strong><em>Bold and italic</em></strong></p>")

        val text = view.text.toString()
        assertTrue(text.contains("Bold and italic"))

        val spannable = view.text as Spanned
        val spans = spannable.getSpans(0, spannable.length, StyleSpan::class.java)
        assertTrue("Should have bold", spans.any { it.style == Typeface.BOLD })
        assertTrue("Should have italic", spans.any { it.style == Typeface.ITALIC })
    }

    @Test
    fun `setHtml renders multiple paragraphs`() {
        view.setHtml("<p>First</p><p>Second</p>")

        val text = view.text.toString()
        assertTrue(text.contains("First"))
        assertTrue(text.contains("Second"))
        assertTrue("Should have paragraph separation", text.contains("\n"))
    }

    @Test
    fun `setHtml preserves safe anchor tags`() {
        view.setHtml("<a href=\"https://example.com\">Link</a>")

        val text = view.text.toString()
        assertTrue("Should contain link text", text.contains("Link"))
    }

    // ========== Updating Content ==========

    @Test
    fun `setHtml can update content multiple times`() {
        view.setHtml("<p>First content</p>")
        assertEquals("First content", view.text.toString().trim())

        view.setHtml("<p>Second content</p>")
        assertEquals("Second content", view.text.toString().trim())

        view.setHtml("<strong>Third</strong>")
        assertEquals("Third", view.text.toString())
    }

    @Test
    fun `setHtml clears previous formatting on update`() {
        view.setHtml("<strong>Bold</strong>")

        val firstSpannable = view.text as Spanned
        val firstSpans = firstSpannable.getSpans(0, firstSpannable.length, StyleSpan::class.java)
        assertTrue(firstSpans.any { it.style == Typeface.BOLD })

        view.setHtml("Plain text")

        val secondSpannable = view.text as Spanned
        val secondSpans = secondSpannable.getSpans(0, secondSpannable.length, StyleSpan::class.java)
        assertTrue("Should have no bold spans after plain text", secondSpans.none { it.style == Typeface.BOLD })
    }

    // ========== Performance ==========

    @Test
    fun `setHtml renders typical content within performance budget`() {
        val html = """<p>Museum <strong>exhibit</strong> description with <a href="https://example.com">link</a>.</p>"""

        val startTime = System.nanoTime()
        repeat(100) {
            view.setHtml(html)
        }
        val endTime = System.nanoTime()

        val averageMs = (endTime - startTime) / 100 / 1_000_000.0
        assertTrue("Average setHtml time should be < 16ms, was ${averageMs}ms", averageMs < 16)
    }
}
