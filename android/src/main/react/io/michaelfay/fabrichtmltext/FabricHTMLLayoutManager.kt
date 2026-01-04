package io.michaelfay.fabrichtmltext

import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import com.facebook.proguard.annotations.DoNotStrip
import com.facebook.react.bridge.ReactApplicationContext
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.ceil

/**
 * Manages HTML layout measurement and caching.
 *
 * This class bridges C++ measurement (via JNI) and Kotlin rendering by:
 * 1. Creating StaticLayout during measurement (called from C++)
 * 2. Caching the layout for later retrieval during rendering
 * 3. Ensuring the SAME StaticLayout is used for both measurement and rendering
 *
 * This mirrors React Native's PreparedLayout pattern where the same layout
 * object is used in both measureContent() and onDraw().
 */
@DoNotStrip
object FabricHTMLLayoutManager {
    // Don't set explicit line spacing - let Android use natural font metrics
    // This matches C++ which doesn't set lineHeight

    // Cache for layouts: key is (html + tagStyles + width), value is StaticLayout
    private val layoutCache = ConcurrentHashMap<String, CachedLayout>()

    // Create builder per operation to ensure thread safety
    private fun createBuilder(): FabricHtmlSpannableBuilder = FabricHtmlSpannableBuilder()

    data class CachedLayout(
        val layout: StaticLayout,
        val width: Float,
        val height: Float
    )

    /**
     * Measures HTML content and caches the resulting StaticLayout.
     * Called from C++ via JNI during measureContent().
     *
     * @param html The HTML string to measure
     * @param tagStylesJson Optional JSON string for tag styles
     * @param maxWidth Maximum width constraint in pixels
     * @param density Screen density for scaling
     * @return FloatArray of [width, height] in pixels
     */
    @JvmStatic
    @DoNotStrip
    fun measureHtml(
        html: String?,
        tagStylesJson: String?,
        maxWidth: Float,
        density: Float
    ): FloatArray {
        if (html.isNullOrEmpty()) {
            return floatArrayOf(0f, 0f)
        }

        val cacheKey = buildCacheKey(html, tagStylesJson, maxWidth)

        // Check cache first
        layoutCache[cacheKey]?.let { cached ->
            return floatArrayOf(cached.width, cached.height)
        }

        // Create a fresh builder for thread safety
        val builder = createBuilder()

        // Configure tag styles
        if (!tagStylesJson.isNullOrEmpty()) {
            try {
                val parsed = org.json.JSONObject(tagStylesJson)
                val tagStyles = mutableMapOf<String, Map<String, Any>>()
                parsed.keys().forEach { tag ->
                    val styleObj = parsed.getJSONObject(tag)
                    val styleMap = mutableMapOf<String, Any>()
                    styleObj.keys().forEach { key ->
                        styleMap[key] = styleObj.get(key)
                    }
                    tagStyles[tag] = styleMap
                }
                builder.setTagStyles(tagStyles)
            } catch (e: Exception) {
                builder.setTagStyles(null)
            }
        } else {
            builder.setTagStyles(null)
        }

        // Build spannable from HTML
        val spannable = builder.buildSpannable(html)

        // Create TextPaint matching C++ measurement settings
        val paint = TextPaint().apply {
            isAntiAlias = true
            textSize = FabricGeneratedConstants.DEFAULT_FONT_SIZE * density
            typeface = Typeface.DEFAULT
        }

        // Calculate layout width
        val layoutWidth = if (maxWidth > 0 && maxWidth < Float.MAX_VALUE) {
            maxWidth.toInt()
        } else {
            // Measure without constraint to get intrinsic width
            ceil(Layout.getDesiredWidth(spannable, paint)).toInt().coerceAtLeast(1)
        }

        // Create StaticLayout with default line spacing (no explicit multiplier)
        // This matches C++ which doesn't set lineHeight, letting Android use natural font metrics
        val layout = StaticLayout.Builder.obtain(spannable, 0, spannable.length, paint, layoutWidth)
            .setAlignment(Layout.Alignment.ALIGN_NORMAL)
            .setLineSpacing(0f, 1f)  // Default: no extra spacing
            .setIncludePad(true)
            .setEllipsize(TextUtils.TruncateAt.END)
            .build()

        val measuredWidth = layout.width.toFloat()
        val measuredHeight = layout.height.toFloat()

        // Cache the layout
        layoutCache[cacheKey] = CachedLayout(layout, measuredWidth, measuredHeight)

        return floatArrayOf(measuredWidth, measuredHeight)
    }

    /**
     * Retrieves a cached StaticLayout for rendering.
     * Called by FabricHTMLTextView during rendering.
     *
     * @param html The HTML string
     * @param tagStylesJson Optional JSON string for tag styles
     * @param width The layout width used during measurement
     * @return The cached StaticLayout, or null if not found
     */
    @JvmStatic
    fun getCachedLayout(html: String?, tagStylesJson: String?, width: Float): StaticLayout? {
        if (html.isNullOrEmpty()) return null
        val cacheKey = buildCacheKey(html, tagStylesJson, width)
        return layoutCache[cacheKey]?.layout
    }

    /**
     * Creates a StaticLayout for cases where cache miss occurs during rendering.
     * This should rarely happen if measurement was called first.
     */
    @JvmStatic
    fun createLayout(
        html: String?,
        tagStylesJson: String?,
        width: Int,
        density: Float
    ): StaticLayout? {
        if (html.isNullOrEmpty()) return null

        // Create a fresh builder for thread safety
        val builder = createBuilder()

        // Configure tag styles
        if (!tagStylesJson.isNullOrEmpty()) {
            try {
                val parsed = org.json.JSONObject(tagStylesJson)
                val tagStyles = mutableMapOf<String, Map<String, Any>>()
                parsed.keys().forEach { tag ->
                    val styleObj = parsed.getJSONObject(tag)
                    val styleMap = mutableMapOf<String, Any>()
                    styleObj.keys().forEach { key ->
                        styleMap[key] = styleObj.get(key)
                    }
                    tagStyles[tag] = styleMap
                }
                builder.setTagStyles(tagStyles)
            } catch (e: Exception) {
                builder.setTagStyles(null)
            }
        } else {
            builder.setTagStyles(null)
        }

        val spannable = builder.buildSpannable(html)

        val paint = TextPaint().apply {
            isAntiAlias = true
            textSize = FabricGeneratedConstants.DEFAULT_FONT_SIZE * density
            typeface = Typeface.DEFAULT
        }

        val layoutWidth = if (width > 0) width else {
            ceil(Layout.getDesiredWidth(spannable, paint)).toInt().coerceAtLeast(1)
        }

        return StaticLayout.Builder.obtain(spannable, 0, spannable.length, paint, layoutWidth)
            .setAlignment(Layout.Alignment.ALIGN_NORMAL)
            .setLineSpacing(0f, 1f)  // Default: no extra spacing
            .setIncludePad(true)
            .setEllipsize(TextUtils.TruncateAt.END)
            .build()
    }

    /**
     * Clears the layout cache. Call when memory pressure is high.
     */
    @JvmStatic
    fun clearCache() {
        layoutCache.clear()
    }

    private fun buildCacheKey(html: String, tagStylesJson: String?, width: Float): String {
        return "${html.hashCode()}_${tagStylesJson?.hashCode() ?: 0}_${width.toInt()}"
    }
}
