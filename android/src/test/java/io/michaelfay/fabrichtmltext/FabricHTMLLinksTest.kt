package io.michaelfay.fabrichtmltext

import android.text.style.ClickableSpan
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.text.style.UnderlineSpan
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class HTMLLinksTest {

    private lateinit var builder: FabricHtmlSpannableBuilder

    @Before
    fun setUp() {
        builder = FabricHtmlSpannableBuilder()
    }

    // MARK: - Link Parsing Tests (FR-001)

    @Test
    fun `link tag parses href and creates ClickableSpan`() {
        val html = "<a href=\"https://example.com\">Click here</a>"
        val result = builder.buildSpannable(html)

        assertEquals("Click here", result.toString())

        val spans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertTrue("Should have at least one ClickableSpan", spans.isNotEmpty())
    }

    @Test
    fun `link tag applies underline`() {
        val html = "<a href=\"https://example.com\">Underlined</a>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, UnderlineSpan::class.java)
        assertTrue("Should have UnderlineSpan", spans.isNotEmpty())
    }

    @Test
    fun `link tag applies link color`() {
        val html = "<a href=\"https://example.com\">Blue link</a>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, ForegroundColorSpan::class.java)
        assertTrue("Should have ForegroundColorSpan for link color", spans.isNotEmpty())
    }

    // MARK: - Link URL Types (FR-002)

    @Test
    fun `link tag with relative URL`() {
        val html = "<a href=\"/path/to/page\">Relative</a>"
        val result = builder.buildSpannable(html)

        assertEquals("Relative", result.toString())

        val spans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertTrue("Should have ClickableSpan for relative URL", spans.isNotEmpty())
    }

    @Test
    fun `link tag with anchor fragment`() {
        val html = "<a href=\"#section\">Jump</a>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertTrue("Should have ClickableSpan for anchor fragment", spans.isNotEmpty())
    }

    @Test
    fun `link tag with mailto URL`() {
        val html = "<a href=\"mailto:test@example.com\">Email</a>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertTrue("Should have ClickableSpan for mailto URL", spans.isNotEmpty())
    }

    // MARK: - Empty/Invalid Link Tests (Edge Cases)

    @Test
    fun `link tag with empty href renders as plain text`() {
        val html = "<a href=\"\">No link</a>"
        val result = builder.buildSpannable(html)

        assertEquals("No link", result.toString())

        val spans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertTrue("Empty href should not create ClickableSpan", spans.isEmpty())

        val underlineSpans = result.getSpans(0, result.length, UnderlineSpan::class.java)
        assertTrue("Empty href should not have underline", underlineSpans.isEmpty())
    }

    @Test
    fun `link tag with no href renders as plain text`() {
        val html = "<a>No href attribute</a>"
        val result = builder.buildSpannable(html)

        assertEquals("No href attribute", result.toString())

        val spans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertTrue("Missing href should not create ClickableSpan", spans.isEmpty())
    }

    // MARK: - Nested Formatting in Links

    @Test
    fun `link tag with bold text`() {
        val html = "<a href=\"https://example.com\"><strong>Bold link</strong></a>"
        val result = builder.buildSpannable(html)

        assertEquals("Bold link", result.toString())

        val linkSpans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertTrue("Should have ClickableSpan", linkSpans.isNotEmpty())

        val styleSpans = result.getSpans(0, result.length, StyleSpan::class.java)
        assertTrue("Should have bold style", styleSpans.any { it.style == android.graphics.Typeface.BOLD })
    }

    @Test
    fun `link tag with italic text`() {
        val html = "<a href=\"https://example.com\"><em>Italic link</em></a>"
        val result = builder.buildSpannable(html)

        val linkSpans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertTrue("Should have ClickableSpan", linkSpans.isNotEmpty())

        val styleSpans = result.getSpans(0, result.length, StyleSpan::class.java)
        assertTrue("Should have italic style", styleSpans.any { it.style == android.graphics.Typeface.ITALIC })
    }

    // MARK: - Multiple Links

    @Test
    fun `multiple links in same paragraph`() {
        val html = "Visit <a href=\"https://a.com\">A</a> or <a href=\"https://b.com\">B</a>"
        val result = builder.buildSpannable(html)

        assertEquals("Visit A or B", result.toString())

        val spans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertEquals("Should have two ClickableSpans", 2, spans.size)
    }

    // MARK: - Link Click Handler Tests

    @Test
    fun `link stores href for click handling`() {
        val html = "<a href=\"https://example.com\">Click me</a>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertTrue("Should have ClickableSpan", spans.isNotEmpty())

        val linkSpan = spans.first()
        assertTrue("Should be HrefClickableSpan", linkSpan is HrefClickableSpan)

        val hrefSpan = linkSpan as HrefClickableSpan
        assertEquals("Should store href", "https://example.com", hrefSpan.href)
    }

    // MARK: - Accessibility Tests

    @Test
    fun `link is accessible via spans`() {
        val html = "<a href=\"https://example.com\">Accessible link</a>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertTrue("Link should be present via ClickableSpan for accessibility", spans.isNotEmpty())
    }
}
