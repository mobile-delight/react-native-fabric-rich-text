package io.michaelfay.fabricrichtext

import android.graphics.Typeface
import android.util.Log
import android.view.Gravity

/**
 * Holds text style configuration from React props.
 * These values are passed from the ViewManager and must match
 * the values used in C++ ShadowNode::measureContent() for alignment.
 */
data class TextStyleConfig(
    var fontSize: Float = FabricGeneratedConstants.DEFAULT_FONT_SIZE,
    var lineHeight: Float = 0f,
    var fontWeight: String? = null,
    var fontFamily: String? = null,
    var fontStyle: String? = null,
    var letterSpacing: Float = 0f,
    var textAlign: String? = null,
    var allowFontScaling: Boolean = true,
    var maxFontSizeMultiplier: Float = 0f,
    var textColor: Int? = null
)

/**
 * Manages text styling props and applies them to views.
 * Synchronizes styling configuration from React props.
 *
 * Single Responsibility: Text style prop management and application
 */
class TextStyleApplier {

    companion object {
        private const val TAG = "TextStyleApplier"
        private val DEBUG = BuildConfig.DEBUG && false
    }

    /**
     * Callback interface for style changes.
     */
    interface StyleChangeListener {
        fun onStyleChanged()
        fun applyTextSize(sizeSp: Float)
        fun applyTextColor(color: Int)
        fun applyTypeface(typeface: Typeface)
        fun applyGravity(gravity: Int)
        fun applyLetterSpacing(spacingEm: Float)
    }

    private val config = TextStyleConfig()

    /**
     * Get current font size.
     */
    val fontSize: Float get() = config.fontSize

    /**
     * Get current line height.
     */
    val lineHeight: Float get() = config.lineHeight

    /**
     * Get current text alignment.
     */
    val textAlign: String? get() = config.textAlign

    /**
     * Sets the font size.
     * @return true if the value changed
     */
    fun setFontSize(fontSize: Float, listener: StyleChangeListener): Boolean {
        val newSize = if (fontSize > 0) fontSize else FabricGeneratedConstants.DEFAULT_FONT_SIZE
        if (config.fontSize != newSize) {
            config.fontSize = newSize
            listener.applyTextSize(newSize)
            if (DEBUG) {
                Log.d(TAG, "[Props] setFontSize: $newSize")
            }
            listener.onStyleChanged()
            return true
        }
        return false
    }

    /**
     * Sets the line height.
     * Line height is handled by FabricCustomLineHeightSpan in the Spannable.
     * @return true if the value changed
     */
    fun setLineHeight(lineHeight: Float, listener: StyleChangeListener): Boolean {
        if (config.lineHeight != lineHeight) {
            config.lineHeight = lineHeight
            // Line height is handled by FabricCustomLineHeightSpan
            listener.onStyleChanged()
            return true
        }
        return false
    }

    /**
     * Sets the font weight.
     * @return true if the value changed
     */
    fun setFontWeight(fontWeight: String?, listener: StyleChangeListener): Boolean {
        if (config.fontWeight != fontWeight) {
            config.fontWeight = fontWeight
            applyTypeface(listener)
            listener.onStyleChanged()
            return true
        }
        return false
    }

    /**
     * Sets the font family.
     * @return true if the value changed
     */
    fun setFontFamily(fontFamily: String?, listener: StyleChangeListener): Boolean {
        if (config.fontFamily != fontFamily) {
            config.fontFamily = fontFamily
            applyTypeface(listener)
            listener.onStyleChanged()
            return true
        }
        return false
    }

    /**
     * Sets the font style (italic, normal).
     * @return true if the value changed
     */
    fun setFontStyle(fontStyle: String?, listener: StyleChangeListener): Boolean {
        if (config.fontStyle != fontStyle) {
            config.fontStyle = fontStyle
            applyTypeface(listener)
            listener.onStyleChanged()
            return true
        }
        return false
    }

    /**
     * Sets the letter spacing.
     * Android letterSpacing is in ems, React Native is in pt.
     * @return true if the value changed
     */
    fun setLetterSpacing(letterSpacing: Float, listener: StyleChangeListener): Boolean {
        if (config.letterSpacing != letterSpacing) {
            config.letterSpacing = letterSpacing
            if (letterSpacing != 0f) {
                // Convert: letterSpacing (pt) / fontSize (sp) = ems
                val spacingEm = letterSpacing / config.fontSize
                listener.applyLetterSpacing(spacingEm)
            }
            listener.onStyleChanged()
            return true
        }
        return false
    }

    /**
     * Sets text alignment.
     * @return true if the value changed
     */
    fun setTextAlign(textAlign: String?, listener: StyleChangeListener): Boolean {
        if (config.textAlign != textAlign) {
            config.textAlign = textAlign
            val gravity = when (textAlign) {
                "center" -> Gravity.CENTER_HORIZONTAL
                "right" -> Gravity.END
                "justify" -> Gravity.START // Android doesn't support justify directly
                else -> Gravity.START
            }
            listener.applyGravity(gravity)
            return true
        }
        return false
    }

    /**
     * Sets whether font scaling is allowed.
     * Note: Font scaling is handled in C++ measurement, Kotlin just stores the value.
     * @return true if the value changed
     */
    fun setAllowFontScaling(allowFontScaling: Boolean, listener: StyleChangeListener): Boolean {
        if (config.allowFontScaling != allowFontScaling) {
            config.allowFontScaling = allowFontScaling
            listener.onStyleChanged()
            return true
        }
        return false
    }

    /**
     * Sets the max font size multiplier.
     * Note: Max multiplier is handled in C++ measurement, Kotlin just stores the value.
     * @return true if the value changed
     */
    fun setMaxFontSizeMultiplier(maxFontSizeMultiplier: Float, listener: StyleChangeListener): Boolean {
        if (config.maxFontSizeMultiplier != maxFontSizeMultiplier) {
            config.maxFontSizeMultiplier = maxFontSizeMultiplier
            listener.onStyleChanged()
            return true
        }
        return false
    }

    /**
     * Sets the text color.
     * @return true if the value changed
     */
    fun setTextColor(color: Int, listener: StyleChangeListener): Boolean {
        if (config.textColor != color && color != 0) {
            config.textColor = color
            listener.applyTextColor(color)
            return true
        }
        return false
    }

    /**
     * Apply typeface based on current font weight, style, and family.
     */
    private fun applyTypeface(listener: StyleChangeListener) {
        val isBold = FabricGeneratedConstants.isBoldWeight(config.fontWeight)
        val isItalic = FabricGeneratedConstants.isItalicStyle(config.fontStyle)

        val style = when {
            isBold && isItalic -> Typeface.BOLD_ITALIC
            isBold -> Typeface.BOLD
            isItalic -> Typeface.ITALIC
            else -> Typeface.NORMAL
        }

        val family = when (config.fontFamily) {
            "serif" -> Typeface.SERIF
            "monospace" -> Typeface.MONOSPACE
            else -> Typeface.DEFAULT
        }

        listener.applyTypeface(Typeface.create(family, style))
    }

    /**
     * Create a BaseTextStyle from current configuration.
     * Used for FabricRichSpannableBuilder.
     */
    fun createBaseTextStyle(): BaseTextStyle {
        return BaseTextStyle(
            fontSize = config.fontSize,
            lineHeight = config.lineHeight,
            fontWeight = config.fontWeight,
            fontFamily = config.fontFamily,
            fontStyle = config.fontStyle,
            letterSpacing = config.letterSpacing,
            textAlign = config.textAlign,
            color = config.textColor
        )
    }
}
