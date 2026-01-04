package io.michaelfay.fabrichtmltext

import android.graphics.Typeface
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.style.AbsoluteSizeSpan
import android.text.style.StrikethroughSpan
import android.text.style.StyleSpan
import android.text.style.UnderlineSpan
import android.util.Log
import com.facebook.react.common.mapbuffer.ReadableMapBuffer
import com.facebook.react.uimanager.PixelUtil

/**
 * Represents a parsed text fragment from C++ AttributedString.
 * Each fragment has text content and associated text attributes.
 */
data class TextFragment(
    val text: String,
    val fontSize: Float,
    val lineHeight: Float,
    val fontWeight: String?,
    val fontStyle: String?,
    val fontFamily: String?,
    val letterSpacing: Float,
    val foregroundColor: Int?,
    val backgroundColor: Int?,
    val allowFontScaling: Boolean,
    val textDecorationLine: String?,
    val linkUrl: String? = null  // href URL for <a> tags, null if not a link
)

/**
 * Parses MapBuffer from C++ FabricHTMLTextViewState into TextFragment objects.
 *
 * This enables the Kotlin view to render using the same parsed data
 * that C++ used for measurement, eliminating duplicate HTML parsing
 * and ensuring perfect measurement/rendering alignment.
 *
 * MapBuffer format (matches React Native's AttributedString serialization):
 * - AS_KEY_HASH = 0
 * - AS_KEY_STRING = 1
 * - AS_KEY_FRAGMENTS = 2
 * - AS_KEY_CACHE_ID = 3
 * - AS_KEY_BASE_ATTRIBUTES = 4
 *
 * Fragment format:
 * - FR_KEY_STRING = 0
 * - FR_KEY_REACT_TAG = 1
 * - FR_KEY_IS_ATTACHMENT = 2
 * - FR_KEY_WIDTH = 3
 * - FR_KEY_HEIGHT = 4
 * - FR_KEY_TEXT_ATTRIBUTES = 5
 *
 * TextAttributes format:
 * - TA_KEY_FOREGROUND_COLOR = 0
 * - TA_KEY_BACKGROUND_COLOR = 1
 * - TA_KEY_FONT_SIZE = 4
 * - TA_KEY_FONT_WEIGHT = 6
 * - TA_KEY_FONT_STYLE = 7
 * - TA_KEY_ALLOW_FONT_SCALING = 9
 * - TA_KEY_LETTER_SPACING = 10
 * - TA_KEY_LINE_HEIGHT = 11
 */
object FabricHTMLFragmentParser {
    private const val TAG = "FabricHTMLFragmentParser"
    private const val DEBUG = false

    // State keys (from FabricHTMLTextViewState.cpp)
    private const val HTML_STATE_KEY_ATTRIBUTED_STRING = 0
    private const val HTML_STATE_KEY_PARAGRAPH_ATTRIBUTES = 1
    private const val HTML_STATE_KEY_HASH = 2
    private const val HTML_STATE_KEY_LINK_URLS = 3

    // AttributedString keys (from conversions.h)
    private const val AS_KEY_HASH = 0
    private const val AS_KEY_STRING = 1
    private const val AS_KEY_FRAGMENTS = 2
    private const val AS_KEY_CACHE_ID = 3
    private const val AS_KEY_BASE_ATTRIBUTES = 4

    // Fragment keys
    private const val FR_KEY_STRING = 0
    private const val FR_KEY_REACT_TAG = 1
    private const val FR_KEY_IS_ATTACHMENT = 2
    private const val FR_KEY_WIDTH = 3
    private const val FR_KEY_HEIGHT = 4
    private const val FR_KEY_TEXT_ATTRIBUTES = 5

    // TextAttributes keys
    private const val TA_KEY_FOREGROUND_COLOR = 0
    private const val TA_KEY_BACKGROUND_COLOR = 1
    private const val TA_KEY_OPACITY = 2
    private const val TA_KEY_FONT_FAMILY = 3
    private const val TA_KEY_FONT_SIZE = 4
    private const val TA_KEY_FONT_SIZE_MULTIPLIER = 5
    private const val TA_KEY_FONT_WEIGHT = 6
    private const val TA_KEY_FONT_STYLE = 7
    private const val TA_KEY_FONT_VARIANT = 8
    private const val TA_KEY_ALLOW_FONT_SCALING = 9
    private const val TA_KEY_LETTER_SPACING = 10
    private const val TA_KEY_LINE_HEIGHT = 11
    private const val TA_KEY_TEXT_DECORATION_LINE = 15

    /**
     * Parses the state MapBuffer into a list of TextFragment objects.
     */
    fun parseState(stateMapBuffer: ReadableMapBuffer): List<TextFragment> {
        if (DEBUG) {
            Log.d(TAG, "Parsing state MapBuffer")
        }

        // Get the AttributedString MapBuffer from state
        if (!stateMapBuffer.contains(HTML_STATE_KEY_ATTRIBUTED_STRING)) {
            Log.w(TAG, "State does not contain attributed string")
            return emptyList()
        }

        // Extract link URLs if present (fragment index -> URL string)
        // Keys are fragment indices (sparse), values are URL strings
        val linkUrls = mutableMapOf<Int, String>()
        if (stateMapBuffer.contains(HTML_STATE_KEY_LINK_URLS)) {
            val linkUrlsBuffer = stateMapBuffer.getMapBuffer(HTML_STATE_KEY_LINK_URLS)
            if (DEBUG) {
                Log.d(TAG, "Found linkUrls MapBuffer with ${linkUrlsBuffer.count} entries")
            }
            // Iterate over the MapBuffer's entries using its iterator
            // Each entry has a key (fragment index) and value (URL string)
            val iterator = linkUrlsBuffer.iterator()
            while (iterator.hasNext()) {
                val entry = iterator.next()
                val fragmentIndex = entry.key
                try {
                    val url = linkUrlsBuffer.getString(fragmentIndex)
                    if (url.isNotEmpty()) {
                        linkUrls[fragmentIndex] = url
                        if (DEBUG) {
                            Log.d(TAG, "  linkUrls[$fragmentIndex] = '$url'")
                        }
                    }
                } catch (e: Exception) {
                    // Key might not exist or be wrong type, skip
                    if (DEBUG) {
                        Log.d(TAG, "  linkUrls[$fragmentIndex] - error: ${e.message}")
                    }
                }
            }
        } else {
            if (DEBUG) {
                Log.d(TAG, "No linkUrls in state")
            }
        }

        val attributedStringBuffer = stateMapBuffer.getMapBuffer(HTML_STATE_KEY_ATTRIBUTED_STRING)
        return parseAttributedString(attributedStringBuffer, linkUrls)
    }

    /**
     * Parses an AttributedString MapBuffer into fragments.
     */
    private fun parseAttributedString(
        buffer: ReadableMapBuffer,
        linkUrls: Map<Int, String> = emptyMap()
    ): List<TextFragment> {
        val fragments = mutableListOf<TextFragment>()

        if (!buffer.contains(AS_KEY_FRAGMENTS)) {
            Log.w(TAG, "AttributedString does not contain fragments")
            return fragments
        }

        val fragmentsBuffer = buffer.getMapBuffer(AS_KEY_FRAGMENTS)
        val fragmentCount = fragmentsBuffer.count

        if (DEBUG) {
            val fullString = if (buffer.contains(AS_KEY_STRING)) buffer.getString(AS_KEY_STRING) else ""
            Log.d(TAG, "Parsing $fragmentCount fragments, full string: '${fullString.take(50)}...'")
        }

        for (i in 0 until fragmentCount) {
            val fragmentBuffer = fragmentsBuffer.getMapBuffer(i)
            val linkUrl = linkUrls[i]  // Get link URL for this fragment index
            val fragment = parseFragment(fragmentBuffer, linkUrl)
            if (fragment != null) {
                fragments.add(fragment)
            }
        }

        if (DEBUG) {
            Log.d(TAG, "Parsed ${fragments.size} fragments")
        }

        return fragments
    }

    /**
     * Parses a single Fragment MapBuffer.
     */
    private fun parseFragment(buffer: ReadableMapBuffer, linkUrl: String? = null): TextFragment? {
        // Get text content
        val text = if (buffer.contains(FR_KEY_STRING)) {
            buffer.getString(FR_KEY_STRING)
        } else {
            return null
        }

        if (text.isEmpty()) {
            return null
        }

        // Get text attributes
        val textAttrsBuffer = if (buffer.contains(FR_KEY_TEXT_ATTRIBUTES)) {
            buffer.getMapBuffer(FR_KEY_TEXT_ATTRIBUTES)
        } else {
            null
        }

        val fontSize = textAttrsBuffer?.let {
            if (it.contains(TA_KEY_FONT_SIZE)) it.getDouble(TA_KEY_FONT_SIZE).toFloat() else FabricGeneratedConstants.DEFAULT_FONT_SIZE
        } ?: FabricGeneratedConstants.DEFAULT_FONT_SIZE

        val lineHeight = textAttrsBuffer?.let {
            if (it.contains(TA_KEY_LINE_HEIGHT)) it.getDouble(TA_KEY_LINE_HEIGHT).toFloat() else 0f
        } ?: 0f

        val fontWeight = textAttrsBuffer?.let {
            if (it.contains(TA_KEY_FONT_WEIGHT)) it.getString(TA_KEY_FONT_WEIGHT) else null
        }

        val fontStyle = textAttrsBuffer?.let {
            if (it.contains(TA_KEY_FONT_STYLE)) it.getString(TA_KEY_FONT_STYLE) else null
        }

        val fontFamily = textAttrsBuffer?.let {
            if (it.contains(TA_KEY_FONT_FAMILY)) it.getString(TA_KEY_FONT_FAMILY) else null
        }

        val letterSpacing = textAttrsBuffer?.let {
            if (it.contains(TA_KEY_LETTER_SPACING)) it.getDouble(TA_KEY_LETTER_SPACING).toFloat() else 0f
        } ?: 0f

        val foregroundColor = textAttrsBuffer?.let {
            if (it.contains(TA_KEY_FOREGROUND_COLOR)) {
                val color = it.getInt(TA_KEY_FOREGROUND_COLOR)
                if (DEBUG) {
                    Log.d(TAG, "Fragment foregroundColor: 0x${color.toUInt().toString(16).uppercase()} (decimal=$color)")
                }
                color
            } else {
                if (DEBUG) {
                    Log.d(TAG, "Fragment foregroundColor: NOT PRESENT in MapBuffer")
                }
                null
            }
        }

        // backgroundColor: Parsed from C++ AttributedString for React Native Text compatibility.
        // React Native's AttributedString includes backgroundColor in its fragment attributes.
        val backgroundColor = textAttrsBuffer?.let {
            if (it.contains(TA_KEY_BACKGROUND_COLOR)) it.getInt(TA_KEY_BACKGROUND_COLOR) else null
        }

        val allowFontScaling = textAttrsBuffer?.let {
            if (it.contains(TA_KEY_ALLOW_FONT_SCALING)) it.getBoolean(TA_KEY_ALLOW_FONT_SCALING) else true
        } ?: true

        val textDecorationLine = textAttrsBuffer?.let {
            if (it.contains(TA_KEY_TEXT_DECORATION_LINE)) it.getString(TA_KEY_TEXT_DECORATION_LINE) else null
        }

        if (DEBUG) {
            Log.d(TAG, "Fragment: text='${text.take(20)}...' fontSize=$fontSize lineHeight=$lineHeight fontWeight=$fontWeight textDecorationLine=$textDecorationLine linkUrl=$linkUrl")
        }

        return TextFragment(
            text = text,
            fontSize = fontSize,
            lineHeight = lineHeight,
            fontWeight = fontWeight,
            fontStyle = fontStyle,
            fontFamily = fontFamily,
            letterSpacing = letterSpacing,
            foregroundColor = foregroundColor,
            backgroundColor = backgroundColor,
            allowFontScaling = allowFontScaling,
            textDecorationLine = textDecorationLine,
            linkUrl = linkUrl
        )
    }

    /**
     * Builds a Spannable from parsed fragments.
     * This replaces the FabricHtmlSpannableBuilder for state-based rendering.
     *
     * Uses React Native's PixelUtil for unit conversion to ensure pixel-perfect
     * alignment between C++ measurement and Kotlin rendering.
     *
     * @param fragments List of parsed text fragments
     */
    fun buildSpannableFromFragments(fragments: List<TextFragment>): Spannable {
        val builder = SpannableStringBuilder()

        for (fragment in fragments) {
            val startPos = builder.length
            builder.append(fragment.text)
            val endPos = builder.length

            if (startPos < endPos) {
                // Apply font size
                builder.setSpan(
                    AbsoluteSizeSpan(fragment.fontSize.toInt(), true), // true = size in SP
                    startPos,
                    endPos,
                    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                )

                // Apply font weight
                val isBold = FabricGeneratedConstants.isBoldWeight(fragment.fontWeight)
                val isItalic = FabricGeneratedConstants.isItalicStyle(fragment.fontStyle)

                val style = when {
                    isBold && isItalic -> Typeface.BOLD_ITALIC
                    isBold -> Typeface.BOLD
                    isItalic -> Typeface.ITALIC
                    else -> null
                }

                if (style != null) {
                    builder.setSpan(
                        StyleSpan(style),
                        startPos,
                        endPos,
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }

                // Apply line height via FabricCustomLineHeightSpan
                // Uses React Native's PixelUtil for conversion - this is the exact same code path
                // that TextLayoutManager uses for measurement, ensuring pixel-perfect alignment.
                // - PixelUtil.toPixelFromSP() when allowFontScaling=true (respects font scale)
                // - PixelUtil.toPixelFromDIP() when allowFontScaling=false (ignores font scale)
                if (fragment.lineHeight > 0) {
                    val lineHeightPx = if (fragment.allowFontScaling) {
                        PixelUtil.toPixelFromSP(fragment.lineHeight)
                    } else {
                        PixelUtil.toPixelFromDIP(fragment.lineHeight)
                    }
                    if (DEBUG) {
                        val unitName = if (fragment.allowFontScaling) "SP" else "DIP"
                        Log.d(TAG, "Applying FabricCustomLineHeightSpan: ${fragment.lineHeight} ($unitName) -> ${lineHeightPx}px")
                    }
                    builder.setSpan(
                        FabricCustomLineHeightSpan(lineHeightPx),
                        startPos,
                        endPos,
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }

                // Apply foreground color if specified
                if (fragment.foregroundColor != null) {
                    if (DEBUG) {
                        Log.d(TAG, "Applying ForegroundColorSpan: 0x${fragment.foregroundColor.toUInt().toString(16).uppercase()} to range [$startPos, $endPos] text='${fragment.text.take(20)}'")
                    }
                    builder.setSpan(
                        android.text.style.ForegroundColorSpan(fragment.foregroundColor),
                        startPos,
                        endPos,
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                } else {
                    if (DEBUG) {
                        Log.d(TAG, "No ForegroundColorSpan for range [$startPos, $endPos] text='${fragment.text.take(20)}'")
                    }
                }

                // Apply background color if specified
                if (fragment.backgroundColor != null) {
                    builder.setSpan(
                        android.text.style.BackgroundColorSpan(fragment.backgroundColor),
                        startPos,
                        endPos,
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }

                // Apply text decoration (underline, strikethrough)
                // Values from C++ toString(TextDecorationLineType): "none", "underline", "strikethrough", "underline-strikethrough"
                when (fragment.textDecorationLine) {
                    "underline" -> {
                        builder.setSpan(
                            UnderlineSpan(),
                            startPos,
                            endPos,
                            Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                        )
                    }
                    "strikethrough" -> {
                        builder.setSpan(
                            StrikethroughSpan(),
                            startPos,
                            endPos,
                            Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                        )
                    }
                    "underline-strikethrough" -> {
                        builder.setSpan(
                            UnderlineSpan(),
                            startPos,
                            endPos,
                            Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                        )
                        builder.setSpan(
                            StrikethroughSpan(),
                            startPos,
                            endPos,
                            Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                        )
                    }
                }

                // Apply link span for <a href="..."> tags
                if (!fragment.linkUrl.isNullOrEmpty()) {
                    if (DEBUG) {
                        Log.d(TAG, "Creating HrefClickableSpan for linkUrl='${fragment.linkUrl}' at range [$startPos, $endPos]")
                    }
                    builder.setSpan(
                        HrefClickableSpan(fragment.linkUrl),
                        startPos,
                        endPos,
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
            }
        }

        if (DEBUG) {
            Log.d(TAG, "Built Spannable with ${builder.length} chars from ${fragments.size} fragments")
        }

        return builder
    }
}
