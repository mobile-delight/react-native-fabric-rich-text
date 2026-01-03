package io.michaelfay.fabrichtmltext

import android.graphics.Paint.FontMetricsInt
import android.text.style.LineHeightSpan
import kotlin.math.ceil
import kotlin.math.floor

/**
 * Custom line height span that matches React Native's FabricCustomLineHeightSpan behavior.
 *
 * This span modifies font metrics to achieve a specific line height by distributing
 * "half-leading" above and below the text. This is the same approach React Native
 * uses in its TextLayoutManager for measuring text.
 *
 * Using this span in Kotlin ensures the rendered height matches the C++ measured height.
 */
class FabricCustomLineHeightSpan(height: Float) : LineHeightSpan {
    val lineHeight: Int = ceil(height.toDouble()).toInt()

    override fun chooseHeight(
        text: CharSequence,
        start: Int,
        end: Int,
        spanstartv: Int,
        v: Int,
        fm: FontMetricsInt,
    ) {
        // Calculate leading as the difference between desired line height and natural text height
        val leading = lineHeight - ((-fm.ascent) + fm.descent)

        // Distribute half-leading above and below the text
        fm.ascent -= ceil(leading / 2.0f).toInt()
        fm.descent += floor(leading / 2.0f).toInt()

        // Adjust top/bottom for first/last lines to prevent clipping
        if (start == 0) {
            fm.top = fm.ascent
        }
        if (end == text.length) {
            fm.bottom = fm.descent
        }
    }
}
