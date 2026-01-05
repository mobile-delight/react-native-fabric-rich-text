package io.michaelfay.fabrichtmltext

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.text.BoringLayout
import android.text.Layout
import android.text.Spannable
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint
import android.text.method.LinkMovementMethod
import android.util.AttributeSet
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import androidx.appcompat.widget.AppCompatTextView
import android.animation.ValueAnimator
import android.view.animation.AccelerateDecelerateInterpolator
import kotlin.math.ceil
import kotlin.math.floor
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

class FabricHTMLTextView : AppCompatTextView {
  private val sanitizer = FabricHTMLSanitizer()
  private val builder = FabricHtmlSpannableBuilder()
  private var currentHtml: String? = null

  // State-based rendering: when true, we bypass AppCompatTextView's internal layout
  // and draw our own StaticLayout with parameters matching TextLayoutManager
  private var hasStateSpannable: Boolean = false
  // Internal visibility to allow LinkClickMovementMethod to access for hit testing
  internal var stateSpannable: Spannable? = null
  internal var customLayout: Layout? = null
  private val customTextPaint = TextPaint(TextPaint.ANTI_ALIAS_FLAG)

  var linkClickListener: LinkClickListener? = null

  // Detection props
  private var detectLinks: Boolean = false
  private var detectPhoneNumbers: Boolean = false
  private var detectEmails: Boolean = false
  private val detectionLock = Any()  // Thread safety for detection prop changes

  companion object {
    private const val TAG = "FabricHTMLTextView"
    // Debug flags: only enabled in debug builds
    // To enable debug visualization, set DEBUG_DRAW_LINE_BOUNDS = true AND build in debug mode
    private val DEBUG_DRAW_LINE_BOUNDS = BuildConfig.DEBUG && false
    // To enable debug logging, set DEBUG_LOG = true AND build in debug mode
    private val DEBUG_LOG = BuildConfig.DEBUG && false
  }

  // Text style props from React - synchronized with C++ measurement
  private var baseFontSize: Float = FabricGeneratedConstants.DEFAULT_FONT_SIZE
  private var baseLineHeight: Float = 0f
  private var baseFontWeight: String? = null
  private var baseFontFamily: String? = null
  private var baseFontStyle: String? = null
  private var baseLetterSpacing: Float = 0f
  private var baseTextAlign: String? = null
  private var baseAllowFontScaling: Boolean = true
  private var baseMaxFontSizeMultiplier: Float = 0f
  private var baseTextColor: Int? = null

  // numberOfLines feature props
  private var numberOfLines: Int = 0  // 0 = no limit
  private var animationDuration: Float = 0.2f

  // RTL text direction
  private var isRTL: Boolean = false

  // Height animation state
  private var previousHeight: Int = 0
  private var hasInitializedLayout: Boolean = false
  private var heightAnimator: ValueAnimator? = null

  // Debug drawing paints
  private val debugFillPaints = if (DEBUG_DRAW_LINE_BOUNDS) {
    arrayOf(
      Paint().apply { color = Color.argb(51, 255, 0, 0) },     // Red 20%
      Paint().apply { color = Color.argb(51, 0, 0, 255) },     // Blue 20%
      Paint().apply { color = Color.argb(51, 0, 204, 0) },     // Green 20%
      Paint().apply { color = Color.argb(51, 255, 128, 0) }    // Orange 20%
    )
  } else null

  private val debugStrokePaint = if (DEBUG_DRAW_LINE_BOUNDS) {
    Paint().apply {
      color = Color.argb(128, 0, 0, 0)
      style = Paint.Style.STROKE
      strokeWidth = 1f
    }
  } else null

  private val debugBaselinePaint = if (DEBUG_DRAW_LINE_BOUNDS) {
    Paint().apply {
      color = Color.RED
      style = Paint.Style.STROKE
      strokeWidth = 2f
    }
  } else null

  constructor(context: Context) : super(context) {
    init()
  }
  constructor(context: Context, attrs: AttributeSet?) : super(context, attrs) {
    init()
  }
  constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(
    context,
    attrs,
    defStyleAttr
  ) {
    init()
  }

  private fun init() {
    // Set base text size to default (will be overridden by fontSize prop if provided)
    setTextSize(TypedValue.COMPLEX_UNIT_SP, FabricGeneratedConstants.DEFAULT_FONT_SIZE)

    // Initialize custom text paint with default size
    customTextPaint.textSize = FabricGeneratedConstants.DEFAULT_FONT_SIZE * resources.displayMetrics.scaledDensity

    // Match React Native's TextLayoutManager StaticLayout configuration:
    // StaticLayout.Builder.obtain(...).setLineSpacing(0f, 1f)
    // This ensures the TextView's internal StaticLayout uses the same parameters
    // as the measurement StaticLayout, preventing height mismatches.
    setLineSpacing(0f, 1f)

    movementMethod = LinkClickMovementMethod { url, type ->
      linkClickListener?.onLinkClick(url, type)
    }
  }

  // Text style prop setters - called from ViewManager

  fun setFontSize(fontSize: Float) {
    baseFontSize = if (fontSize > 0) fontSize else FabricGeneratedConstants.DEFAULT_FONT_SIZE
    setTextSize(TypedValue.COMPLEX_UNIT_SP, baseFontSize)
    if (DEBUG_LOG) {
      Log.d(TAG, "[Props] setFontSize: $baseFontSize")
    }
    rebuildIfNeeded()
  }

  fun setLineHeight(lineHeight: Float) {
    baseLineHeight = lineHeight
    // Line height is now handled by FabricCustomLineHeightSpan in the Spannable
    // Do NOT use setLineSpacing as it produces different results than
    // React Native's TextLayoutManager measurement approach
    rebuildIfNeeded()
  }

  fun setFontWeight(fontWeight: String?) {
    baseFontWeight = fontWeight
    applyTypeface()
    rebuildIfNeeded()
  }

  fun setFontFamily(fontFamily: String?) {
    baseFontFamily = fontFamily
    applyTypeface()
    rebuildIfNeeded()
  }

  fun setFontStyle(fontStyle: String?) {
    baseFontStyle = fontStyle
    applyTypeface()
    rebuildIfNeeded()
  }

  fun setLetterSpacingProp(letterSpacing: Float) {
    baseLetterSpacing = letterSpacing
    if (letterSpacing != 0f) {
      // Android letterSpacing is in ems, React Native is in pt
      // Convert: letterSpacing (pt) / fontSize (sp) = ems
      this.letterSpacing = letterSpacing / baseFontSize
    }
    rebuildIfNeeded()
  }

  fun setTextAlign(textAlign: String?) {
    baseTextAlign = textAlign
    gravity = when (textAlign) {
      "center" -> Gravity.CENTER_HORIZONTAL
      "right" -> Gravity.END
      "justify" -> Gravity.START // Android doesn't support justify directly
      else -> Gravity.START
    }
  }

  fun setAllowFontScaling(allowFontScaling: Boolean) {
    baseAllowFontScaling = allowFontScaling
    // Note: Font scaling is handled in C++ measurement, Kotlin just stores the value
    rebuildIfNeeded()
  }

  fun setMaxFontSizeMultiplier(maxFontSizeMultiplier: Float) {
    baseMaxFontSizeMultiplier = maxFontSizeMultiplier
    // Note: Max multiplier is handled in C++ measurement, Kotlin just stores the value
    rebuildIfNeeded()
  }

  fun setTextColorProp(color: Int) {
    baseTextColor = color
    if (color != 0) {
      // 0 typically means no color was set (default from codegen)
      super.setTextColor(color)
    }
  }

  private fun applyTypeface() {
    val isBold = FabricGeneratedConstants.isBoldWeight(baseFontWeight)
    val isItalic = FabricGeneratedConstants.isItalicStyle(baseFontStyle)

    val style = when {
      isBold && isItalic -> Typeface.BOLD_ITALIC
      isBold -> Typeface.BOLD
      isItalic -> Typeface.ITALIC
      else -> Typeface.NORMAL
    }

    val family = when (baseFontFamily) {
      "serif" -> Typeface.SERIF
      "monospace" -> Typeface.MONOSPACE
      else -> Typeface.DEFAULT
    }

    typeface = Typeface.create(family, style)
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

    // Rebuild spannable with new styles if we have HTML
    rebuildIfNeeded()
  }

  fun setHtml(html: String?) {
    currentHtml = html
    rebuildIfNeeded()
  }

  fun setDetectLinks(detect: Boolean) {
    synchronized(detectionLock) {
      if (detectLinks != detect) {
        detectLinks = detect
        applyDetectionLocked()
      }
    }
  }

  fun setDetectPhoneNumbers(detect: Boolean) {
    synchronized(detectionLock) {
      if (detectPhoneNumbers != detect) {
        detectPhoneNumbers = detect
        applyDetectionLocked()
      }
    }
  }

  fun setDetectEmails(detect: Boolean) {
    synchronized(detectionLock) {
      if (detectEmails != detect) {
        detectEmails = detect
        applyDetectionLocked()
      }
    }
  }

  fun setNumberOfLines(lines: Int) {
    val effectiveLines = if (lines < 0) 0 else lines
    if (numberOfLines != effectiveLines) {
      numberOfLines = effectiveLines
      customLayout = null  // Force layout recreation
      updateAccessibilityForTruncation()
      invalidate()
    }
  }

  /**
   * Update content description to indicate truncation for TalkBack users.
   */
  private fun updateAccessibilityForTruncation() {
    if (numberOfLines > 0 && text?.isNotEmpty() == true) {
      // Check if content would be truncated
      val layout = customLayout ?: layout
      if (layout != null && layout.lineCount > numberOfLines) {
        // Content is truncated - provide hint
        contentDescription = text.toString() + ". Content is truncated."
      } else {
        contentDescription = null // Use default text content
      }
    } else {
      contentDescription = null
    }
  }

  fun setAnimationDuration(duration: Float) {
    animationDuration = if (duration < 0) 0f else duration
  }

  fun setWritingDirection(direction: String?) {
    val newIsRTL = direction == "rtl"
    if (isRTL != newIsRTL) {
      isRTL = newIsRTL
      customLayout = null  // Force layout recreation
      invalidate()
    }
  }

  /**
   * Apply auto-detection to the current text if any detection props are enabled.
   * Uses Android's Linkify to detect URLs, emails, and phone numbers.
   *
   * Creates a COPY of the spannable before applying Linkify to avoid:
   * 1. Mutating the original spannable (thread safety)
   * 2. Accumulating duplicate spans on repeated calls
   *
   * MUST be called with detectionLock held.
   */
  private fun applyDetectionLocked() {
    val source = stateSpannable ?: (text as? Spannable) ?: return

    // Build the Linkify mask based on enabled detection
    var mask = 0
    if (detectLinks) {
      mask = mask or android.text.util.Linkify.WEB_URLS
    }
    if (detectPhoneNumbers) {
      mask = mask or android.text.util.Linkify.PHONE_NUMBERS
    }
    if (detectEmails) {
      mask = mask or android.text.util.Linkify.EMAIL_ADDRESSES
    }

    if (mask == 0) {
      return
    }

    // Create a copy to avoid mutating the original spannable
    val spannable = android.text.SpannableString(source)

    // Apply Linkify to detect and create URLSpans on the copy
    try {
      android.text.util.Linkify.addLinks(spannable, mask)
    } catch (e: RuntimeException) {
      // Linkify can throw RuntimeException or PatternSyntaxException on malformed patterns.
      // Log and continue without detection. We catch RuntimeException specifically to let
      // Errors (OutOfMemoryError, etc.) propagate rather than silently swallowing them.
      android.util.Log.w(TAG, "Linkify.addLinks failed", e)
      return
    }

    // Update the state with the new spannable
    stateSpannable = spannable
    customLayout = null  // Force layout recreation
    invalidate()
  }

  /**
   * Sets pre-built Spannable from C++ state.
   * This is called by ViewManager.updateExtraData() with the Spannable
   * built from parsed fragments that C++ used for measurement.
   * Using this ensures perfect alignment between measurement and rendering.
   *
   * IMPORTANT: We do NOT call `text = spannable` here because that would
   * trigger AppCompatTextView to create its own internal StaticLayout
   * with potentially different parameters. Instead, we store the spannable
   * and create our own StaticLayout in onDraw() with parameters that exactly
   * match TextLayoutManager.createLayout().
   */
  fun setSpannableFromState(spannable: android.text.Spannable) {
    if (DEBUG_LOG) {
      Log.d(TAG, "[State] setSpannableFromState: ${spannable.length} chars")
    }
    stateSpannable = spannable
    hasStateSpannable = true
    customLayout = null  // Clear cached layout to force recreation with new spannable

    // Apply link detection if any detection props are enabled
    // This must happen AFTER setting stateSpannable since detection operates on it
    synchronized(detectionLock) {
      if (detectLinks || detectPhoneNumbers || detectEmails) {
        applyDetectionLocked()
      }
    }

    // Update accessibility after content changes
    post { updateAccessibilityForTruncation() }

    invalidate()
    requestLayout()
  }

  private fun rebuildIfNeeded() {
    val html = currentHtml
    if (html.isNullOrEmpty()) {
      text = ""
      return
    }

    // Create base style configuration from props
    val baseStyle = BaseTextStyle(
      fontSize = baseFontSize,
      lineHeight = baseLineHeight,
      fontWeight = baseFontWeight,
      fontFamily = baseFontFamily,
      fontStyle = baseFontStyle,
      letterSpacing = baseLetterSpacing,
      textAlign = baseTextAlign,
      color = baseTextColor
    )
    builder.setBaseStyle(baseStyle)

    // Sanitize HTML before parsing to prevent XSS attacks
    val sanitizedHtml = sanitizer.sanitize(html)
    val spannable = builder.buildSpannable(sanitizedHtml)
    text = spannable
  }

  /**
   * Creates a StaticLayout using the EXACT same parameters as TextLayoutManager.createLayout().
   * This ensures the rendered layout matches the measured layout from C++.
   *
   * See: ReactAndroid/.../views/text/TextLayoutManager.kt lines 520-575
   */
  private fun createCustomLayout(text: Spannable, availableWidth: Int): Layout {
    // Sync customTextPaint with view's paint settings
    customTextPaint.set(paint)

    // Select text direction heuristic based on isRTL setting
    val textDirectionHeuristic = if (isRTL) {
      TextDirectionHeuristics.FIRSTSTRONG_RTL
    } else {
      TextDirectionHeuristics.FIRSTSTRONG_LTR
    }

    // Check if text is "boring" (single line, no special features)
    // Matches TextLayoutManager.isBoring() behavior
    val boring = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
      BoringLayout.isBoring(text, customTextPaint)
    } else {
      BoringLayout.isBoring(text, customTextPaint, textDirectionHeuristic, true, null)
    }

    // TextLayoutManager alignment mapping
    // In RTL mode, "left" maps to "start" (NORMAL=right in RTL) and "right" maps to "end" (OPPOSITE=left in RTL)
    // This follows CSS logical properties: left/right become start/end relative to writing direction
    val alignment = when (baseTextAlign) {
      "center" -> Layout.Alignment.ALIGN_CENTER
      "right" -> if (isRTL) Layout.Alignment.ALIGN_NORMAL else Layout.Alignment.ALIGN_OPPOSITE
      "left" -> if (isRTL) Layout.Alignment.ALIGN_OPPOSITE else Layout.Alignment.ALIGN_NORMAL
      else -> Layout.Alignment.ALIGN_NORMAL
    }

    // If boring text fits in width and numberOfLines allows single line, use BoringLayout
    if (boring != null && boring.width <= floor(availableWidth.toFloat()) && (numberOfLines == 0 || numberOfLines == 1)) {
      if (DEBUG_LOG) {
        Log.d(TAG, "[Layout] Using BoringLayout: width=${boring.width}, availableWidth=$availableWidth")
      }
      return BoringLayout.make(
        text, customTextPaint, availableWidth, alignment, 1f, 0f, boring, includeFontPadding
      )
    }

    // Calculate layout width (matches TextLayoutManager)
    val desiredWidth = ceil(Layout.getDesiredWidth(text, customTextPaint)).toInt()
    val layoutWidth = min(desiredWidth, availableWidth)

    if (DEBUG_LOG) {
      Log.d(TAG, "[Layout] Using StaticLayout: desiredWidth=$desiredWidth, layoutWidth=$layoutWidth, availableWidth=$availableWidth, numberOfLines=$numberOfLines")
    }

    // Build StaticLayout with EXACT same parameters as TextLayoutManager.createLayout()
    val builder = StaticLayout.Builder.obtain(text, 0, text.length, customTextPaint, layoutWidth)
      .setAlignment(alignment)
      .setLineSpacing(0f, 1f)  // CRITICAL: Must match TextLayoutManager
      .setIncludePad(includeFontPadding)
      .setBreakStrategy(Layout.BREAK_STRATEGY_HIGH_QUALITY)
      .setHyphenationFrequency(Layout.HYPHENATION_FREQUENCY_NONE)
      .setTextDirection(textDirectionHeuristic)  // Apply RTL direction if set

    // Apply numberOfLines with ellipsis truncation
    if (numberOfLines > 0) {
      builder.setMaxLines(numberOfLines)
      builder.setEllipsize(android.text.TextUtils.TruncateAt.END)
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      builder.setUseLineSpacingFromFallbacks(true)
    }

    return builder.build()
  }

  override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
    super.onSizeChanged(w, h, oldw, oldh)

    // Clear custom layout when width changes (height changes don't affect text layout)
    if (w != oldw) {
      customLayout = null
    }

    // Handle height animation when numberOfLines changes
    if (hasInitializedLayout && h != previousHeight && animationDuration > 0 && oldh > 0) {
      animateHeightChange(oldh, h)
    }

    previousHeight = h
    hasInitializedLayout = true

    if (DEBUG_LOG) {
      val textLayout = if (hasStateSpannable) customLayout else layout
      val contentHeight = textLayout?.height ?: 0
      val lineCount = textLayout?.lineCount ?: 0
      Log.d(TAG, "[View] onSizeChanged: ${w}x${h} (was ${oldw}x${oldh})")
      Log.d(TAG, "[View] Layout content height: $contentHeight, lines: $lineCount")
      Log.d(TAG, "[View] Extra space: ${h - contentHeight}px")
    }
  }

  private fun animateHeightChange(fromHeight: Int, toHeight: Int) {
    // Cancel any running animation
    heightAnimator?.cancel()

    // Convert animationDuration from seconds to milliseconds
    val durationMs = (animationDuration * 1000).toLong()

    heightAnimator = ValueAnimator.ofInt(fromHeight, toHeight).apply {
      duration = durationMs
      interpolator = AccelerateDecelerateInterpolator()
      addUpdateListener { animator ->
        val animatedHeight = animator.animatedValue as Int
        // Request layout to apply the animated height
        val params = layoutParams
        if (params != null) {
          params.height = animatedHeight
          layoutParams = params
        }
      }
      start()
    }
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    // Clean up animator when view is detached
    heightAnimator?.cancel()
    heightAnimator = null
  }

  override fun onDraw(canvas: Canvas) {
    // When using state-based spannable, draw our custom layout directly
    // This bypasses AppCompatTextView's internal layout creation
    if (hasStateSpannable && stateSpannable != null) {
      val spannable = stateSpannable!!

      // Create custom layout if needed (lazy creation on first draw with valid width)
      if (customLayout == null && width > 0) {
        customLayout = createCustomLayout(spannable, width - paddingLeft - paddingRight)

        if (DEBUG_LOG) {
          val cl = customLayout!!
          Log.d(TAG, "[Draw] Created custom layout: ${cl.width}x${cl.height}, lines: ${cl.lineCount}")
          Log.d(TAG, "[Draw] View size: ${width}x${height}")
          Log.d(TAG, "[Draw] Height comparison: view=$height, layout=${cl.height}, diff=${height - cl.height}px")
        }
      }

      val cl = customLayout
      if (cl != null) {
        // Draw the layout directly at padding offset
        canvas.save()
        canvas.translate(paddingLeft.toFloat(), paddingTop.toFloat())
        cl.draw(canvas)
        canvas.restore()

        if (DEBUG_DRAW_LINE_BOUNDS) {
          drawDebugLineBoundsForLayout(canvas, cl)
        }
        return
      }
    }

    // Fall back to default AppCompatTextView rendering for non-state mode
    super.onDraw(canvas)

    if (DEBUG_LOG && layout != null) {
      val textLayout = layout
      Log.d(TAG, "[Draw] View size: ${width}x${height}, Layout size: ${textLayout.width}x${textLayout.height}")
    }

    if (DEBUG_DRAW_LINE_BOUNDS) {
      drawDebugLineBounds(canvas)
    }
  }

  private fun drawDebugLineBoundsForLayout(canvas: Canvas, textLayout: Layout) {
    val lineCount = textLayout.lineCount
    if (lineCount == 0) return

    Log.d(TAG, "[DEBUG] Custom Layout - Total lines: $lineCount, view height: $height, layout height: ${textLayout.height}")

    canvas.save()
    canvas.translate(paddingLeft.toFloat(), paddingTop.toFloat())

    for (i in 0 until lineCount) {
      val lineTop = textLayout.getLineTop(i).toFloat()
      val lineBottom = textLayout.getLineBottom(i).toFloat()
      val lineBaseline = textLayout.getLineBaseline(i).toFloat()
      val lineLeft = textLayout.getLineLeft(i)
      val lineRight = textLayout.getLineRight(i)

      Log.d(TAG, "[DEBUG] Line $i: top=$lineTop bottom=$lineBottom baseline=$lineBaseline height=${lineBottom - lineTop}")

      debugFillPaints?.get(i % 4)?.let { paint ->
        canvas.drawRect(lineLeft, lineTop, lineRight, lineBottom, paint)
      }

      debugStrokePaint?.let { paint ->
        canvas.drawRect(lineLeft, lineTop, lineRight, lineBottom, paint)
      }

      debugBaselinePaint?.let { paint ->
        canvas.drawLine(lineLeft, lineBaseline, lineRight, lineBaseline, paint)
      }
    }

    canvas.restore()
  }

  private fun drawDebugLineBounds(canvas: Canvas) {
    val textLayout = layout ?: return
    val lineCount = textLayout.lineCount

    if (lineCount == 0) return

    Log.d(TAG, "[DEBUG] Total lines: $lineCount, view height: $height")

    for (i in 0 until lineCount) {
      val lineTop = textLayout.getLineTop(i).toFloat()
      val lineBottom = textLayout.getLineBottom(i).toFloat()
      val lineBaseline = textLayout.getLineBaseline(i).toFloat()
      val lineLeft = textLayout.getLineLeft(i)
      val lineRight = textLayout.getLineRight(i)
      val lineWidth = lineRight - lineLeft

      val lineStart = textLayout.getLineStart(i)
      val lineEnd = textLayout.getLineEnd(i)
      val lineText = text.subSequence(lineStart, lineEnd).toString()
        .replace("\n", "\\n")

      val ascent = textLayout.getLineAscent(i).toFloat()
      val descent = textLayout.getLineDescent(i).toFloat()

      Log.d(TAG, "[DEBUG] Line $i: top=$lineTop bottom=$lineBottom baseline=$lineBaseline " +
        "ascent=$ascent descent=$descent height=${lineBottom - lineTop} " +
        "text='$lineText'")

      // Draw filled rect for line bounds
      debugFillPaints?.get(i % 4)?.let { paint ->
        canvas.drawRect(lineLeft, lineTop, lineRight, lineBottom, paint)
      }

      // Draw stroke around line bounds
      debugStrokePaint?.let { paint ->
        canvas.drawRect(lineLeft, lineTop, lineRight, lineBottom, paint)
      }

      // Draw baseline
      debugBaselinePaint?.let { paint ->
        canvas.drawLine(lineLeft, lineBaseline, lineRight, lineBaseline, paint)
      }
    }
  }
}

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

      // For state-based rendering, use the custom layout and stateSpannable
      val fabricView = widget as? FabricHTMLTextView
      val effectiveLayout = fabricView?.customLayout ?: widget.layout
      val effectiveBuffer = fabricView?.stateSpannable ?: buffer

      if (effectiveLayout == null) {
        return super.onTouchEvent(widget, buffer, event)
      }

      val line = effectiveLayout.getLineForVertical(y)
      val offset = effectiveLayout.getOffsetForHorizontal(line, x.toFloat())

      // First check for HrefClickableSpan (explicit <a> tags)
      val hrefLinks = effectiveBuffer.getSpans(offset, offset, HrefClickableSpan::class.java)
      if (hrefLinks.isNotEmpty()) {
        val href = hrefLinks[0].href

        // Defense-in-depth: Validate URL scheme before invoking callback
        // Block dangerous schemes like javascript:, data:, vbscript:
        val scheme = android.net.Uri.parse(href).scheme?.lowercase()
        val allowedSchemes = setOf("http", "https", "mailto", "tel")
        if (scheme == null || scheme !in allowedSchemes) {
          return true  // Consume the event but don't invoke callback
        }

        onClick(href, DetectedContentType.LINK)
        return true
      }

      // Then check for URLSpan (auto-detected links from Linkify)
      val urlSpans = effectiveBuffer.getSpans(offset, offset, android.text.style.URLSpan::class.java)
      if (urlSpans.isNotEmpty()) {
        val url = urlSpans[0].url

        // Defense-in-depth: Validate URL scheme before invoking callback
        // Block dangerous schemes like javascript:, data:, vbscript:
        val scheme = android.net.Uri.parse(url).scheme?.lowercase()
        val allowedSchemes = setOf("http", "https", "mailto", "tel")
        if (scheme == null || scheme !in allowedSchemes) {
          return true  // Consume the event but don't invoke callback
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
