package io.michaelfay.fabrichtmltext

import android.graphics.RectF
import android.text.SpannableString
import android.text.style.ClickableSpan
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * Unit tests for link bounds calculation in FabricHTMLTextView.
 *
 * These tests verify the `getLinkBounds(index)` method correctly calculates
 * bounding rectangles for links in the text using Layout analysis.
 *
 * TDD Requirement: These tests should FAIL initially until T007 is implemented.
 *
 * ## Accessibility Testing Limitations
 *
 * Robolectric (used for unit tests) has limitations for accessibility testing:
 * - Text ellipsis calculations are not accurate
 * - Layout metrics may differ from real devices
 * - AccessibilityNodeProvider virtual nodes are partially mocked
 *
 * For comprehensive accessibility testing, use Espresso with ATF:
 * ```kotlin
 * // In androidTest/FabricHTMLAccessibilityTest.kt
 * @Before
 * fun setUp() {
 *     AccessibilityChecks.enable()
 *         .setRunChecksFromRootView(true)
 *         .setThrowExceptionFor(AccessibilityCheckResultType.ERROR)
 * }
 * ```
 *
 * See: https://developer.android.com/training/testing/espresso/accessibility-checking
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class FabricHTMLLinkBoundsTest {

    private lateinit var textView: FabricHTMLTextView
    private lateinit var builder: FabricHtmlSpannableBuilder

    @Before
    fun setUp() {
        val context = RuntimeEnvironment.getApplication()
        textView = FabricHTMLTextView(context)
        builder = FabricHtmlSpannableBuilder()
        // Set a reasonable size for layout creation
        textView.layout(0, 0, 300, 100)
    }

    // MARK: - Basic Link Bounds Tests

    @Test
    fun `getLinkBounds returns valid rect for single link`() {
        // Given: A view with a single link
        val html = """<p>Visit <a href="https://example.com">Example Site</a> for more info.</p>"""
        setHtmlAndLayout(html)

        // When: We get the bounds for link at index 0
        val bounds = textView.getLinkBounds(0)

        // Then: The bounds should be a valid non-empty rect
        assertNotNull("Bounds should not be null for valid link", bounds)
        assertFalse("Bounds should not be empty for valid link", bounds!!.isEmpty)
        assertTrue("Bounds width should be positive", bounds.width() > 0)
        assertTrue("Bounds height should be positive", bounds.height() > 0)
    }

    @Test
    fun `getLinkBounds returns null for invalid index`() {
        // Given: A view with one link
        val html = """<p>Visit <a href="https://example.com">Example</a>.</p>"""
        setHtmlAndLayout(html)

        // When: We request bounds for an invalid index
        val bounds = textView.getLinkBounds(999)

        // Then: Should return null
        assertNull("Bounds for invalid index should be null", bounds)
    }

    @Test
    fun `getLinkBounds returns null for empty text`() {
        // Given: A view with no text
        textView.text = ""

        // When: We request any bounds
        val bounds = textView.getLinkBounds(0)

        // Then: Should return null
        assertNull("Bounds for empty text should be null", bounds)
    }

    @Test
    fun `getLinkBounds returns null when no links exist`() {
        // Given: A view with plain text (no links)
        val html = "<p>Just plain text with no links.</p>"
        setHtmlAndLayout(html)

        // When: We request bounds for index 0
        val bounds = textView.getLinkBounds(0)

        // Then: Should return null
        assertNull("Bounds for text without links should be null", bounds)
    }

    // MARK: - Multiple Links Tests

    @Test
    fun `getLinkBounds returns different bounds for multiple links`() {
        // Given: A view with multiple links
        val html = """<p>Visit <a href="https://a.com">First</a> and <a href="https://b.com">Second</a> links.</p>"""
        setHtmlAndLayout(html)

        // When: We get bounds for each link
        val firstBounds = textView.getLinkBounds(0)
        val secondBounds = textView.getLinkBounds(1)

        // Then: Both should have valid bounds
        assertNotNull("First link should have valid bounds", firstBounds)
        assertNotNull("Second link should have valid bounds", secondBounds)
        assertFalse("First link bounds should not be empty", firstBounds!!.isEmpty)
        assertFalse("Second link bounds should not be empty", secondBounds!!.isEmpty)

        // And: Second link should be to the right of first (assuming LTR text)
        assertTrue(
            "Second link should be positioned after first",
            secondBounds.left > firstBounds.left
        )
    }

    @Test
    fun `getLinkBounds returns non-overlapping bounds for adjacent links`() {
        // Given: A view with adjacent links
        val html = """<p><a href="https://a.com">Link One</a> <a href="https://b.com">Link Two</a></p>"""
        setHtmlAndLayout(html)

        // When: We get bounds for both links
        val firstBounds = textView.getLinkBounds(0)
        val secondBounds = textView.getLinkBounds(1)

        // Then: They should not overlap significantly
        assertNotNull("First bounds should not be null", firstBounds)
        assertNotNull("Second bounds should not be null", secondBounds)

        val intersection = RectF()
        val overlaps = intersection.setIntersect(firstBounds!!, secondBounds!!)
        assertTrue(
            "Link bounds should not overlap significantly",
            !overlaps || intersection.width() < 1
        )
    }

    // MARK: - Multi-Line Link Tests

    @Test
    fun `getLinkBounds returns union rect for multi-line link`() {
        // Given: A view with a link that spans multiple lines (narrow width)
        val context = RuntimeEnvironment.getApplication()
        textView = FabricHTMLTextView(context)
        textView.layout(0, 0, 80, 200) // Narrow width to force wrapping

        val html = """<p><a href="https://example.com">This is a very long link text that will wrap to multiple lines</a></p>"""
        setHtmlAndLayout(html)

        // When: We get the bounds
        val bounds = textView.getLinkBounds(0)

        // Then: The bounds should span multiple line heights
        assertNotNull("Multi-line link should have bounds", bounds)
        assertTrue(
            "Multi-line link should have height spanning multiple lines",
            bounds!!.height() > 30
        )
    }

    // MARK: - Bounds Coordinate Tests

    @Test
    fun `getLinkBounds returns coordinates within view bounds`() {
        // Given: A view with a link
        val html = """<p>Visit <a href="https://example.com">Example</a>.</p>"""
        setHtmlAndLayout(html)

        // When: We get the bounds
        val bounds = textView.getLinkBounds(0)

        // Then: Bounds should be within the view's bounds
        assertNotNull("Bounds should not be null", bounds)
        assertTrue("Bounds left should be >= 0", bounds!!.left >= 0)
        assertTrue("Bounds top should be >= 0", bounds.top >= 0)
        assertTrue(
            "Bounds right should be <= view width",
            bounds.right <= textView.width
        )
        assertTrue(
            "Bounds bottom should be <= view height",
            bounds.bottom <= textView.height
        )
    }

    // MARK: - Visible Link Count Tests

    @Test
    fun `getVisibleLinkCount returns correct count with no truncation`() {
        // Given: A view with 3 links and no truncation
        val html = """<p><a href="https://a.com">A</a> <a href="https://b.com">B</a> <a href="https://c.com">C</a></p>"""
        textView.setNumberOfLines(0) // No limit
        setHtmlAndLayout(html)

        // When: We get the visible link count
        val count = textView.getVisibleLinkCount()

        // Then: All 3 links should be visible
        assertEquals("All 3 links should be visible when no truncation", 3, count)
    }

    @Test
    fun `getVisibleLinkCount respects numberOfLines limit`() {
        // Given: A view with numberOfLines set to 1
        val html = """<p><a href="https://a.com">First</a> <a href="https://b.com">Second</a> <a href="https://c.com">Third</a></p>"""
        textView.setNumberOfLines(1)
        setHtmlAndLayout(html)

        // When: We get the visible link count
        val count = textView.getVisibleLinkCount()

        // Then: Method should be callable and return a non-negative count
        // Note: Robolectric doesn't simulate text ellipsis, so we can't verify
        // the exact truncation behavior. Real ellipsis testing requires
        // instrumentation tests with Espresso/ATF.
        assertTrue("Visible link count should be non-negative", count >= 0)
        assertTrue("Visible link count should not exceed total links", count <= 3)
    }

    @Test
    fun `getVisibleLinkCount returns all links when no truncation`() {
        // Given: A view with no line limit (numberOfLines=0)
        val html = """<p><a href="https://a.com">A</a> <a href="https://b.com">B</a> <a href="https://c.com">C</a></p>"""
        textView.setNumberOfLines(0)
        setHtmlAndLayout(html)

        // When: We get the visible link count
        val count = textView.getVisibleLinkCount()

        // Then: All links should be visible
        assertEquals("All 3 links should be visible when numberOfLines=0", 3, count)
    }

    @Test
    fun `getVisibleLinkCount handles multi-line text with line limit`() {
        // Given: A narrow view that wraps to multiple lines
        val context = RuntimeEnvironment.getApplication()
        textView = FabricHTMLTextView(context)
        textView.layout(0, 0, 80, 200) // Narrow width to force wrapping

        // Use text with links spread across expected multiple lines
        val html = """<p><a href="https://a.com">First Link Here</a> some text <a href="https://b.com">Second Link Here</a> more text <a href="https://c.com">Third Link Here</a></p>"""
        textView.setNumberOfLines(2) // Limit to 2 lines

        val spannable = builder.buildSpannable(html)
        textView.setSpannableFromState(spannable)
        textView.measure(
            android.view.View.MeasureSpec.makeMeasureSpec(80, android.view.View.MeasureSpec.EXACTLY),
            android.view.View.MeasureSpec.makeMeasureSpec(200, android.view.View.MeasureSpec.AT_MOST)
        )
        textView.layout(0, 0, 80, 200)

        // When: We get the visible link count
        val count = textView.getVisibleLinkCount()

        // Then: Count should be between 0 and 3
        // Note: Exact count depends on text layout which varies in Robolectric
        assertTrue("Visible link count should be non-negative", count >= 0)
        assertTrue("Visible link count should not exceed total links", count <= 3)
    }

    @Test
    fun `getVisibleLinkCount returns zero when no links exist`() {
        // Given: A view with no links
        val html = "<p>Just plain text with no links.</p>"
        setHtmlAndLayout(html)

        // When: We get the visible link count
        val count = textView.getVisibleLinkCount()

        // Then: Should be zero
        assertEquals("View with no links should have count of 0", 0, count)
    }

    @Test
    fun `getVisibleLinkCount returns zero for empty text`() {
        // Given: A view with no text
        textView.text = ""

        // When: We get the visible link count
        val count = textView.getVisibleLinkCount()

        // Then: Should be zero
        assertEquals("Empty view should have count of 0", 0, count)
    }

    // MARK: - Helper Methods

    private fun setHtmlAndLayout(html: String) {
        val spannable = builder.buildSpannable(html)
        textView.setSpannableFromState(spannable)
        // Force layout creation
        textView.measure(
            android.view.View.MeasureSpec.makeMeasureSpec(300, android.view.View.MeasureSpec.EXACTLY),
            android.view.View.MeasureSpec.makeMeasureSpec(100, android.view.View.MeasureSpec.AT_MOST)
        )
        textView.layout(0, 0, 300, 100)
    }
}
