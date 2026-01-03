package io.michaelfay.fabrichtmltext

import android.graphics.Color
import android.graphics.Typeface
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.text.style.UnderlineSpan
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class HTMLStylingTest {
    private lateinit var builder: FabricHtmlSpannableBuilder

    @Before
    fun setUp() {
        builder = FabricHtmlSpannableBuilder()
    }

    // MARK: - TagStyles Application Tests

    @Test
    fun `tagStyles applied to matching elements`() {
        // Given: tagStyles that override strong color to red
        val tagStyles = mapOf(
            "strong" to mapOf("color" to "#FF0000")
        )
        builder.setTagStyles(tagStyles)

        // When: HTML with <strong> tag is rendered
        val html = "<p>Normal <strong>Bold</strong> text</p>"
        val spannable = builder.buildSpannable(html)

        // Then: The strong portion should have red color applied
        val text = spannable.toString()
        val boldStart = text.indexOf("Bold")
        val boldEnd = boldStart + "Bold".length

        val colorSpans = spannable.getSpans(boldStart, boldEnd, ForegroundColorSpan::class.java)
        assertTrue("Expected ForegroundColorSpan on bold text", colorSpans.isNotEmpty())

        // Find the color span that overlaps with "Bold"
        val redSpan = colorSpans.find { span ->
            val start = spannable.getSpanStart(span)
            val end = spannable.getSpanEnd(span)
            start <= boldStart && end >= boldEnd && span.foregroundColor == Color.parseColor("#FF0000")
        }
        assertNotNull("Expected red color span on 'Bold' text", redSpan)
    }

    @Test
    fun `tagStyles merge with defaults - bold preserved with color override`() {
        // Given: tagStyles that only override color (not font weight)
        val tagStyles = mapOf(
            "strong" to mapOf("color" to "#0000FF")
        )
        builder.setTagStyles(tagStyles)

        // When: HTML with <strong> tag is rendered
        val html = "<strong>Bold Blue</strong>"
        val spannable = builder.buildSpannable(html)

        // Then: Text should be both bold (default) AND blue (override)
        val styleSpans = spannable.getSpans(0, spannable.length, StyleSpan::class.java)
        val hasBold = styleSpans.any { it.style == Typeface.BOLD }
        assertTrue("Font should still be bold (default style preserved)", hasBold)

        // Check color override is applied
        val colorSpans = spannable.getSpans(0, spannable.length, ForegroundColorSpan::class.java)
        val hasBlue = colorSpans.any { it.foregroundColor == Color.parseColor("#0000FF") }
        assertTrue("Color override should be applied", hasBlue)
    }

    @Test
    fun `tagStyles override defaults when specified`() {
        // Given: tagStyles that override the default font size for paragraphs
        val tagStyles = mapOf(
            "p" to mapOf("fontSize" to 24.0)
        )
        builder.setTagStyles(tagStyles)

        // When: HTML with <p> tag is rendered
        val html = "<p>Large paragraph</p>"
        val spannable = builder.buildSpannable(html)

        // Then: Text should render without error (font size is handled at view level)
        assertEquals("Large paragraph", spannable.toString())
    }

    @Test
    fun `multiple tagStyles applied to different tags`() {
        // Given: tagStyles for multiple tags
        val tagStyles = mapOf(
            "strong" to mapOf("color" to "#FF0000"),
            "em" to mapOf("color" to "#00FF00")
        )
        builder.setTagStyles(tagStyles)

        // When: HTML with both tags is rendered
        val html = "<strong>Red</strong> and <em>Green</em>"
        val spannable = builder.buildSpannable(html)

        val text = spannable.toString()

        // Check strong (red)
        val redStart = text.indexOf("Red")
        val redEnd = redStart + "Red".length
        val redSpans = spannable.getSpans(redStart, redEnd, ForegroundColorSpan::class.java)
        val hasRed = redSpans.any { it.foregroundColor == Color.parseColor("#FF0000") }
        assertTrue("Expected red color on 'Red' text", hasRed)

        // Check em (green)
        val greenStart = text.indexOf("Green")
        val greenEnd = greenStart + "Green".length
        val greenSpans = spannable.getSpans(greenStart, greenEnd, ForegroundColorSpan::class.java)
        val hasGreen = greenSpans.any { it.foregroundColor == Color.parseColor("#00FF00") }
        assertTrue("Expected green color on 'Green' text", hasGreen)
    }

    // MARK: - Invalid Styles Handling Tests

    @Test
    fun `invalid style property is ignored without crashing`() {
        // Given: tagStyles with an invalid property name
        val tagStyles = mapOf(
            "p" to mapOf(
                "color" to "#FF0000",
                "invalidProperty" to "someValue"
            )
        )
        builder.setTagStyles(tagStyles)

        // When: HTML is rendered
        val html = "<p>Text with invalid style</p>"

        // Then: Should not crash and valid properties should apply
        val spannable = builder.buildSpannable(html)
        assertTrue("Should render without crashing", spannable.toString().isNotEmpty())

        // Check that valid color still applied
        val colorSpans = spannable.getSpans(0, spannable.length, ForegroundColorSpan::class.java)
        val hasRed = colorSpans.any { it.foregroundColor == Color.parseColor("#FF0000") }
        assertTrue("Valid color property should still apply", hasRed)
    }

    @Test
    fun `invalid color value is ignored without crashing`() {
        // Given: tagStyles with an invalid color value
        val tagStyles = mapOf(
            "p" to mapOf("color" to "not-a-color")
        )
        builder.setTagStyles(tagStyles)

        // When: HTML is rendered
        val html = "<p>Text with invalid color</p>"

        // Then: Should not crash and text should render with default color
        val spannable = builder.buildSpannable(html)
        assertTrue("Should render without crashing", spannable.toString().isNotEmpty())
    }

    @Test
    fun `empty tagStyles handled gracefully`() {
        // Given: Empty tagStyles dictionary
        val tagStyles = emptyMap<String, Map<String, Any>>()
        builder.setTagStyles(tagStyles)

        // When: HTML is rendered
        val html = "<p>Normal text</p>"

        // Then: Should render normally with default styles
        val spannable = builder.buildSpannable(html)
        assertEquals("Normal text", spannable.toString())
    }

    @Test
    fun `null tagStyles handled gracefully`() {
        // Given: No tagStyles set (null)
        // When: HTML is rendered
        val html = "<strong>Bold text</strong>"

        // Then: Should render normally with default styles
        val spannable = builder.buildSpannable(html)
        assertEquals("Bold text", spannable.toString())

        val styleSpans = spannable.getSpans(0, spannable.length, StyleSpan::class.java)
        val hasBold = styleSpans.any { it.style == Typeface.BOLD }
        assertTrue("Default bold style should be applied", hasBold)
    }

    @Test
    fun `tagStyles for non-existent tag is ignored`() {
        // Given: tagStyles for a tag that doesn't appear in HTML
        val tagStyles = mapOf(
            "h1" to mapOf("color" to "#FF0000")
        )
        builder.setTagStyles(tagStyles)

        // When: HTML without h1 is rendered
        val html = "<p>No heading here</p>"

        // Then: Should render normally without any issues
        val spannable = builder.buildSpannable(html)
        assertEquals("No heading here", spannable.toString())
    }

    // MARK: - Supported Style Properties Tests

    @Test
    fun `fontWeight bold style applied`() {
        // Given: tagStyles with fontWeight bold
        val tagStyles = mapOf(
            "p" to mapOf("fontWeight" to "bold")
        )
        builder.setTagStyles(tagStyles)

        // When: HTML is rendered
        val html = "<p>Bold paragraph</p>"
        val spannable = builder.buildSpannable(html)

        // Then: Font should be bold
        val styleSpans = spannable.getSpans(0, spannable.length, StyleSpan::class.java)
        val hasBold = styleSpans.any { it.style == Typeface.BOLD }
        assertTrue("Font should be bold", hasBold)
    }

    @Test
    fun `fontStyle italic applied`() {
        // Given: tagStyles with fontStyle italic
        val tagStyles = mapOf(
            "p" to mapOf("fontStyle" to "italic")
        )
        builder.setTagStyles(tagStyles)

        // When: HTML is rendered
        val html = "<p>Italic paragraph</p>"
        val spannable = builder.buildSpannable(html)

        // Then: Font should be italic
        val styleSpans = spannable.getSpans(0, spannable.length, StyleSpan::class.java)
        val hasItalic = styleSpans.any { it.style == Typeface.ITALIC }
        assertTrue("Font should be italic", hasItalic)
    }

    @Test
    fun `textDecorationLine underline applied`() {
        // Given: tagStyles with textDecorationLine underline
        val tagStyles = mapOf(
            "p" to mapOf("textDecorationLine" to "underline")
        )
        builder.setTagStyles(tagStyles)

        // When: HTML is rendered
        val html = "<p>Underlined text</p>"
        val spannable = builder.buildSpannable(html)

        // Then: Underline style should be applied
        val underlineSpans = spannable.getSpans(0, spannable.length, UnderlineSpan::class.java)
        assertTrue("Expected underline span", underlineSpans.isNotEmpty())
    }
}
