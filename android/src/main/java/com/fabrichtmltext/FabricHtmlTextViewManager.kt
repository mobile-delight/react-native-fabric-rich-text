package com.fabrichtmltext

import android.graphics.Color
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.FabricHtmlTextViewManagerInterface
import com.facebook.react.viewmanagers.FabricHtmlTextViewManagerDelegate

@ReactModule(name = FabricHtmlTextViewManager.NAME)
class FabricHtmlTextViewManager : SimpleViewManager<FabricHtmlTextView>(),
  FabricHtmlTextViewManagerInterface<FabricHtmlTextView> {
  private val mDelegate: ViewManagerDelegate<FabricHtmlTextView>

  init {
    mDelegate = FabricHtmlTextViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<FabricHtmlTextView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): FabricHtmlTextView {
    return FabricHtmlTextView(context)
  }

  @ReactProp(name = "color")
  override fun setColor(view: FabricHtmlTextView?, color: String?) {
    view?.setBackgroundColor(Color.parseColor(color))
  }

  companion object {
    const val NAME = "FabricHtmlTextView"
  }
}
