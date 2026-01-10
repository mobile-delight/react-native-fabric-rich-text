package io.michaelfay.fabricrichtext

import android.content.Context
import android.graphics.Canvas
import android.graphics.Typeface
import android.text.Layout
import android.text.Spannable
import android.text.TextPaint
import android.text.method.LinkMovementMethod
import android.util.AttributeSet
import android.util.Log
import android.util.TypedValue
import android.view.MotionEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.appcompat.widget.AppCompatTextView
import androidx.core.view.ViewCompat
import kotlin.math.min

/**
 * Type of content detected when a link is pressed.
 */
enum class DetectedContentType {
    LINK,
    EMAIL,
    PHONE
}

interface LinkClickListener {
    fun onLinkClick(url: String, type: DetectedContentType)
}

interface MeasurementListener {
    fun onMeasurement(measuredLineCount: Int, visibleLineCount: Int)
}

/**
 * Fabric component view for HTML rendering.
 *
 * Architecture: Thin orchestrator delegating to single-responsibility modules:
 * - TextTruncationEngine: Smart word-boundary truncation
 * - LinkDetectionManager: Auto-detection of URLs, emails, phones
 * - TextAccessibilityHelper: Accessibility calculations
 * - TextLayoutProvider: StaticLayout/BoringLayout creation
 * - TextStyleApplier: Text styling props
 * - HeightAnimationController: Height change animation
 * - DebugDrawingHelper: Debug visualization
 */
class FabricRichTextView : AppCompatTextView, TextStyleApplier.StyleChangeListener {

    companion object {
        private const val TAG = "FabricRichTextView"
        private const val A11Y_TAG = "A11Y_FHTMLTV"
        private const val A11Y_DEBUG = true
    }

    // Core modules (single responsibility)
    private val customTextPaint = TextPaint(TextPaint.ANTI_ALIAS_FLAG)
    private val truncationEngine = TextTruncationEngine(customTextPaint)
    private val linkDetectionManager = LinkDetectionManager()
    private val accessibilityHelper = TextAccessibilityHelper(truncationEngine)
    private val layoutProvider = TextLayoutProvider(customTextPaint, includeFontPadding)
    private val styleApplier = TextStyleApplier()
    private val animationController = HeightAnimationController()
    private val debugHelper = DebugDrawingHelper()

    // HTML parsing
    private val sanitizer = FabricRichSanitizer()
    private val builder = FabricRichSpannableBuilder()
    private var currentHtml: String? = null

    // State-based rendering
    private var hasStateSpannable: Boolean = false
    internal var stateSpannable: Spannable? = null
    internal var customLayout: Layout? = null

    // Listeners
    var linkClickListener: LinkClickListener? = null
    var measurementListener: MeasurementListener? = null

    // Measurement tracking
    private var lastReportedMeasuredLineCount: Int = -1
    private var lastReportedVisibleLineCount: Int = -1

    // State props
    private var numberOfLines: Int = 0
    private var isRTL: Boolean = false
    private var resolvedAccessibilityLabel: String? = null

    // Accessibility delegate
    private var accessibilityDelegate: FabricRichTextAccessibilityDelegate? = null

    // Constructors
    constructor(context: Context) : super(context) { init() }
    constructor(context: Context, attrs: AttributeSet?) : super(context, attrs) { init() }
    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr) { init() }

    private fun init() {
        setTextSize(TypedValue.COMPLEX_UNIT_SP, FabricGeneratedConstants.DEFAULT_FONT_SIZE)
        customTextPaint.textSize = FabricGeneratedConstants.DEFAULT_FONT_SIZE * resources.displayMetrics.scaledDensity
        setLineSpacing(0f, 1f)

        movementMethod = LinkClickMovementMethod { url, type ->
            linkClickListener?.onLinkClick(url, type)
        }

        // Set up accessibility delegate
        val originalFocus = isFocusable
        val originalImportantForA11y = importantForAccessibility
        accessibilityDelegate = FabricRichTextAccessibilityDelegate(this, originalFocus, originalImportantForA11y)
        ViewCompat.setAccessibilityDelegate(this, accessibilityDelegate)
        logA11y("init: set up ExploreByTouchHelper delegate for link accessibility")
    }

    // MARK: - TextStyleApplier.StyleChangeListener

    override fun onStyleChanged() {
        rebuildIfNeeded()
    }

    override fun applyTextSize(sizeSp: Float) {
        setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp)
    }

    override fun applyTextColor(color: Int) {
        super.setTextColor(color)
    }

    override fun applyTypeface(typeface: Typeface) {
        this.typeface = typeface
    }

    override fun applyGravity(gravity: Int) {
        this.gravity = gravity
    }

    override fun applyLetterSpacing(spacingEm: Float) {
        this.letterSpacing = spacingEm
    }

    // MARK: - Public Prop Setters (delegating to modules)

    fun setFontSize(fontSize: Float) { styleApplier.setFontSize(fontSize, this) }
    fun setLineHeight(lineHeight: Float) { styleApplier.setLineHeight(lineHeight, this) }
    fun setFontWeight(fontWeight: String?) { styleApplier.setFontWeight(fontWeight, this) }
    fun setFontFamily(fontFamily: String?) { styleApplier.setFontFamily(fontFamily, this) }
    fun setFontStyle(fontStyle: String?) { styleApplier.setFontStyle(fontStyle, this) }
    fun setLetterSpacingProp(letterSpacing: Float) { styleApplier.setLetterSpacing(letterSpacing, this) }
    fun setTextAlign(textAlign: String?) { styleApplier.setTextAlign(textAlign, this) }
    fun setAllowFontScaling(allowFontScaling: Boolean) { styleApplier.setAllowFontScaling(allowFontScaling, this) }
    fun setMaxFontSizeMultiplier(maxFontSizeMultiplier: Float) { styleApplier.setMaxFontSizeMultiplier(maxFontSizeMultiplier, this) }
    fun setTextColorProp(color: Int) { styleApplier.setTextColor(color, this) }

    fun setDetectLinks(detect: Boolean) {
        if (linkDetectionManager.setDetectLinks(detect)) {
            applyDetectionIfNeeded()
        }
    }

    fun setDetectPhoneNumbers(detect: Boolean) {
        if (linkDetectionManager.setDetectPhoneNumbers(detect)) {
            applyDetectionIfNeeded()
        }
    }

    fun setDetectEmails(detect: Boolean) {
        if (linkDetectionManager.setDetectEmails(detect)) {
            applyDetectionIfNeeded()
        }
    }

    fun setNumberOfLines(lines: Int) {
        val effectiveLines = if (lines < 0) 0 else lines
        if (numberOfLines != effectiveLines) {
            numberOfLines = effectiveLines
            customLayout = null
            updateAccessibilityForTruncation()
            invalidate()
        }
    }

    fun setAnimationDuration(duration: Float) {
        animationController.setAnimationDuration(duration)
    }

    fun setWritingDirection(direction: String?) {
        applyRTLState(direction == "rtl")
    }

    fun setWritingDirectionFromState(rtl: Boolean) {
        applyRTLState(rtl)
    }

    fun setResolvedAccessibilityLabel(label: String?) {
        resolvedAccessibilityLabel = label
        logA11y("setResolvedAccessibilityLabel: ${label?.length ?: 0} chars")
        updateAccessibilityForTruncation()
    }

    fun setTagStyles(tagStylesJson: String?) {
        if (tagStylesJson.isNullOrEmpty()) {
            builder.setTagStyles(null)
        } else {
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
        }
        rebuildIfNeeded()
    }

    fun setHtml(html: String?) {
        currentHtml = html
        rebuildIfNeeded()
    }

    // MARK: - State-Based Rendering

    fun setSpannableFromState(spannable: Spannable) {
        debugHelper.log("[State] setSpannableFromState: ${spannable.length} chars")
        stateSpannable = spannable
        hasStateSpannable = true
        customLayout = null

        applyDetectionIfNeeded()
        accessibilityDelegate?.updateLinks()
        post { updateAccessibilityForTruncation() }

        invalidate()
        requestLayout()
    }

    internal fun performLinkClick(url: String, type: DetectedContentType) {
        linkClickListener?.onLinkClick(url, type)
    }

    // MARK: - Accessibility

    fun getVisibleTextForAccessibility(): String {
        return accessibilityHelper.getVisibleTextForAccessibility(
            customLayout ?: layout,
            resolvedAccessibilityLabel,
            stateSpannable ?: text as? Spannable,
            numberOfLines
        )
    }

    fun isCharacterOnVisibleLine(charIndex: Int): Boolean {
        return accessibilityHelper.isCharacterOnVisibleLine(customLayout ?: layout, charIndex, numberOfLines)
    }

    fun getVisibleLinkCount(): Int {
        return accessibilityHelper.getVisibleLinkCount(
            getOrCreateLayout(),
            stateSpannable ?: text as? Spannable,
            numberOfLines
        )
    }

    fun getLinkBounds(index: Int): android.graphics.RectF? {
        return accessibilityHelper.getLinkBounds(
            getOrCreateLayout(),
            stateSpannable ?: text as? Spannable,
            index,
            paddingLeft,
            paddingTop
        )
    }

    override fun onInitializeAccessibilityNodeInfo(info: AccessibilityNodeInfo) {
        super.onInitializeAccessibilityNodeInfo(info)
        val visibleText = getVisibleTextForAccessibility()
        info.text = visibleText
        info.contentDescription = visibleText
        logA11y("onInitializeAccessibilityNodeInfo: set visible text, length=${visibleText.length}")
    }

    // MARK: - View Lifecycle

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)

        if (w != oldw) {
            customLayout = null
        }

        animationController.onSizeChanged(this, h, oldh)

        debugHelper.log("[View] onSizeChanged: ${w}x${h} (was ${oldw}x${oldh})")
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        animationController.cleanup()
    }

    override fun onDraw(canvas: Canvas) {
        if (hasStateSpannable && stateSpannable != null) {
            val spannable = stateSpannable!!

            if (customLayout == null && width > 0) {
                customLayout = layoutProvider.createLayout(
                    spannable,
                    width - paddingLeft - paddingRight,
                    isRTL,
                    styleApplier.textAlign,
                    numberOfLines
                )
                debugHelper.log("[Draw] Created custom layout: ${customLayout!!.width}x${customLayout!!.height}, lines: ${customLayout!!.lineCount}")
            }

            val cl = customLayout
            if (cl != null) {
                canvas.save()
                canvas.translate(paddingLeft.toFloat(), paddingTop.toFloat())

                if (numberOfLines > 0 && cl.lineCount > numberOfLines) {
                    truncationEngine.drawTruncatedLayout(canvas, cl, spannable, numberOfLines)
                } else {
                    cl.draw(canvas)
                }

                canvas.restore()

                if (debugHelper.isDrawingEnabled()) {
                    debugHelper.drawDebugLineBoundsForLayout(canvas, cl, paddingLeft, paddingTop, height)
                }

                reportLineMeasurementsIfNeeded(cl)
                return
            }
        }

        super.onDraw(canvas)

        if (debugHelper.isDrawingEnabled()) {
            layout?.let { debugHelper.drawDebugLineBounds(canvas, it, text, height) }
        }

        reportLineMeasurementsIfNeeded(layout)
    }

    // MARK: - Private Helpers

    private fun applyRTLState(rtl: Boolean) {
        if (isRTL != rtl) {
            isRTL = rtl
            layoutDirection = if (rtl) LAYOUT_DIRECTION_RTL else LAYOUT_DIRECTION_LTR
            customLayout = null
            invalidate()
        }
    }

    private fun applyDetectionIfNeeded() {
        if (linkDetectionManager.isDetectionEnabled()) {
            val source = stateSpannable ?: (text as? Spannable) ?: return
            val detected = linkDetectionManager.applyDetection(source)
            if (detected != null) {
                stateSpannable = detected
                customLayout = null
                invalidate()
            }
        }
    }

    private fun rebuildIfNeeded() {
        val html = currentHtml
        if (html.isNullOrEmpty()) {
            text = ""
            return
        }

        builder.setBaseStyle(styleApplier.createBaseTextStyle())
        val sanitizedHtml = sanitizer.sanitize(html)
        val spannable = builder.buildSpannable(sanitizedHtml)
        text = spannable
    }

    private fun updateAccessibilityForTruncation() {
        val baseLabel = resolvedAccessibilityLabel ?: (stateSpannable ?: text)?.toString() ?: ""
        val fullText = (stateSpannable ?: text)?.toString() ?: ""

        if (numberOfLines > 0 && baseLabel.isNotEmpty() && truncationEngine.isContentTruncated(customLayout ?: layout, numberOfLines, fullText)) {
            val layout = customLayout ?: layout
            if (layout != null) {
                val visibleText = truncationEngine.calculateVisibleText(layout, fullText, numberOfLines)
                contentDescription = visibleText
                logA11y("Truncated with word-boundary: showing ${visibleText.length} of ${fullText.length} chars")
                return
            }
        }

        contentDescription = if (baseLabel.isNotEmpty()) baseLabel else null
    }

    private fun getOrCreateLayout(): Layout? {
        if (customLayout != null) return customLayout

        if (hasStateSpannable && stateSpannable != null && width > 0) {
            customLayout = layoutProvider.createLayout(
                stateSpannable!!,
                width - paddingLeft - paddingRight,
                isRTL,
                styleApplier.textAlign,
                numberOfLines
            )
            return customLayout
        }

        return layout
    }

    private fun reportLineMeasurementsIfNeeded(textLayout: Layout?) {
        if (textLayout == null || measurementListener == null) return

        val spannable = stateSpannable ?: text as? Spannable ?: return
        if (spannable.isEmpty()) return

        val measuredLineCount = textLayout.lineCount
        val visibleLineCount = if (numberOfLines > 0) min(textLayout.lineCount, numberOfLines) else textLayout.lineCount

        if (measuredLineCount != lastReportedMeasuredLineCount || visibleLineCount != lastReportedVisibleLineCount) {
            lastReportedMeasuredLineCount = measuredLineCount
            lastReportedVisibleLineCount = visibleLineCount
            measurementListener?.onMeasurement(measuredLineCount, visibleLineCount)
        }
    }

    private fun logA11y(message: String) {
        if (A11Y_DEBUG) {
            Log.d(A11Y_TAG, "[${hashCode().toString(16)}] $message")
        }
    }
}

// MARK: - Link Click Movement Method

private class LinkClickMovementMethod(
    private val onClick: (url: String, type: DetectedContentType) -> Unit
) : LinkMovementMethod() {
    override fun onTouchEvent(
        widget: android.widget.TextView,
        buffer: android.text.Spannable,
        event: MotionEvent
    ): Boolean {
        if (event.action == MotionEvent.ACTION_UP) {
            val x = event.x.toInt() - widget.totalPaddingLeft + widget.scrollX
            val y = event.y.toInt() - widget.totalPaddingTop + widget.scrollY

            val fabricView = widget as? FabricRichTextView
            val effectiveLayout = fabricView?.customLayout ?: widget.layout
            val effectiveBuffer = fabricView?.stateSpannable ?: buffer

            if (effectiveLayout == null) {
                return super.onTouchEvent(widget, buffer, event)
            }

            val line = effectiveLayout.getLineForVertical(y)
            val offset = effectiveLayout.getOffsetForHorizontal(line, x.toFloat())

            // Check for HrefClickableSpan (explicit <a> tags)
            val hrefLinks = effectiveBuffer.getSpans(offset, offset, HrefClickableSpan::class.java)
            if (hrefLinks.isNotEmpty()) {
                val href = hrefLinks[0].href
                val scheme = android.net.Uri.parse(href).scheme?.lowercase()
                val allowedSchemes = setOf("http", "https", "mailto", "tel")
                if (scheme == null || scheme !in allowedSchemes) {
                    return true
                }
                onClick(href, DetectedContentType.LINK)
                return true
            }

            // Check for URLSpan (auto-detected links)
            val urlSpans = effectiveBuffer.getSpans(offset, offset, android.text.style.URLSpan::class.java)
            if (urlSpans.isNotEmpty()) {
                val url = urlSpans[0].url
                val scheme = android.net.Uri.parse(url).scheme?.lowercase()
                val allowedSchemes = setOf("http", "https", "mailto", "tel")
                if (scheme == null || scheme !in allowedSchemes) {
                    return true
                }
                val type = when {
                    url.startsWith("mailto:") -> DetectedContentType.EMAIL
                    url.startsWith("tel:") -> DetectedContentType.PHONE
                    else -> DetectedContentType.LINK
                }
                onClick(url, type)
                return true
            }
        }
        return super.onTouchEvent(widget, buffer, event)
    }
}
