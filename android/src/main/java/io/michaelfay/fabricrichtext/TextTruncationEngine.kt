package io.michaelfay.fabricrichtext

import android.graphics.Canvas
import android.text.Layout
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.StaticLayout
import android.text.TextPaint

/**
 * Handles smart word-boundary text truncation for numberOfLines feature.
 * Mirrors iOS adjustTruncationIndexToWordBoundary:atIndex: implementation.
 *
 * Single Responsibility: Truncation logic with word-boundary awareness
 */
class TextTruncationEngine(private val textPaint: TextPaint) {

    /**
     * Check if content is truncated based on ellipsis or visible text range.
     * Uses getEllipsisCount and visible text range to accurately detect truncation.
     *
     * @param layout The text layout to check
     * @param numberOfLines Maximum lines allowed (0 = no limit)
     * @param fullText The complete text content
     * @return true if content is truncated
     */
    fun isContentTruncated(layout: Layout?, numberOfLines: Int, fullText: String?): Boolean {
        if (numberOfLines <= 0) return false
        if (layout == null || fullText.isNullOrEmpty()) return false

        val visibleLines = minOf(layout.lineCount, numberOfLines)
        if (visibleLines == 0) return false

        // Check if the last visible line has ellipsis
        val lastVisibleLine = visibleLines - 1
        if (layout.getEllipsisCount(lastVisibleLine) > 0) {
            return true
        }

        // Also check if visible text is less than full text
        val visibleEndOffset = layout.getLineEnd(lastVisibleLine)
        return visibleEndOffset < fullText.length
    }

    /**
     * Adjusts truncation index to word boundary if cut occurs mid-word.
     * Mirrors iOS adjustTruncationIndexToWordBoundary:atIndex: implementation.
     *
     * Algorithm:
     * 1. Check if character at truncation index is alphanumeric (first hidden char)
     * 2. Check if character just before is alphanumeric (last visible char)
     * 3. If both are alphanumeric → cut mid-word detected
     * 4. Find last whitespace in text before truncation point
     * 5. Return whitespace location if found, else original truncation index
     *
     * @param text The text being truncated
     * @param truncationIndex Where truncation would occur
     * @return Adjusted index at last word boundary, or original if no adjustment needed
     */
    fun adjustTruncationIndexToWordBoundary(text: String, truncationIndex: Int): Int {
        if (truncationIndex <= 0 || truncationIndex >= text.length) {
            return truncationIndex
        }

        val lastVisibleChar = text[truncationIndex - 1]
        val firstHiddenChar = text[truncationIndex]

        // Check if we're cutting mid-word (both chars are alphanumeric)
        val cutMidWord = Character.isLetterOrDigit(lastVisibleChar) &&
                         Character.isLetterOrDigit(firstHiddenChar)

        if (!cutMidWord) {
            return truncationIndex
        }

        // Find last whitespace to get the last complete word
        val textBeforeTruncation = text.substring(0, truncationIndex)
        val lastSpaceIndex = textBeforeTruncation.lastIndexOfAny(charArrayOf(' ', '\t'))

        return if (lastSpaceIndex > 0) lastSpaceIndex else truncationIndex
    }

    /**
     * Find the character index where text exceeds availableWidth.
     * Used to determine where truncation should occur before applying word boundary adjustment.
     *
     * @param text The text to measure
     * @param availableWidth Maximum width available for text
     * @return Character index where text exceeds width, or text.length if it fits
     */
    fun findTruncationIndex(text: String, availableWidth: Float): Int {
        var width = 0f
        for (i in text.indices) {
            width += textPaint.measureText(text, i, i + 1)
            if (width > availableWidth) {
                return i
            }
        }
        return text.length
    }

    /**
     * Builds a truncated Spannable preserving spans from the original.
     * Includes the ellipsis character with matching style from the end of the truncated text.
     * Mirrors iOS attributesForTruncationToken: behavior.
     *
     * @param original The original full Spannable
     * @param startOffset Start of the last line in the original
     * @param truncationLength Characters to keep from the last line (before trimming)
     * @return A new Spannable with truncated text + ellipsis, preserving styles
     */
    fun buildTruncatedSpannable(
        original: Spannable,
        startOffset: Int,
        truncationLength: Int
    ): Spannable {
        // Calculate the actual end position in the original spannable
        val endOffset = minOf(startOffset + truncationLength, original.length)

        // Create a SpannableStringBuilder from the truncated portion
        val builder = SpannableStringBuilder(original, startOffset, endOffset)

        // Trim trailing whitespace
        while (builder.isNotEmpty() && Character.isWhitespace(builder[builder.length - 1])) {
            builder.delete(builder.length - 1, builder.length)
        }

        // Get style spans from the last character to apply to ellipsis
        val ellipsisSpans = if (builder.isNotEmpty()) {
            original.getSpans(endOffset - 1, endOffset, Any::class.java)
        } else {
            emptyArray()
        }

        // Append ellipsis
        val ellipsisStart = builder.length
        builder.append("\u2026")

        // Copy relevant style spans to the ellipsis
        for (span in ellipsisSpans) {
            when (span) {
                is android.text.style.ForegroundColorSpan,
                is android.text.style.StyleSpan,
                is android.text.style.TypefaceSpan,
                is android.text.style.AbsoluteSizeSpan -> {
                    // Create a copy of the span for the ellipsis to avoid sharing issues
                    val newSpan = when (span) {
                        is android.text.style.ForegroundColorSpan ->
                            android.text.style.ForegroundColorSpan(span.foregroundColor)
                        is android.text.style.StyleSpan ->
                            android.text.style.StyleSpan(span.style)
                        is android.text.style.AbsoluteSizeSpan ->
                            android.text.style.AbsoluteSizeSpan(span.size, span.dip)
                        else -> span
                    }
                    builder.setSpan(
                        newSpan,
                        ellipsisStart,
                        builder.length,
                        android.text.Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
            }
        }

        return builder
    }

    /**
     * Draws layout with smart word-boundary truncation on the last visible line.
     * Mirrors iOS drawTruncatedFrame:inContext:maxLines: implementation.
     * Preserves text spans (colors, bold, etc.) from the original Spannable.
     *
     * @param canvas The canvas to draw on
     * @param layout The full text layout (without ellipsis)
     * @param spannable The original spannable with all styling
     * @param numberOfLines Maximum lines to display
     */
    fun drawTruncatedLayout(
        canvas: Canvas,
        layout: Layout,
        spannable: Spannable,
        numberOfLines: Int
    ) {
        val lastLine = numberOfLines - 1

        // Draw all complete lines (0 to lastLine-1) using clipping
        if (lastLine > 0) {
            val clipBottom = layout.getLineBottom(lastLine - 1)
            canvas.save()
            canvas.clipRect(0f, 0f, layout.width.toFloat(), clipBottom.toFloat())
            layout.draw(canvas)
            canvas.restore()
        }

        // Handle last visible line with word boundary truncation
        val lastLineStart = layout.getLineStart(lastLine)
        val plainText = spannable.toString()

        // Guard against out of bounds
        if (lastLineStart >= plainText.length) {
            return
        }

        // Get remaining text from last line start to end
        val remainingText = plainText.substring(lastLineStart)

        // Replace newlines with spaces (matching iOS behavior)
        val continuousText = remainingText.replace(Regex("[\n\r]"), " ")

        // Calculate how much text fits on the last line (account for ellipsis width)
        val ellipsisWidth = textPaint.measureText("\u2026")
        val availableWidth = layout.width.toFloat() - ellipsisWidth

        // Find truncation point using paint measurement
        val truncationIndex = findTruncationIndex(continuousText, availableWidth)

        // Apply word boundary adjustment
        val adjustedIndex = adjustTruncationIndexToWordBoundary(continuousText, truncationIndex)

        // Guard against zero-length truncation
        if (adjustedIndex <= 0) {
            return
        }

        // Build truncated Spannable preserving original spans
        val truncatedSpannable = buildTruncatedSpannable(spannable, lastLineStart, adjustedIndex)

        // Draw the truncated last line using StaticLayout to preserve spans
        val lastLineTop = layout.getLineTop(lastLine).toFloat()
        val truncatedLayout = StaticLayout.Builder
            .obtain(truncatedSpannable, 0, truncatedSpannable.length, textPaint, layout.width)
            .setAlignment(layout.alignment)
            .setLineSpacing(0f, 1f)
            .setIncludePad(false)
            .build()

        canvas.save()
        canvas.translate(0f, lastLineTop)
        truncatedLayout.draw(canvas)
        canvas.restore()
    }

    /**
     * Gets the character offset where visible content ends on the given line,
     * accounting for ellipsis truncation.
     *
     * @param layout The text layout
     * @param line The line index to check
     * @return Character offset where visible content ends
     */
    fun getVisibleContentEnd(layout: Layout, line: Int): Int {
        val lineStart = layout.getLineStart(line)
        val lineEnd = layout.getLineEnd(line)

        // Check if this line has ellipsis truncation
        val ellipsisCount = layout.getEllipsisCount(line)
        if (ellipsisCount > 0) {
            // Content is truncated - ellipsis starts at this offset within the line
            val ellipsisStart = layout.getEllipsisStart(line)
            return lineStart + ellipsisStart
        }

        return lineEnd
    }

    /**
     * Calculate the visible text for accessibility when content is truncated.
     *
     * @param layout The text layout
     * @param fullText The complete text content
     * @param numberOfLines Maximum lines allowed
     * @return The visible portion of text with word-boundary adjustment
     */
    fun calculateVisibleText(layout: Layout, fullText: String, numberOfLines: Int): String {
        val visibleLines = minOf(layout.lineCount, numberOfLines)
        val lastLine = visibleLines - 1
        val lastLineStart = layout.getLineStart(lastLine)

        // Get remaining text and find word-boundary-adjusted truncation point
        val remainingText = fullText.substring(lastLineStart).replace(Regex("[\n\r]"), " ")
        val ellipsisWidth = textPaint.measureText("\u2026")
        val availableWidth = layout.width.toFloat() - ellipsisWidth
        val truncationIndex = findTruncationIndex(remainingText, availableWidth)
        val adjustedIndex = adjustTruncationIndexToWordBoundary(remainingText, truncationIndex)

        // Build visible text from all complete lines + truncated last line
        val completeLinesText = if (lastLine > 0) fullText.substring(0, lastLineStart) else ""
        val truncatedLastLine = if (adjustedIndex > 0) {
            remainingText.substring(0, adjustedIndex).trimEnd()
        } else ""

        return (completeLinesText + truncatedLastLine).trim()
    }
}
