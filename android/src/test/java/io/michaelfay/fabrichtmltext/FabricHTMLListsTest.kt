package io.michaelfay.fabrichtmltext

import android.text.style.ClickableSpan
import android.text.style.LeadingMarginSpan
import android.text.style.StyleSpan
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class HTMLListsTest {

    private lateinit var builder: FabricHtmlSpannableBuilder

    @Before
    fun setUp() {
        builder = FabricHtmlSpannableBuilder()
    }

    // MARK: - Unordered List Tests (FR-006)

    @Test
    fun `unordered list inserts bullet markers`() {
        val html = "<ul><li>First</li><li>Second</li></ul>"
        val result = builder.buildSpannable(html)

        val text = result.toString()
        assertTrue("Should contain bullet marker", text.contains("•"))
        assertTrue("Should contain First", text.contains("First"))
        assertTrue("Should contain Second", text.contains("Second"))
    }

    @Test
    fun `unordered list uses unicode bullet`() {
        val html = "<ul><li>Item</li></ul>"
        val result = builder.buildSpannable(html)

        assertTrue("Should use Unicode bullet U+2022", result.toString().contains("\u2022"))
    }

    @Test
    fun `unordered list multiple items have bullets`() {
        val html = "<ul><li>A</li><li>B</li><li>C</li></ul>"
        val result = builder.buildSpannable(html)

        val bulletCount = result.toString().count { it == '\u2022' }
        assertEquals("Should have 3 bullet markers", 3, bulletCount)
    }

    // MARK: - Ordered List Tests (FR-007)

    @Test
    fun `ordered list inserts sequential numbers`() {
        val html = "<ol><li>First</li><li>Second</li><li>Third</li></ol>"
        val result = builder.buildSpannable(html)

        val text = result.toString()
        assertTrue("Should contain '1.'", text.contains("1."))
        assertTrue("Should contain '2.'", text.contains("2."))
        assertTrue("Should contain '3.'", text.contains("3."))
    }

    @Test
    fun `ordered list numbering restarts for separate lists`() {
        val html = "<ol><li>A</li><li>B</li></ol><ol><li>X</li><li>Y</li></ol>"
        val result = builder.buildSpannable(html)

        val text = result.toString()
        val oneCount = text.split("1.").size - 1
        assertEquals("Should have two '1.' markers for separate lists", 2, oneCount)
    }

    // MARK: - Orphaned List Item Tests (FR-008)

    @Test
    fun `orphaned list item renders as plain text`() {
        val html = "<li>Orphan</li>"
        val result = builder.buildSpannable(html)

        assertEquals("Orphaned li should render as plain text", "Orphan", result.toString())
        assertFalse("Should NOT have bullet marker", result.toString().contains("•"))
        assertFalse("Should NOT have number marker", result.toString().contains("1."))
    }

    @Test
    fun `orphaned list item no marker no indentation`() {
        val html = "Before<li>Middle</li>After"
        val result = builder.buildSpannable(html)

        assertTrue("Should render inline without markers", result.toString().contains("BeforeMiddleAfter"))
    }

    // MARK: - List Indentation Tests (FR-009)

    @Test
    fun `list indentation applies LeadingMarginSpan`() {
        val html = "<ul><li>Indented item</li></ul>"
        val result = builder.buildSpannable(html)

        val spans = result.getSpans(0, result.length, LeadingMarginSpan::class.java)
        assertTrue("List items should have LeadingMarginSpan for indentation", spans.isNotEmpty())
    }

    // MARK: - Nested List Tests (FR-010)

    @Test
    fun `nested list increases indentation`() {
        val html = """
            <ul>
                <li>Level 1</li>
                <li><ul><li>Level 2</li></ul></li>
            </ul>
        """.trimIndent()
        val result = builder.buildSpannable(html)

        val text = result.toString()
        assertTrue("Should contain Level 1", text.contains("Level 1"))
        assertTrue("Should contain Level 2", text.contains("Level 2"))
    }

    @Test
    fun `nested list caps at level 3`() {
        val html = """
            <ul>
                <li>L1<ul>
                    <li>L2<ul>
                        <li>L3<ul>
                            <li>L4</li>
                        </ul></li>
                    </ul></li>
                </ul></li>
            </ul>
        """.trimIndent()
        val result = builder.buildSpannable(html)

        val text = result.toString()
        assertTrue("Should contain L1", text.contains("L1"))
        assertTrue("Should contain L4 (but styled as L3)", text.contains("L4"))
    }

    // MARK: - Mixed Content in Lists

    @Test
    fun `list with bold content`() {
        val html = "<ul><li><strong>Bold item</strong></li></ul>"
        val result = builder.buildSpannable(html)

        val text = result.toString()
        assertTrue("Should contain bold item text", text.contains("Bold item"))
        assertTrue("Should have bullet marker", text.contains("•"))

        val styleSpans = result.getSpans(0, result.length, StyleSpan::class.java)
        assertTrue("Should have bold style", styleSpans.any { it.style == android.graphics.Typeface.BOLD })
    }

    @Test
    fun `list with link content`() {
        val html = "<ul><li><a href=\"https://example.com\">Link</a></li></ul>"
        val result = builder.buildSpannable(html)

        val text = result.toString()
        assertTrue("Should contain link text", text.contains("Link"))
        assertTrue("Should have bullet marker", text.contains("•"))

        val linkSpans = result.getSpans(0, result.length, ClickableSpan::class.java)
        assertTrue("Should have link span", linkSpans.isNotEmpty())
    }

    // MARK: - Empty List Tests

    @Test
    fun `empty list renders nothing`() {
        val html = "<ul></ul>"
        val result = builder.buildSpannable(html)

        assertTrue("Empty list should render as empty", result.toString().trim().isEmpty())
    }

    @Test
    fun `empty list item renders marker only`() {
        val html = "<ul><li></li></ul>"
        val result = builder.buildSpannable(html)

        assertTrue("Should have bullet marker for empty item", result.toString().contains("•"))
    }

    // MARK: - Accessibility Tests

    @Test
    fun `list accessibility contains all content`() {
        val html = "<ul><li>Item 1</li><li>Item 2</li></ul>"
        val result = builder.buildSpannable(html)

        val text = result.toString()
        assertTrue("Should contain Item 1 for accessibility", text.contains("Item 1"))
        assertTrue("Should contain Item 2 for accessibility", text.contains("Item 2"))
    }
}
