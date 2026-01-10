package io.michaelfay.fabricrichtext

import android.graphics.RectF
import android.text.Layout
import android.text.Spannable
import android.text.style.ClickableSpan
import kotlin.math.max
import kotlin.math.min

/**
 * Provides accessibility support for text views with truncation and links.
 * Handles visible text calculation, link bounds, and truncation-aware content.
 *
 * Single Responsibility: Accessibility calculations and link range queries
 */
class TextAccessibilityHelper(
    private val truncationEngine: TextTruncationEngine
) {

    /**
     * Returns all ClickableSpan ranges in the text, sorted by start position.
     * This includes both HrefClickableSpan (explicit links) and URLSpan (auto-detected).
     *
     * @param spannable The spannable to search for links
     * @return List of IntRange for each link, sorted by start position
     */
    fun getAllLinkRanges(spannable: Spannable?): List<IntRange> {
        if (spannable == null) return emptyList()

        val spans = spannable.getSpans(0, spannable.length, ClickableSpan::class.java)

        return spans.map { span ->
            val start = spannable.getSpanStart(span)
            val end = spannable.getSpanEnd(span)
            start until end
        }.sortedBy { it.first }
    }

    /**
     * Returns the number of visible (non-truncated) links in the view.
     * When numberOfLines is set, only counts links that are fully visible
     * (not truncated by ellipsis).
     *
     * @param layout The text layout
     * @param spannable The spannable containing links
     * @param numberOfLines Maximum lines allowed (0 = no limit)
     * @return Count of fully visible links
     */
    fun getVisibleLinkCount(layout: Layout?, spannable: Spannable?, numberOfLines: Int): Int {
        if (layout == null) return 0

        val linkRanges = getAllLinkRanges(spannable)
        if (linkRanges.isEmpty()) return 0

        // If no line limit, all links are visible
        if (numberOfLines <= 0) return linkRanges.size

        // Get the visible line count (capped by numberOfLines)
        val visibleLines = min(layout.lineCount, numberOfLines)
        if (visibleLines == 0) return 0

        // Find the actual visible content end, accounting for ellipsis
        val lastVisibleLine = visibleLines - 1
        val visibleContentEnd = truncationEngine.getVisibleContentEnd(layout, lastVisibleLine)

        // Count links that END before the visible content end
        // (links that are fully visible, not partially truncated)
        return linkRanges.count { range ->
            range.last < visibleContentEnd
        }
    }

    /**
     * Returns the bounding rectangle for the link at the given index.
     * The bounds are in the layout's coordinate system.
     *
     * @param layout The text layout
     * @param spannable The spannable containing links
     * @param index The zero-based index of the link (0 = first link)
     * @param paddingLeft Left padding to offset bounds
     * @param paddingTop Top padding to offset bounds
     * @return The bounding rectangle, or null if index is invalid or no links exist
     *
     * For multi-line links, returns the union of all line segments containing the link.
     */
    fun getLinkBounds(
        layout: Layout?,
        spannable: Spannable?,
        index: Int,
        paddingLeft: Int = 0,
        paddingTop: Int = 0
    ): RectF? {
        if (layout == null) return null

        val linkRanges = getAllLinkRanges(spannable)
        if (index < 0 || index >= linkRanges.size) return null

        val range = linkRanges[index]
        val linkStart = range.first
        val linkEnd = range.last + 1 // IntRange is exclusive end, but we need inclusive

        // Get the lines containing this link
        val startLine = layout.getLineForOffset(linkStart)
        val endLine = layout.getLineForOffset(linkEnd - 1)

        if (startLine < 0) return null

        // Calculate bounds for each line segment and union them
        val bounds = RectF()
        var isFirstRect = true

        for (line in startLine..endLine) {
            val lineStart = layout.getLineStart(line)
            val lineEnd = layout.getLineEnd(line)

            // Clip the link range to this line
            val segmentStart = max(linkStart, lineStart)
            val segmentEnd = min(linkEnd, lineEnd)

            if (segmentStart >= segmentEnd) continue

            // Get horizontal bounds for this segment
            val left = layout.getPrimaryHorizontal(segmentStart)
            val right = layout.getPrimaryHorizontal(segmentEnd)

            // Get vertical bounds from the line
            val top = layout.getLineTop(line).toFloat()
            val bottom = layout.getLineBottom(line).toFloat()

            // Create rect for this segment (handle RTL where right < left)
            val segmentRect = RectF(
                min(left, right),
                top,
                max(left, right),
                bottom
            )

            // Union with accumulated bounds
            if (isFirstRect) {
                bounds.set(segmentRect)
                isFirstRect = false
            } else {
                bounds.union(segmentRect)
            }
        }

        // Return null if we didn't calculate any bounds
        if (isFirstRect) return null

        // Offset by padding to convert to view coordinates
        bounds.offset(paddingLeft.toFloat(), paddingTop.toFloat())

        return bounds
    }

    /**
     * Check if a character at the given index is on a visible line.
     * Used by accessibility delegate to filter links to only those on visible lines.
     *
     * @param layout The text layout
     * @param charIndex The character index to check
     * @param numberOfLines Maximum lines allowed (0 = no limit)
     * @return true if the character is on a visible line, false if it's on a truncated line
     */
    fun isCharacterOnVisibleLine(layout: Layout?, charIndex: Int, numberOfLines: Int): Boolean {
        // No truncation - all characters are visible
        if (numberOfLines <= 0) return true
        if (layout == null) return true

        // Find which line contains this character
        val lineForChar = layout.getLineForOffset(charIndex)
        return lineForChar < numberOfLines
    }

    /**
     * Get the visible text for accessibility when content is truncated.
     * Returns only the portion of text that is actually visible on screen,
     * accounting for ellipsis truncation on the last line.
     *
     * @param layout The text layout
     * @param baseLabel The base accessibility label or full text
     * @param spannable The spannable (for fallback text)
     * @param numberOfLines Maximum lines allowed (0 = no limit)
     * @return The visible text for screen readers
     */
    fun getVisibleTextForAccessibility(
        layout: Layout?,
        baseLabel: String?,
        spannable: Spannable?,
        numberOfLines: Int
    ): String {
        val effectiveLabel = baseLabel ?: spannable?.toString() ?: ""

        // If not truncating or no content, return full text
        if (numberOfLines <= 0 || effectiveLabel.isEmpty()) {
            return effectiveLabel
        }

        if (layout == null) {
            // Layout not available yet - return full text
            return effectiveLabel
        }

        val fullText = spannable?.toString() ?: effectiveLabel
        if (!truncationEngine.isContentTruncated(layout, numberOfLines, fullText)) {
            // Not actually truncated - return full text
            return effectiveLabel
        }

        // Content is truncated - calculate word-boundary-adjusted visible text
        return truncationEngine.calculateVisibleText(layout, fullText, numberOfLines)
    }
}
