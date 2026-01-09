package io.michaelfay.fabricrichtext

import android.text.Spannable
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.common.MapBuilder
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.events.Event
import com.facebook.react.viewmanagers.FabricRichTextManagerInterface
import com.facebook.react.viewmanagers.FabricRichTextManagerDelegate

class LinkPressEvent(
  surfaceId: Int,
  viewId: Int,
  private val url: String,
  private val type: DetectedContentType
) : Event<LinkPressEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val eventData = Arguments.createMap()
    eventData.putString("url", url)
    eventData.putString("type", when (type) {
      DetectedContentType.LINK -> "link"
      DetectedContentType.EMAIL -> "email"
      DetectedContentType.PHONE -> "phone"
    })
    return eventData
  }

  companion object {
    const val EVENT_NAME = "topLinkPress"
  }
}

@ReactModule(name = FabricRichTextViewManager.NAME)
class FabricRichTextViewManager : SimpleViewManager<FabricRichTextView>(),
  FabricRichTextManagerInterface<FabricRichTextView> {
  private val mDelegate: ViewManagerDelegate<FabricRichTextView>

  init {
    mDelegate = FabricRichTextManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<FabricRichTextView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): FabricRichTextView {
    val view = FabricRichTextView(context)
    view.linkClickListener = object : LinkClickListener {
      override fun onLinkClick(url: String, type: DetectedContentType) {
        val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
        val surfaceId = UIManagerHelper.getSurfaceId(context)
        eventDispatcher?.dispatchEvent(LinkPressEvent(surfaceId, view.id, url, type))
      }
    }
    return view
  }

  @ReactProp(name = "html")
  override fun setHtml(view: FabricRichTextView?, html: String?) {
    view?.setHtml(html)
  }

  @ReactProp(name = "tagStyles")
  override fun setTagStyles(view: FabricRichTextView?, value: String?) {
    view?.setTagStyles(value)
  }

  @ReactProp(name = "className")
  override fun setClassName(view: FabricRichTextView?, value: String?) {
    // className is for NativeWind integration - no-op on Android if NativeWind not configured
  }

  // Text style props (following AndroidTextInput pattern)
  // These ensure Kotlin rendering uses the same values as C++ measurement

  @ReactProp(name = "fontSize", defaultFloat = 14f)
  override fun setFontSize(view: FabricRichTextView?, fontSize: Float) {
    view?.setFontSize(fontSize)
  }

  @ReactProp(name = "lineHeight", defaultFloat = 0f)
  override fun setLineHeight(view: FabricRichTextView?, lineHeight: Float) {
    view?.setLineHeight(lineHeight)
  }

  @ReactProp(name = "fontWeight")
  override fun setFontWeight(view: FabricRichTextView?, fontWeight: String?) {
    view?.setFontWeight(fontWeight)
  }

  @ReactProp(name = "fontFamily")
  override fun setFontFamily(view: FabricRichTextView?, fontFamily: String?) {
    view?.setFontFamily(fontFamily)
  }

  @ReactProp(name = "fontStyle")
  override fun setFontStyle(view: FabricRichTextView?, fontStyle: String?) {
    view?.setFontStyle(fontStyle)
  }

  @ReactProp(name = "letterSpacing", defaultFloat = 0f)
  override fun setLetterSpacing(view: FabricRichTextView?, letterSpacing: Float) {
    view?.setLetterSpacingProp(letterSpacing)
  }

  @ReactProp(name = "textAlign")
  override fun setTextAlign(view: FabricRichTextView?, textAlign: String?) {
    view?.setTextAlign(textAlign)
  }

  @ReactProp(name = "includeFontPadding", defaultBoolean = true)
  override fun setIncludeFontPadding(view: FabricRichTextView?, includeFontPadding: Boolean) {
    view?.includeFontPadding = includeFontPadding
  }

  @ReactProp(name = "allowFontScaling", defaultBoolean = true)
  override fun setAllowFontScaling(view: FabricRichTextView?, allowFontScaling: Boolean) {
    view?.setAllowFontScaling(allowFontScaling)
  }

  @ReactProp(name = "maxFontSizeMultiplier", defaultFloat = 0f)
  override fun setMaxFontSizeMultiplier(view: FabricRichTextView?, maxFontSizeMultiplier: Float) {
    view?.setMaxFontSizeMultiplier(maxFontSizeMultiplier)
  }

  @ReactProp(name = "color", customType = "Color")
  override fun setColor(view: FabricRichTextView?, color: Int) {
    view?.setTextColorProp(color)
  }

  @ReactProp(name = "detectLinks", defaultBoolean = false)
  override fun setDetectLinks(view: FabricRichTextView?, detectLinks: Boolean) {
    view?.setDetectLinks(detectLinks)
  }

  @ReactProp(name = "detectPhoneNumbers", defaultBoolean = false)
  override fun setDetectPhoneNumbers(view: FabricRichTextView?, detectPhoneNumbers: Boolean) {
    view?.setDetectPhoneNumbers(detectPhoneNumbers)
  }

  @ReactProp(name = "detectEmails", defaultBoolean = false)
  override fun setDetectEmails(view: FabricRichTextView?, detectEmails: Boolean) {
    view?.setDetectEmails(detectEmails)
  }

  @ReactProp(name = "numberOfLines", defaultInt = 0)
  override fun setNumberOfLines(view: FabricRichTextView?, numberOfLines: Int) {
    view?.setNumberOfLines(numberOfLines)
  }

  @ReactProp(name = "animationDuration", defaultFloat = 0.2f)
  override fun setAnimationDuration(view: FabricRichTextView?, animationDuration: Float) {
    view?.setAnimationDuration(animationDuration)
  }

  @ReactProp(name = "writingDirection")
  override fun setWritingDirection(view: FabricRichTextView?, writingDirection: String?) {
    view?.setWritingDirection(writingDirection)
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any>? {
    return MapBuilder.builder<String, Any>()
      .put(LinkPressEvent.EVENT_NAME, MapBuilder.of("registrationName", "onLinkPress"))
      .build()
  }

  /**
   * Receives state updates from C++ ShadowNode.
   *
   * The C++ FabricRichTextViewShadowNode parses HTML into an AttributedString,
   * serializes it to MapBuffer, and passes it here via Fabric's state mechanism.
   * We parse the MapBuffer to extract text fragments and build a Spannable
   * that exactly matches what C++ used for measurement.
   *
   * This eliminates the measurement/rendering mismatch caused by duplicate
   * HTML parsing in C++ (measurement) and Kotlin (rendering).
   */
  override fun updateState(
    view: FabricRichTextView,
    props: ReactStylesDiffMap?,
    stateWrapper: StateWrapper?
  ): Any? {
    if (stateWrapper == null) {
      if (DEBUG_STATE) {
        Log.d(TAG, "updateState: stateWrapper is null")
      }
      return null
    }

    try {
      val mapBuffer = stateWrapper.stateDataMapBuffer
      if (mapBuffer == null) {
        if (DEBUG_STATE) {
          Log.d(TAG, "updateState: MapBuffer is null")
        }
        return null
      }

      if (DEBUG_STATE) {
        Log.d(TAG, "updateState: Received MapBuffer from C++")
      }

      // Parse the full state including fragments and layout props
      val parsedState = FabricRichFragmentParser.parseFullState(mapBuffer)

      if (parsedState == null) {
        if (DEBUG_STATE) {
          Log.d(TAG, "updateState: No state parsed")
        }
        return null
      }

      if (DEBUG_STATE) {
        Log.d(TAG, "updateState: Built Spannable with ${parsedState.spannable.length} chars, " +
            "numberOfLines=${parsedState.numberOfLines}, isRTL=${parsedState.isRTL}")
      }

      return parsedState
    } catch (e: Exception) {
      Log.e(TAG, "updateState: Error parsing state", e)
      return null
    }
  }

  /**
   * Called with the return value from updateState.
   * Sets the pre-built Spannable and state properties on the view.
   */
  override fun updateExtraData(view: FabricRichTextView, extraData: Any?) {
    if (extraData is ParsedState) {
      if (DEBUG_STATE) {
        Log.d(TAG, "updateExtraData: Setting state on view - isRTL=${extraData.isRTL}, numberOfLines=${extraData.numberOfLines}, a11yLabel=${extraData.accessibilityLabel?.length ?: 0} chars")
      }
      // Apply all state properties to the view
      view.setNumberOfLines(extraData.numberOfLines)
      view.setAnimationDuration(extraData.animationDuration)
      view.setWritingDirectionFromState(extraData.isRTL)
      view.setResolvedAccessibilityLabel(extraData.accessibilityLabel)
      view.setSpannableFromState(extraData.spannable)
    } else if (extraData is Spannable) {
      // Fallback for backward compatibility
      if (DEBUG_STATE) {
        Log.d(TAG, "updateExtraData: Setting Spannable on view (legacy)")
      }
      view.setSpannableFromState(extraData)
    }
  }

  companion object {
    const val NAME = "FabricRichText"
    private const val TAG = "FabricRichTextViewManager"
    private const val DEBUG_STATE = false
  }
}
