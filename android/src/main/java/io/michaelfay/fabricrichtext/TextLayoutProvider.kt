package io.michaelfay.fabricrichtext

import android.os.Build
import android.text.BoringLayout
import android.text.Layout
import android.text.Spannable
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import android.util.Log
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.min

/**
 * Creates text layouts using parameters that match TextLayoutManager.createLayout().
 * Ensures rendered layout matches the measured layout from C++.
 *
 * Single Responsibility: StaticLayout/BoringLayout creation with proper configuration
 *
 * See: ReactAndroid/.../views/text/TextLayoutManager.kt lines 520-575
 */
class TextLayoutProvider(
    private val textPaint: TextPaint,
    private val includeFontPadding: Boolean
) {

    companion object {
        private const val TAG = "TextLayoutProvider"
        private val DEBUG = BuildConfig.DEBUG && false
    }

    /**
     * Detects if text starts with RTL script based on first strong directional character.
     * This matches Android's BidiFormatter logic and Unicode Bidirectional Algorithm.
     *
     * @param text The text to analyze
     * @return true if text starts with RTL content
     */
    fun detectTextDirectionRTL(text: CharSequence): Boolean {
        for (i in 0 until text.length) {
            val dir = Character.getDirectionality(text[i])
            when (dir) {
                Character.DIRECTIONALITY_RIGHT_TO_LEFT,
                Character.DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC,
                Character.DIRECTIONALITY_RIGHT_TO_LEFT_EMBEDDING,
                Character.DIRECTIONALITY_RIGHT_TO_LEFT_OVERRIDE -> return true
                Character.DIRECTIONALITY_LEFT_TO_RIGHT,
                Character.DIRECTIONALITY_LEFT_TO_RIGHT_EMBEDDING,
                Character.DIRECTIONALITY_LEFT_TO_RIGHT_OVERRIDE -> return false
                // Skip neutral/weak characters (spaces, punctuation, etc.)
            }
        }
        return false // Default to LTR if no strong characters found
    }

    /**
     * Creates a Layout using the EXACT same parameters as TextLayoutManager.createLayout().
     * This ensures the rendered layout matches the measured layout from C++.
     *
     * @param text The spannable text to layout
     * @param availableWidth Available width for layout
     * @param isRTL Explicit RTL setting from props
     * @param textAlign Text alignment setting ("left", "center", "right")
     * @param numberOfLines Maximum lines (0 = unlimited)
     * @return A Layout (StaticLayout or BoringLayout) matching C++ measurement
     */
    fun createLayout(
        text: Spannable,
        availableWidth: Int,
        isRTL: Boolean,
        textAlign: String?,
        numberOfLines: Int
    ): Layout {
        // Determine effective RTL: explicit isRTL prop OR auto-detect from text content
        val effectiveRTL = isRTL || detectTextDirectionRTL(text)

        if (DEBUG) {
            Log.d(TAG, "[Layout] isRTL=$isRTL, detectTextDirectionRTL=${detectTextDirectionRTL(text)}, effectiveRTL=$effectiveRTL")
        }

        // Select text direction heuristic based on effective RTL setting
        // When RTL is detected/forced, use RTL (not FIRSTSTRONG_RTL) to ensure
        // paragraph direction is RTL for proper ALIGN_NORMAL alignment
        val textDirectionHeuristic = if (effectiveRTL) {
            TextDirectionHeuristics.RTL
        } else {
            TextDirectionHeuristics.FIRSTSTRONG_LTR
        }

        // Check if text is "boring" (single line, no special features)
        // Matches TextLayoutManager.isBoring() behavior
        val boring = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            BoringLayout.isBoring(text, textPaint)
        } else {
            BoringLayout.isBoring(text, textPaint, textDirectionHeuristic, true, null)
        }

        // TextLayoutManager alignment mapping
        // IMPORTANT: ALIGN_NORMAL means "start of paragraph direction"
        // - For LTR text: ALIGN_NORMAL = left, ALIGN_OPPOSITE = right
        // - For RTL text: ALIGN_NORMAL = right, ALIGN_OPPOSITE = left
        // Since we set textDirectionHeuristic for RTL text, ALIGN_NORMAL gives us right-alignment
        val alignment = when (textAlign) {
            "center" -> Layout.Alignment.ALIGN_CENTER
            "right" -> if (effectiveRTL) Layout.Alignment.ALIGN_NORMAL else Layout.Alignment.ALIGN_OPPOSITE
            "left" -> if (effectiveRTL) Layout.Alignment.ALIGN_OPPOSITE else Layout.Alignment.ALIGN_NORMAL
            else -> Layout.Alignment.ALIGN_NORMAL  // Natural alignment: start of paragraph direction
        }

        // If boring text fits in width and numberOfLines allows single line, use BoringLayout
        if (boring != null && boring.width <= floor(availableWidth.toFloat()) && (numberOfLines == 0 || numberOfLines == 1)) {
            if (DEBUG) {
                Log.d(TAG, "[Layout] Using BoringLayout: width=${boring.width}, availableWidth=$availableWidth")
            }
            return BoringLayout.make(
                text, textPaint, availableWidth, alignment, 1f, 0f, boring, includeFontPadding
            )
        }

        // Calculate layout width
        // For RTL text, always use availableWidth so alignment can take effect
        // For LTR text, use the smaller of desired and available (matches TextLayoutManager)
        val desiredWidth = ceil(Layout.getDesiredWidth(text, textPaint)).toInt()
        val layoutWidth = if (effectiveRTL) availableWidth else min(desiredWidth, availableWidth)

        if (DEBUG) {
            Log.d(TAG, "[Layout] Using StaticLayout: desiredWidth=$desiredWidth, layoutWidth=$layoutWidth, availableWidth=$availableWidth, numberOfLines=$numberOfLines")
        }

        // Build StaticLayout with EXACT same parameters as TextLayoutManager.createLayout()
        val builder = StaticLayout.Builder.obtain(text, 0, text.length, textPaint, layoutWidth)
            .setAlignment(alignment)
            .setLineSpacing(0f, 1f)  // CRITICAL: Must match TextLayoutManager
            .setIncludePad(includeFontPadding)
            .setBreakStrategy(Layout.BREAK_STRATEGY_HIGH_QUALITY)
            .setHyphenationFrequency(Layout.HYPHENATION_FREQUENCY_NONE)
            .setTextDirection(textDirectionHeuristic)  // Apply RTL direction if set

        // NOTE: We do NOT use StaticLayout's built-in ellipsis (setMaxLines/setEllipsize)
        // because we need smart word-boundary truncation matching iOS behavior.
        // Truncation is handled manually in TextTruncationEngine instead.
        // The layout is created with all lines so we can properly detect truncation
        // and calculate where to apply word-boundary-aware ellipsis.

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setUseLineSpacingFromFallbacks(true)
        }

        return builder.build()
    }
}
