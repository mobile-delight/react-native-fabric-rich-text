package io.michaelfay.fabrichtmltext

import android.graphics.Color
import io.michaelfay.fabrichtmltext.BuildConfig
import android.graphics.Typeface
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import android.text.style.ClickableSpan
import android.text.style.ForegroundColorSpan
import android.text.style.LeadingMarginSpan
import android.text.style.StyleSpan
import android.text.style.StrikethroughSpan
import android.text.style.UnderlineSpan
import android.view.View

class HrefClickableSpan(val href: String) : ClickableSpan() {
    override fun onClick(widget: View) {
        // Click handling is delegated to the containing view
    }

    override fun updateDrawState(ds: TextPaint) {
        super.updateDrawState(ds)
        ds.isUnderlineText = true
    }
}

/**
 * Base text style configuration from React props.
 * These values are passed from the ViewManager and must match
 * the values used in C++ ShadowNode::measureContent() for alignment.
 */
data class BaseTextStyle(
    val fontSize: Float = FabricGeneratedConstants.DEFAULT_FONT_SIZE,
    val lineHeight: Float = 0f,
    val fontWeight: String? = null,
    val fontFamily: String? = null,
    val fontStyle: String? = null,
    val letterSpacing: Float = 0f,
    val textAlign: String? = null,
    val color: Int? = null
)

class FabricHtmlSpannableBuilder {

    companion object {
        private const val TAG = "FabricHtmlSpannableBuilder"
        // Use BuildConfig.DEBUG to exclude debug code from production builds
        private val DEBUG = BuildConfig.DEBUG
    }

    private var tagStyles: Map<String, Map<String, Any>> = emptyMap()
    private var baseStyle: BaseTextStyle = BaseTextStyle()

    fun setTagStyles(styles: Map<String, Map<String, Any>>?) {
        this.tagStyles = styles ?: emptyMap()
    }

    fun setBaseStyle(style: BaseTextStyle) {
        this.baseStyle = style
        if (DEBUG) {
            android.util.Log.d(TAG, "[BaseStyle] fontSize=${style.fontSize}, lineHeight=${style.lineHeight}")
        }
    }

    private enum class ListType { UNORDERED, ORDERED }

    private data class ListContext(
        val type: ListType,
        var itemCounter: Int,
        val nestingLevel: Int
    )

    private data class LinkInfo(val startPosition: Int, val href: String)

    private data class ListItemInfo(val startPosition: Int, val nestingLevel: Int)

    private data class TagInfo(val tag: String, val startPosition: Int)

    private data class ParseState(
        var inParagraph: Boolean = false,
        var currentHeading: String? = null,
        var headingStartPosition: Int? = null,
        val boldStartPositions: MutableList<Int> = mutableListOf(),
        val italicStartPositions: MutableList<Int> = mutableListOf(),
        val linkStack: MutableList<LinkInfo> = mutableListOf(),
        val listStack: MutableList<ListContext> = mutableListOf(),
        val pendingListItemStack: MutableList<ListItemInfo> = mutableListOf(),
        val tagStack: MutableList<TagInfo> = mutableListOf()
    )

    fun buildSpannable(html: String): Spannable {
        if (html.isEmpty()) {
            return SpannableStringBuilder()
        }

        val result = SpannableStringBuilder()
        val state = ParseState()
        var position = 0

        while (position < html.length) {
            if (html[position] == '<') {
                val tagResult = parseTag(html, position)
                if (tagResult != null) {
                    val (tag, isClosing, endPosition, attributes) = tagResult
                    handleTag(tag.lowercase(), isClosing, result, state, attributes)
                    position = endPosition
                    continue
                }
            }

            val textEnd = html.indexOf('<', position).takeIf { it >= 0 } ?: html.length
            val text = html.substring(position, textEnd)

            if (text.isNotEmpty()) {
                result.append(text)
            }

            position = textEnd
        }

        trimTrailingNewlines(result)

        if (DEBUG) {
            val text = result.toString()
            val escapedText = text.replace("\n", "\\n").replace(" ", "·")
            android.util.Log.d(TAG, "[Kotlin] Final text length: ${text.length}")
            android.util.Log.d(TAG, "[Kotlin] Final text: '$escapedText'")
            android.util.Log.d(TAG, "[Kotlin] Line count: ${text.count { it == '\n' } + 1}")
        }

        return result
    }

    private fun handleTag(
        tag: String,
        isClosing: Boolean,
        result: SpannableStringBuilder,
        state: ParseState,
        attributes: Map<String, String> = emptyMap()
    ) {
        when (tag) {
            "strong", "b" -> handleBoldTag(isClosing, result, state.boldStartPositions, state)
            "em", "i" -> handleItalicTag(isClosing, result, state.italicStartPositions, state)
            "p" -> handleParagraphTag(isClosing, result, state)
            "h1", "h2", "h3", "h4", "h5", "h6" -> handleHeadingTag(tag, isClosing, result, state)
            "a" -> handleLinkTag(isClosing, result, state, attributes)
            "ul" -> handleUnorderedListTag(isClosing, state, result)
            "ol" -> handleOrderedListTag(isClosing, state, result)
            "li" -> handleListItemTag(isClosing, result, state)
        }
    }

    private fun handleUnorderedListTag(isClosing: Boolean, state: ParseState, result: SpannableStringBuilder) {
        if (isClosing) {
            if (state.listStack.isNotEmpty()) {
                state.listStack.removeAt(state.listStack.lastIndex)
            }
            // Add paragraph spacing after top-level list ends (not nested lists)
            if (state.listStack.isEmpty() && result.isNotEmpty()) {
                result.append("\n")
            }
        } else {
            // Add newline before nested list (when inside another list)
            if (state.listStack.isNotEmpty() && result.isNotEmpty() && result[result.length - 1] != '\n') {
                result.append("\n")
            }
            val nestingLevel = minOf(state.listStack.size + 1, FabricGeneratedConstants.MAX_LIST_NESTING_LEVEL)
            state.listStack.add(ListContext(ListType.UNORDERED, 0, nestingLevel))
        }
    }

    private fun handleOrderedListTag(isClosing: Boolean, state: ParseState, result: SpannableStringBuilder) {
        if (isClosing) {
            if (state.listStack.isNotEmpty()) {
                state.listStack.removeAt(state.listStack.lastIndex)
            }
            // Add paragraph spacing after top-level list ends (not nested lists)
            if (state.listStack.isEmpty() && result.isNotEmpty()) {
                result.append("\n")
            }
        } else {
            // Add newline before nested list (when inside another list)
            if (state.listStack.isNotEmpty() && result.isNotEmpty() && result[result.length - 1] != '\n') {
                result.append("\n")
            }
            val nestingLevel = minOf(state.listStack.size + 1, FabricGeneratedConstants.MAX_LIST_NESTING_LEVEL)
            state.listStack.add(ListContext(ListType.ORDERED, 0, nestingLevel))
        }
    }

    private fun handleListItemTag(isClosing: Boolean, result: SpannableStringBuilder, state: ParseState) {
        if (isClosing) {
            if (state.pendingListItemStack.isNotEmpty()) {
                val itemInfo = state.pendingListItemStack.removeAt(state.pendingListItemStack.lastIndex)
                applyListItemFormatting(result, itemInfo.startPosition, itemInfo.nestingLevel)
                // Note: Screen reader pauses are handled via resolvedAccessibilityLabel
                // (built by C++ parser) rather than modifying the rendered text
            }
        } else {
            if (state.listStack.isNotEmpty()) {
                val listIndex = state.listStack.lastIndex
                state.listStack[listIndex].itemCounter++
                val currentList = state.listStack[listIndex]

                // Add newline before this item if it's not the first item in the list
                // (itemCounter is already incremented, so > 1 means not first)
                if (currentList.itemCounter > 1 && result.isNotEmpty() && result[result.length - 1] != '\n') {
                    result.append("\n")
                }

                val marker = if (currentList.type == ListType.UNORDERED) {
                    FabricGeneratedConstants.BULLET_MARKER
                } else {
                    "${currentList.itemCounter}. "
                }

                result.append(marker)
                state.pendingListItemStack.add(ListItemInfo(result.length - marker.length, currentList.nestingLevel))
            }
        }
    }

    private fun applyListItemFormatting(result: SpannableStringBuilder, startPosition: Int, nestingLevel: Int) {
        val indent = nestingLevel * FabricGeneratedConstants.LIST_INDENT_PX
        if (startPosition < result.length) {
            result.setSpan(
                LeadingMarginSpan.Standard(indent),
                startPosition,
                result.length,
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }
    }

    private fun handleLinkTag(
        isClosing: Boolean,
        result: SpannableStringBuilder,
        state: ParseState,
        attributes: Map<String, String>
    ) {
        if (isClosing) {
            if (state.linkStack.isNotEmpty()) {
                val linkInfo = state.linkStack.removeAt(state.linkStack.lastIndex)
                val startPos = linkInfo.startPosition
                if (startPos < result.length) {
                    result.setSpan(
                        HrefClickableSpan(linkInfo.href),
                        startPos,
                        result.length,
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )

                    // Check for tagStyles for "a" tag - if present, use custom styling
                    val tagStyle = getTagStyle("a")
                    if (tagStyle != null) {
                        applyTagStyle(tagStyle, result, startPos, result.length)
                    } else {
                        // Default link styling: blue color and underline
                        result.setSpan(
                            ForegroundColorSpan(FabricGeneratedConstants.LINK_COLOR),
                            startPos,
                            result.length,
                            Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                        )
                        result.setSpan(
                            UnderlineSpan(),
                            startPos,
                            result.length,
                            Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                        )
                    }
                }
            }
        } else {
            val href = attributes["href"]
            if (!href.isNullOrEmpty() && isAllowedUrlScheme(href)) {
                state.linkStack.add(LinkInfo(result.length, href))
            }
        }
    }

    private fun isAllowedUrlScheme(url: String): Boolean {
        val allowedSchemes = listOf("http://", "https://", "mailto:", "tel:")
        val lowerUrl = url.lowercase().trim()
        // Allow if it starts with an allowed scheme, or is a relative/fragment URL
        return allowedSchemes.any { lowerUrl.startsWith(it) } ||
               (!lowerUrl.contains(":") || lowerUrl.startsWith("/") || lowerUrl.startsWith("#"))
    }

    private fun handleBoldTag(
        isClosing: Boolean,
        result: SpannableStringBuilder,
        boldStartPositions: MutableList<Int>,
        state: ParseState
    ) {
        if (isClosing) {
            if (boldStartPositions.isNotEmpty()) {
                val startPos = boldStartPositions.removeAt(boldStartPositions.lastIndex)
                applyStyleSpan(result, startPos, Typeface.BOLD)

                // Apply tagStyles if defined
                val tagStyle = getTagStyle("strong") ?: getTagStyle("b")
                if (tagStyle != null) {
                    applyTagStyle(tagStyle, result, startPos, result.length)
                }
            }
        } else {
            boldStartPositions.add(result.length)
            state.tagStack.add(TagInfo("strong", result.length))
        }
    }

    private fun handleItalicTag(
        isClosing: Boolean,
        result: SpannableStringBuilder,
        italicStartPositions: MutableList<Int>,
        state: ParseState
    ) {
        if (isClosing) {
            if (italicStartPositions.isNotEmpty()) {
                val startPos = italicStartPositions.removeAt(italicStartPositions.lastIndex)
                applyStyleSpan(result, startPos, Typeface.ITALIC)

                // Apply tagStyles if defined
                val tagStyle = getTagStyle("em") ?: getTagStyle("i")
                if (tagStyle != null) {
                    applyTagStyle(tagStyle, result, startPos, result.length)
                }
            }
        } else {
            italicStartPositions.add(result.length)
            state.tagStack.add(TagInfo("em", result.length))
        }
    }

    private fun handleParagraphTag(
        isClosing: Boolean,
        result: SpannableStringBuilder,
        state: ParseState
    ) {
        if (isClosing) {
            // Apply tagStyles if defined for paragraph
            val tagInfo = state.tagStack.findLast { it.tag == "p" }
            if (tagInfo != null) {
                val tagStyle = getTagStyle("p")
                if (tagStyle != null) {
                    applyTagStyle(tagStyle, result, tagInfo.startPosition, result.length)
                }
                state.tagStack.removeAll { it.startPosition == tagInfo.startPosition && it.tag == "p" }
            }

            if (state.inParagraph && result.isNotEmpty()) {
                result.append("\n")
            }
            state.inParagraph = false
        } else {
            state.tagStack.add(TagInfo("p", result.length))
            state.inParagraph = true
        }
    }

    private fun handleHeadingTag(
        tag: String,
        isClosing: Boolean,
        result: SpannableStringBuilder,
        state: ParseState
    ) {
        if (isClosing) {
            state.headingStartPosition?.let { startPos ->
                val scale = FabricGeneratedConstants.HEADING_SCALES[state.currentHeading] ?: 1.0f
                if (startPos < result.length) {
                    // KEY FIX: Use AbsoluteSizeSpan instead of RelativeSizeSpan
                    // This ensures the heading font size exactly matches the C++ measurement
                    // which calculates: baseFontSize * headingScale * fontSizeMultiplier
                    //
                    // RelativeSizeSpan is relative to the TextPaint's text size which can
                    // diverge from the value used in C++ measurement. AbsoluteSizeSpan
                    // uses the exact calculated value.
                    val baseFontSize = if (baseStyle.fontSize > 0) baseStyle.fontSize else FabricGeneratedConstants.DEFAULT_FONT_SIZE
                    val absoluteFontSize = (baseFontSize * scale).toInt()

                    if (DEBUG) {
                        android.util.Log.d(TAG, "[Heading] $tag: baseFontSize=$baseFontSize, scale=$scale, absoluteSize=$absoluteFontSize sp")
                    }

                    result.setSpan(
                        AbsoluteSizeSpan(absoluteFontSize, true), // true = size is in SP
                        startPos,
                        result.length,
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                    applyStyleSpan(result, startPos, Typeface.BOLD)

                    // Apply tagStyles if defined for heading
                    val tagStyle = getTagStyle(state.currentHeading ?: tag)
                    if (tagStyle != null) {
                        applyTagStyle(tagStyle, result, startPos, result.length)
                    }
                }
            }
            if (result.isNotEmpty()) {
                result.append("\n")
            }
            state.currentHeading = null
            state.headingStartPosition = null
        } else {
            state.currentHeading = tag
            state.headingStartPosition = result.length
            state.tagStack.add(TagInfo(tag, result.length))
        }
    }

    private fun applyStyleSpan(result: SpannableStringBuilder, startPos: Int, style: Int) {
        if (startPos < result.length) {
            result.setSpan(
                StyleSpan(style),
                startPos,
                result.length,
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }
    }

    private data class TagParseResult(
        val tag: String,
        val isClosing: Boolean,
        val endPosition: Int,
        val attributes: Map<String, String>
    )

    private fun parseTag(html: String, position: Int): TagParseResult? {
        if (position >= html.length || html[position] != '<') return null

        val start = position + 1
        if (start >= html.length) return null

        val closeIndex = html.indexOf('>', start)
        if (closeIndex < 0) return null

        var tagContent = html.substring(start, closeIndex)
        val isClosing = tagContent.startsWith("/")

        if (isClosing) {
            tagContent = tagContent.substring(1)
        }

        val tagName = tagContent.split(" ").firstOrNull()?.trim() ?: tagContent.trim()
        val attributes = parseAttributes(tagContent)
        return TagParseResult(tagName, isClosing, closeIndex + 1, attributes)
    }

    private fun parseAttributes(tagContent: String): Map<String, String> {
        val attributes = mutableMapOf<String, String>()

        val pattern = Regex("""(\w+)\s*=\s*"([^"]*)"""")
        pattern.findAll(tagContent).forEach { match ->
            val name = match.groupValues[1].lowercase()
            val value = match.groupValues[2]
            attributes[name] = value
        }

        return attributes
    }

    private fun trimTrailingNewlines(builder: SpannableStringBuilder) {
        // Trim all trailing whitespace (not just newlines) to match C++ measurement
        while (builder.isNotEmpty() && builder[builder.length - 1].isWhitespace()) {
            builder.delete(builder.length - 1, builder.length)
        }
    }

    // MARK: - TagStyles Support

    private fun getTagStyle(tag: String): Map<String, Any>? {
        return tagStyles[tag.lowercase()]
    }

    private fun applyTagStyle(
        style: Map<String, Any>,
        result: SpannableStringBuilder,
        startPos: Int,
        endPos: Int
    ) {
        if (startPos >= endPos) return

        // Parse color
        val colorValue = style["color"]
        if (colorValue is String) {
            val color = parseColor(colorValue)
            if (color != null) {
                result.setSpan(
                    ForegroundColorSpan(color),
                    startPos,
                    endPos,
                    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                )
            }
        }

        // Parse fontSize
        val fontSizeValue = style["fontSize"]
        val fontSize = when (fontSizeValue) {
            is Number -> fontSizeValue.toInt()
            is String -> fontSizeValue.toIntOrNull()
            else -> null
        }
        if (fontSize != null && fontSize > 0) {
            result.setSpan(
                AbsoluteSizeSpan(fontSize, true), // true = size is in SP
                startPos,
                endPos,
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }

        // Parse fontWeight
        val fontWeight = style["fontWeight"] as? String
        if (FabricGeneratedConstants.isBoldWeight(fontWeight)) {
            result.setSpan(
                StyleSpan(Typeface.BOLD),
                startPos,
                endPos,
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }

        // Parse fontStyle
        val fontStyle = style["fontStyle"] as? String
        if (FabricGeneratedConstants.isItalicStyle(fontStyle)) {
            result.setSpan(
                StyleSpan(Typeface.ITALIC),
                startPos,
                endPos,
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
            )
        }

        // Parse textDecorationLine
        val decoration = style["textDecorationLine"]
        if (decoration is String) {
            when (decoration) {
                "underline" -> {
                    result.setSpan(
                        UnderlineSpan(),
                        startPos,
                        endPos,
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
                "line-through" -> {
                    result.setSpan(
                        StrikethroughSpan(),
                        startPos,
                        endPos,
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
                "underline line-through", "line-through underline" -> {
                    result.setSpan(
                        UnderlineSpan(),
                        startPos,
                        endPos,
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                    result.setSpan(
                        StrikethroughSpan(),
                        startPos,
                        endPos,
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
            }
        }
    }

    private fun parseColor(colorString: String): Int? {
        val trimmed = colorString.trim()

        // Handle hex colors
        if (trimmed.startsWith("#")) {
            return try {
                Color.parseColor(trimmed)
            } catch (e: IllegalArgumentException) {
                null
            }
        }

        // Handle named colors (basic set)
        return FabricGeneratedConstants.parseNamedColor(trimmed)
    }
}
