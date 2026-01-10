package io.michaelfay.fabricrichtext

import android.animation.ValueAnimator
import android.view.View
import android.view.ViewGroup
import android.view.animation.AccelerateDecelerateInterpolator

/**
 * Controls height animation when numberOfLines changes.
 * Animates smooth transitions between different content heights.
 *
 * Single Responsibility: Height change animation management
 */
class HeightAnimationController {

    private var previousHeight: Int = 0
    private var hasInitializedLayout: Boolean = false
    private var heightAnimator: ValueAnimator? = null
    private var animationDuration: Float = 0.2f  // seconds

    /**
     * Sets the animation duration in seconds.
     */
    fun setAnimationDuration(duration: Float) {
        animationDuration = if (duration < 0) 0f else duration
    }

    /**
     * Gets the animation duration in seconds.
     */
    fun getAnimationDuration(): Float = animationDuration

    /**
     * Called when the view's size changes.
     * Triggers height animation if appropriate.
     *
     * @param view The view being animated
     * @param newHeight New height
     * @param oldHeight Previous height
     * @return true if animation was triggered
     */
    fun onSizeChanged(view: View, newHeight: Int, oldHeight: Int): Boolean {
        var animated = false

        // Handle height animation when numberOfLines changes
        if (hasInitializedLayout && newHeight != previousHeight && animationDuration > 0 && oldHeight > 0) {
            animateHeightChange(view, oldHeight, newHeight)
            animated = true
        }

        previousHeight = newHeight
        hasInitializedLayout = true

        return animated
    }

    /**
     * Animates height change from one value to another.
     */
    private fun animateHeightChange(view: View, fromHeight: Int, toHeight: Int) {
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
                val params = view.layoutParams
                if (params != null) {
                    params.height = animatedHeight
                    view.layoutParams = params
                }
            }
            start()
        }
    }

    /**
     * Cancels any running animation and cleans up resources.
     * Should be called when the view is detached.
     */
    fun cleanup() {
        heightAnimator?.cancel()
        heightAnimator = null
    }

    /**
     * Resets the controller state.
     * Used when the view needs to reinitialize.
     */
    fun reset() {
        cleanup()
        previousHeight = 0
        hasInitializedLayout = false
    }
}
