package io.michaelfay.fabricrichtext

import android.os.Looper
import android.text.SpannableStringBuilder
import android.view.View
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * Unit tests for FabricRichTextView measurement callback functionality.
 *
 * Verifies that onRichTextMeasurement correctly reports:
 * - measuredLineCount: Total lines the text would occupy without truncation
 * - visibleLineCount: Actual lines visible (limited by numberOfLines prop)
 *
 * Note: These tests use explicit newlines to force line breaks since Robolectric's
 * text layout may not wrap text the same way as real devices.
 */
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE)
class FabricRichTextMeasurementTest {

    private lateinit var view: FabricRichTextView
    private var lastMeasuredLineCount: Int = -1
    private var lastVisibleLineCount: Int = -1
    private var measurementCallCount: Int = 0

    @Before
    fun setUp() {
        view = FabricRichTextView(RuntimeEnvironment.getApplication())
        lastMeasuredLineCount = -1
        lastVisibleLineCount = -1
        measurementCallCount = 0

        view.measurementListener = object : MeasurementListener {
            override fun onMeasurement(measuredLineCount: Int, visibleLineCount: Int) {
                lastMeasuredLineCount = measuredLineCount
                lastVisibleLineCount = visibleLineCount
                measurementCallCount++
            }
        }
    }

    // ========== Helper Methods ==========

    /**
     * Sets up the view with a spannable and forces layout/draw to trigger measurement.
     * Idles the main looper to process any queued runnables.
     */
    private fun setupViewWithText(text: String, numberOfLines: Int = 0) {
        val spannable = SpannableStringBuilder(text)
        view.setNumberOfLines(numberOfLines)
        view.setSpannableFromState(spannable)

        // Idle main looper to process any posted runnables (accessibility updates, etc.)
        shadowOf(Looper.getMainLooper()).idle()

        // Force measure and layout with a realistic width
        val widthSpec = View.MeasureSpec.makeMeasureSpec(300, View.MeasureSpec.EXACTLY)
        val heightSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        view.measure(widthSpec, heightSpec)
        view.layout(0, 0, 300, view.measuredHeight)

        // Force draw to trigger measurement callback
        view.draw(android.graphics.Canvas())

        // Idle again after draw
        shadowOf(Looper.getMainLooper()).idle()
    }

    // ========== No Truncation Tests ==========

    @Test
    fun `measurement reports equal counts when no numberOfLines limit`() {
        // Use explicit newlines to ensure multiple lines
        val multilineText = "Line one\nLine two\nLine three\nLine four"

        setupViewWithText(multilineText, numberOfLines = 0)

        assertTrue("Measurement callback should be called", measurementCallCount > 0)
        assertTrue("Measured line count should be positive", lastMeasuredLineCount > 0)
        assertEquals(
            "Without numberOfLines limit, measured and visible should be equal",
            lastMeasuredLineCount,
            lastVisibleLineCount
        )
    }

    @Test
    fun `single line text reports 1 for both counts`() {
        setupViewWithText("Short text", numberOfLines = 0)

        assertTrue("Measurement callback should be called", measurementCallCount > 0)
        assertEquals("Single line text should report 1 measured line", 1, lastMeasuredLineCount)
        assertEquals("Single line text should report 1 visible line", 1, lastVisibleLineCount)
    }

    // ========== Truncation Tests ==========

    @Test
    fun `truncated text reports different measured vs visible counts`() {
        // Use explicit newlines to create exactly 5 lines
        val fiveLineText = "Line one\nLine two\nLine three\nLine four\nLine five"

        setupViewWithText(fiveLineText, numberOfLines = 2)

        assertTrue("Measurement callback should be called", measurementCallCount > 0)
        assertEquals("Measured count should be 5", 5, lastMeasuredLineCount)
        assertEquals("Visible count should be capped at 2", 2, lastVisibleLineCount)
        assertTrue(
            "Measured count should be greater than visible when truncated",
            lastMeasuredLineCount > lastVisibleLineCount
        )
    }

    @Test
    fun `numberOfLines=1 caps visible count to 1`() {
        // Use explicit newlines to create 3 lines
        val threeLineText = "Line one\nLine two\nLine three"

        setupViewWithText(threeLineText, numberOfLines = 1)

        assertTrue("Measurement callback should be called", measurementCallCount > 0)
        assertEquals("Visible count should be 1", 1, lastVisibleLineCount)
        assertEquals("Measured count should be 3", 3, lastMeasuredLineCount)
    }

    @Test
    fun `numberOfLines greater than actual lines reports actual count`() {
        setupViewWithText("Short text", numberOfLines = 10)

        assertTrue("Measurement callback should be called", measurementCallCount > 0)
        assertEquals(
            "When numberOfLines exceeds actual lines, both should be actual count",
            lastMeasuredLineCount,
            lastVisibleLineCount
        )
        assertTrue(
            "Visible count should be less than or equal to numberOfLines",
            lastVisibleLineCount <= 10
        )
    }

    // ========== Edge Cases ==========

    @Test
    fun `empty text does not trigger measurement`() {
        setupViewWithText("", numberOfLines = 0)

        assertEquals("Empty text should not trigger measurement", 0, measurementCallCount)
    }

    @Test
    fun `changing numberOfLines updates visible count`() {
        // Use explicit newlines to create 5 lines
        val fiveLineText = "Line one\nLine two\nLine three\nLine four\nLine five"

        // First with no limit
        setupViewWithText(fiveLineText, numberOfLines = 0)
        val fullLineCount = lastMeasuredLineCount
        assertEquals("Full text should have 5 lines", 5, fullLineCount)

        // Then with limit of 2
        view.setNumberOfLines(2)
        shadowOf(Looper.getMainLooper()).idle()
        view.draw(android.graphics.Canvas())
        shadowOf(Looper.getMainLooper()).idle()

        assertEquals("Measured count should remain 5", 5, lastMeasuredLineCount)
        assertEquals("Visible count should be capped at 2", 2, lastVisibleLineCount)
    }

    @Test
    fun `measurement only fires when values change`() {
        setupViewWithText("Test text", numberOfLines = 0)
        val initialCallCount = measurementCallCount

        // Draw again without changing anything
        view.draw(android.graphics.Canvas())
        shadowOf(Looper.getMainLooper()).idle()

        assertEquals(
            "Measurement should not fire again if values unchanged",
            initialCallCount,
            measurementCallCount
        )
    }

    // ========== numberOfLines Boundary Tests ==========

    @Test
    fun `numberOfLines=3 with exactly 3 lines reports equal counts`() {
        // Create text with exactly 3 lines
        val text = "Line one\nLine two\nLine three"

        setupViewWithText(text, numberOfLines = 3)

        assertTrue("Measurement callback should be called", measurementCallCount > 0)
        assertEquals("Measured count should be 3", 3, lastMeasuredLineCount)
        assertEquals("Visible count should be 3", 3, lastVisibleLineCount)
    }

    @Test
    fun `negative numberOfLines treated as no limit`() {
        val threeLineText = "Line one\nLine two\nLine three"

        // Test that negative values are handled gracefully (should act like 0)
        view.setNumberOfLines(-1)
        val spannable = SpannableStringBuilder(threeLineText)
        view.setSpannableFromState(spannable)
        shadowOf(Looper.getMainLooper()).idle()

        val widthSpec = View.MeasureSpec.makeMeasureSpec(300, View.MeasureSpec.EXACTLY)
        val heightSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        view.measure(widthSpec, heightSpec)
        view.layout(0, 0, 300, view.measuredHeight)
        view.draw(android.graphics.Canvas())
        shadowOf(Looper.getMainLooper()).idle()

        // Negative should be treated as 0 (no limit), so counts should be equal
        assertEquals(
            "Negative numberOfLines should act as no limit",
            lastMeasuredLineCount,
            lastVisibleLineCount
        )
        assertEquals("Should have 3 lines", 3, lastMeasuredLineCount)
    }

    // ========== Measurement Value Correctness ==========

    @Test
    fun `visible count never exceeds measured count`() {
        val fourLineText = "Line one\nLine two\nLine three\nLine four"

        // Test with various numberOfLines values
        for (limit in listOf(0, 1, 2, 3, 4, 5, 10)) {
            setupViewWithText(fourLineText, numberOfLines = limit)

            assertTrue(
                "Visible count ($lastVisibleLineCount) should never exceed measured count ($lastMeasuredLineCount) for limit=$limit",
                lastVisibleLineCount <= lastMeasuredLineCount
            )
        }
    }

    @Test
    fun `visible count respects numberOfLines limit`() {
        val tenLineText = (1..10).joinToString("\n") { "Line $it" }

        for (limit in 1..10) {
            setupViewWithText(tenLineText, numberOfLines = limit)

            assertEquals(
                "Visible count should be exactly $limit when text has more lines",
                limit,
                lastVisibleLineCount
            )
            assertEquals(
                "Measured count should always be 10",
                10,
                lastMeasuredLineCount
            )
        }
    }
}
