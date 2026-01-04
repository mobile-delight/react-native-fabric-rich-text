package io.michaelfay.fabrichtmltext

import android.graphics.Typeface
import android.text.style.AbsoluteSizeSpan
import android.text.style.StyleSpan
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class FabricHtmlSpannableBuilderTest {

    private lateinit var builder: FabricHtmlSpannableBuilder

    companion object {
        // Default base font size matching FabricHtmlSpannableBuilder.DEFAULT_FONT_SIZE
        private const val DEFAULT_FONT_SIZE = 14f
    }

    @Before
    fun setUp() {
        builder = FabricHtmlSpannableBuilder()
    }

    // MARK: - Bold Text Tests (Scenario 1.1)

    @Test
    fun `bold text applies StyleSpan BOLD`() {
        val html = "<strong>Bold text</strong>"
        val result = builder.buildSpannable(html)

        assertEquals("Bold text", result.toString())

        val spans = result.getSpans(0, result.length, StyleSpan::class.java)
        assertTrue("Should have at least one StyleSpan", spans.isNotEmpty())
        assertTrue("Should have BOLD style", spans.any { it.style == Typeface.BOLD })
    }

    @Test
    fun `b tag applies StyleSpan BOLD`() {
        val html = "<b>Bold text</b>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, StyleSpan::class.java)
        assertTrue("Should have BOLD style for <b> tag", spans.any { it.style == Typeface.BOLD })
    }

    // MARK: - Italic Text Tests (Scenario 1.2)

    @Test
    fun `italic text applies StyleSpan ITALIC`() {
        val html = "<em>Italic text</em>"
        val result = builder.buildSpannable(html)

        assertEquals("Italic text", result.toString())

        val spans = result.getSpans(0, result.length, StyleSpan::class.java)
        assertTrue("Should have at least one StyleSpan", spans.isNotEmpty())
        assertTrue("Should have ITALIC style", spans.any { it.style == Typeface.ITALIC })
    }

    @Test
    fun `i tag applies StyleSpan ITALIC`() {
        val html = "<i>Italic text</i>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, StyleSpan::class.java)
        assertTrue("Should have ITALIC style for <i> tag", spans.any { it.style == Typeface.ITALIC })
    }

    // MARK: - Combined Bold and Italic Tests (Scenario 1.3)

    @Test
    fun `combined bold and italic applies both styles`() {
        val html = "<strong><em>Bold italic</em></strong>"
        val result = builder.buildSpannable(html)

        assertEquals("Bold italic", result.toString())

        val spans = result.getSpans(0, result.length, StyleSpan::class.java)
        assertTrue("Should have BOLD style", spans.any { it.style == Typeface.BOLD })
        assertTrue("Should have ITALIC style", spans.any { it.style == Typeface.ITALIC })
    }

    @Test
    fun `nested bold in italic applies both styles`() {
        val html = "<em><strong>Bold in italic</strong></em>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, StyleSpan::class.java)
        assertTrue("Should have BOLD style", spans.any { it.style == Typeface.BOLD })
        assertTrue("Should have ITALIC style", spans.any { it.style == Typeface.ITALIC })
    }

    @Test
    fun `double bold produces single bold span no stacking`() {
        val html = "<strong><strong>double bold</strong></strong>"
        val result = builder.buildSpannable(html)

        assertEquals("double bold", result.toString())

        val spans = result.getSpans(0, result.length, StyleSpan::class.java)
        val boldSpans = spans.filter { it.style == Typeface.BOLD }
        assertTrue("Should have bold spans", boldSpans.isNotEmpty())
    }

    // MARK: - Paragraph Spacing Tests (Scenario 2.1)

    @Test
    fun `multiple paragraphs have spacing`() {
        val html = "<p>First paragraph</p><p>Second paragraph</p>"
        val result = builder.buildSpannable(html)

        assertTrue("Should contain First paragraph", result.toString().contains("First paragraph"))
        assertTrue("Should contain Second paragraph", result.toString().contains("Second paragraph"))
        assertTrue("Should have newline separator", result.toString().contains("\n"))
    }

    // MARK: - Heading Size Tests (Scenario 3.1, 3.2)

    @Test
    fun `heading sizes use correct AbsoluteSizeSpan`() {
        // Heading scales used to calculate absolute sizes
        val headingScales = mapOf(
            "h1" to 2.0f,
            "h2" to 1.5f,
            "h3" to 1.17f,
            "h4" to 1.0f,
            "h5" to 0.83f,
            "h6" to 0.67f
        )

        for ((tag, scale) in headingScales) {
            val html = "<$tag>Heading</$tag>"
            val result = builder.buildSpannable(html)

            val spans = result.getSpans(0, result.length, AbsoluteSizeSpan::class.java)
            assertTrue("$tag should have AbsoluteSizeSpan", spans.isNotEmpty())

            // AbsoluteSizeSpan size is baseFontSize * scale (in SP)
            val expectedSize = (DEFAULT_FONT_SIZE * scale).toInt()
            assertEquals("$tag should have size $expectedSize sp", expectedSize, spans[0].size)
            assertTrue("$tag size should be in dp (dip=true)", spans[0].dip)
        }
    }

    @Test
    fun `h1 has absolute size 28sp`() {
        val html = "<h1>Title</h1>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, AbsoluteSizeSpan::class.java)
        assertTrue("H1 should have AbsoluteSizeSpan", spans.isNotEmpty())
        // H1 scale is 2.0, so size = 14 * 2.0 = 28
        assertEquals("H1 should be 28sp", 28, spans[0].size)
    }

    @Test
    fun `h2 has absolute size 21sp`() {
        val html = "<h2>Subtitle</h2>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, AbsoluteSizeSpan::class.java)
        assertTrue("H2 should have AbsoluteSizeSpan", spans.isNotEmpty())
        // H2 scale is 1.5, so size = 14 * 1.5 = 21
        assertEquals("H2 should be 21sp", 21, spans[0].size)
    }

    @Test
    fun `headings are bold`() {
        val html = "<h1>Bold heading</h1>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, StyleSpan::class.java)
        assertTrue("Heading should have bold style", spans.any { it.style == Typeface.BOLD })
    }

    // MARK: - Empty/Null Input Tests (NFR-003)

    @Test
    fun `empty input returns empty spannable`() {
        val result = builder.buildSpannable("")

        assertEquals(0, result.length)
        assertEquals("", result.toString())
    }

    @Test
    fun `plain text no tags`() {
        val html = "Just plain text"
        val result = builder.buildSpannable(html)

        assertEquals("Just plain text", result.toString())
    }

    // MARK: - Performance Tests (NFR-001)

    @Test
    fun `performance 100 char HTML`() {
        val html = "<p><strong>Lorem ipsum dolor sit amet</strong>, consectetur adipiscing elit. Sed do eiusmod tempor.</p>"
        assertTrue("HTML should be around 100 chars", html.length <= 120)

        val startTime = System.nanoTime()
        repeat(100) {
            builder.buildSpannable(html)
        }
        val endTime = System.nanoTime()
        val avgTimeMs = (endTime - startTime) / 100 / 1_000_000.0

        assertTrue("Average render time should be < 16ms, was ${avgTimeMs}ms", avgTimeMs < 16)
    }

    @Test
    fun `performance 500 char HTML`() {
        val html = """
            <p><strong>Lorem ipsum dolor sit amet</strong>, consectetur adipiscing elit.
            Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
            <p><em>Ut enim ad minim veniam</em>, quis nostrud exercitation ullamco laboris
            nisi ut aliquip ex ea commodo consequat.</p>
            <h2>Heading Two</h2>
            <p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore
            eu fugiat nulla pariatur.</p>
        """.trimIndent()
        assertTrue("HTML should be around 500 chars", html.length >= 400)

        val startTime = System.nanoTime()
        repeat(100) {
            builder.buildSpannable(html)
        }
        val endTime = System.nanoTime()
        val avgTimeMs = (endTime - startTime) / 100 / 1_000_000.0

        assertTrue("Average render time should be < 16ms, was ${avgTimeMs}ms", avgTimeMs < 16)
    }

    // MARK: - Security Edge Cases

    @Test
    fun `script tags are treated as plain text`() {
        val html = "<script>alert('xss')</script>Safe text"
        val result = builder.buildSpannable(html)

        assertTrue("Should contain Safe text", result.toString().contains("Safe text"))
        assertTrue("Script content should be rendered as text", result.toString().contains("alert('xss')"))
    }

    @Test
    fun `event handlers in attributes are ignored`() {
        val html = "<p onclick=\"alert(1)\">Click me</p>"
        val result = builder.buildSpannable(html)

        assertEquals("Click me", result.toString().trim())
    }

    @Test
    fun `iframe tags are treated as plain text`() {
        val html = "<iframe src=\"malicious.com\"></iframe>Safe content"
        val result = builder.buildSpannable(html)

        assertTrue("Should contain Safe content", result.toString().contains("Safe content"))
    }

    @Test
    fun `javascript urls are rendered as text`() {
        val html = "<a href=\"javascript:alert(1)\">Link</a>"
        val result = builder.buildSpannable(html)

        assertTrue("Should contain Link text", result.toString().contains("Link"))
    }

    @Test
    fun `nested script in allowed tag is rendered as text`() {
        val html = "<p><script>malicious()</script>Safe</p>"
        val result = builder.buildSpannable(html)

        assertTrue("Should contain Safe", result.toString().contains("Safe"))
        assertTrue("Script content rendered as text", result.toString().contains("malicious()"))
    }
}
