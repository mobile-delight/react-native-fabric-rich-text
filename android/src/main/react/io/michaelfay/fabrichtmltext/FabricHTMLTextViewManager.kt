package io.michaelfay.fabrichtmltext

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
import com.facebook.react.viewmanagers.FabricHTMLTextManagerInterface
import com.facebook.react.viewmanagers.FabricHTMLTextManagerDelegate

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

@ReactModule(name = FabricHTMLTextViewManager.NAME)
class FabricHTMLTextViewManager : SimpleViewManager<FabricHTMLTextView>(),
  FabricHTMLTextManagerInterface<FabricHTMLTextView> {
  private val mDelegate: ViewManagerDelegate<FabricHTMLTextView>

  init {
    mDelegate = FabricHTMLTextManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<FabricHTMLTextView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): FabricHTMLTextView {
    val view = FabricHTMLTextView(context)
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
  override fun setHtml(view: FabricHTMLTextView?, html: String?) {
    view?.setHtml(html)
  }

  @ReactProp(name = "tagStyles")
  override fun setTagStyles(view: FabricHTMLTextView?, value: String?) {
    view?.setTagStyles(value)
  }

  @ReactProp(name = "className")
  override fun setClassName(view: FabricHTMLTextView?, value: String?) {
    // className is for NativeWind integration - no-op on Android if NativeWind not configured
  }

  // Text style props (following AndroidTextInput pattern)
  // These ensure Kotlin rendering uses the same values as C++ measurement

  @ReactProp(name = "fontSize", defaultFloat = 14f)
  override fun setFontSize(view: FabricHTMLTextView?, fontSize: Float) {
    view?.setFontSize(fontSize)
  }

  @ReactProp(name = "lineHeight", defaultFloat = 0f)
  override fun setLineHeight(view: FabricHTMLTextView?, lineHeight: Float) {
    view?.setLineHeight(lineHeight)
  }

  @ReactProp(name = "fontWeight")
  override fun setFontWeight(view: FabricHTMLTextView?, fontWeight: String?) {
    view?.setFontWeight(fontWeight)
  }

  @ReactProp(name = "fontFamily")
  override fun setFontFamily(view: FabricHTMLTextView?, fontFamily: String?) {
    view?.setFontFamily(fontFamily)
  }

  @ReactProp(name = "fontStyle")
  override fun setFontStyle(view: FabricHTMLTextView?, fontStyle: String?) {
    view?.setFontStyle(fontStyle)
  }

  @ReactProp(name = "letterSpacing", defaultFloat = 0f)
  override fun setLetterSpacing(view: FabricHTMLTextView?, letterSpacing: Float) {
    view?.setLetterSpacingProp(letterSpacing)
  }

  @ReactProp(name = "textAlign")
  override fun setTextAlign(view: FabricHTMLTextView?, textAlign: String?) {
    view?.setTextAlign(textAlign)
  }

  @ReactProp(name = "includeFontPadding", defaultBoolean = true)
  override fun setIncludeFontPadding(view: FabricHTMLTextView?, includeFontPadding: Boolean) {
    view?.includeFontPadding = includeFontPadding
  }

  @ReactProp(name = "allowFontScaling", defaultBoolean = true)
  override fun setAllowFontScaling(view: FabricHTMLTextView?, allowFontScaling: Boolean) {
    view?.setAllowFontScaling(allowFontScaling)
  }

  @ReactProp(name = "maxFontSizeMultiplier", defaultFloat = 0f)
  override fun setMaxFontSizeMultiplier(view: FabricHTMLTextView?, maxFontSizeMultiplier: Float) {
    view?.setMaxFontSizeMultiplier(maxFontSizeMultiplier)
  }

  @ReactProp(name = "color", customType = "Color")
  override fun setColor(view: FabricHTMLTextView?, color: Int) {
    view?.setTextColorProp(color)
  }

  @ReactProp(name = "detectLinks", defaultBoolean = false)
  override fun setDetectLinks(view: FabricHTMLTextView?, detectLinks: Boolean) {
    view?.setDetectLinks(detectLinks)
  }

  @ReactProp(name = "detectPhoneNumbers", defaultBoolean = false)
  override fun setDetectPhoneNumbers(view: FabricHTMLTextView?, detectPhoneNumbers: Boolean) {
    view?.setDetectPhoneNumbers(detectPhoneNumbers)
  }

  @ReactProp(name = "detectEmails", defaultBoolean = false)
  override fun setDetectEmails(view: FabricHTMLTextView?, detectEmails: Boolean) {
    view?.setDetectEmails(detectEmails)
  }

  @ReactProp(name = "numberOfLines", defaultInt = 0)
  override fun setNumberOfLines(view: FabricHTMLTextView?, numberOfLines: Int) {
    view?.setNumberOfLines(numberOfLines)
  }

  @ReactProp(name = "animationDuration", defaultFloat = 0.2f)
  override fun setAnimationDuration(view: FabricHTMLTextView?, animationDuration: Float) {
    view?.setAnimationDuration(animationDuration)
  }

  @ReactProp(name = "writingDirection")
  override fun setWritingDirection(view: FabricHTMLTextView?, writingDirection: String?) {
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
   * The C++ FabricHTMLTextViewShadowNode parses HTML into an AttributedString,
   * serializes it to MapBuffer, and passes it here via Fabric's state mechanism.
   * We parse the MapBuffer to extract text fragments and build a Spannable
   * that exactly matches what C++ used for measurement.
   *
   * This eliminates the measurement/rendering mismatch caused by duplicate
   * HTML parsing in C++ (measurement) and Kotlin (rendering).
   */
  override fun updateState(
    view: FabricHTMLTextView,
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

      // Parse the MapBuffer to extract fragments
      val fragments = FabricHTMLFragmentParser.parseState(mapBuffer)

      if (fragments.isEmpty()) {
        if (DEBUG_STATE) {
          Log.d(TAG, "updateState: No fragments parsed")
        }
        return null
      }

      // Build Spannable from fragments using React Native's PixelUtil for conversion
      val spannable = FabricHTMLFragmentParser.buildSpannableFromFragments(fragments)

      if (DEBUG_STATE) {
        Log.d(TAG, "updateState: Built Spannable with ${spannable.length} chars")
      }

      return spannable
    } catch (e: Exception) {
      Log.e(TAG, "updateState: Error parsing state", e)
      return null
    }
  }

  /**
   * Called with the return value from updateState.
   * Sets the pre-built Spannable on the view.
   */
  override fun updateExtraData(view: FabricHTMLTextView, extraData: Any?) {
    if (extraData is Spannable) {
      if (DEBUG_STATE) {
        Log.d(TAG, "updateExtraData: Setting Spannable on view")
      }
      view.setSpannableFromState(extraData)
    }
  }

  companion object {
    const val NAME = "FabricHTMLText"
    private const val TAG = "FabricHTMLTextViewManager"
    private const val DEBUG_STATE = true
  }
}
