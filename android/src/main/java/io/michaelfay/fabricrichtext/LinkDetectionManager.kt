package io.michaelfay.fabricrichtext

import android.text.Spannable
import android.text.SpannableString
import android.text.util.Linkify
import android.util.Log

/**
 * Manages auto-detection of links, phone numbers, and email addresses.
 * Uses Android's Linkify to detect and create URLSpans on text.
 *
 * Single Responsibility: Link detection with thread-safe prop management
 */
class LinkDetectionManager {

    companion object {
        private const val TAG = "LinkDetectionManager"
    }

    // Detection props - thread-safe access via detectionLock
    private var detectLinks: Boolean = false
    private var detectPhoneNumbers: Boolean = false
    private var detectEmails: Boolean = false
    private val detectionLock = Any()

    /**
     * Callback interface for when detection is applied.
     */
    interface DetectionCallback {
        fun onDetectionApplied(newSpannable: Spannable)
    }

    /**
     * Sets the detectLinks prop.
     * @return true if the value changed
     */
    fun setDetectLinks(detect: Boolean): Boolean {
        synchronized(detectionLock) {
            if (detectLinks != detect) {
                detectLinks = detect
                return true
            }
            return false
        }
    }

    /**
     * Sets the detectPhoneNumbers prop.
     * @return true if the value changed
     */
    fun setDetectPhoneNumbers(detect: Boolean): Boolean {
        synchronized(detectionLock) {
            if (detectPhoneNumbers != detect) {
                detectPhoneNumbers = detect
                return true
            }
            return false
        }
    }

    /**
     * Sets the detectEmails prop.
     * @return true if the value changed
     */
    fun setDetectEmails(detect: Boolean): Boolean {
        synchronized(detectionLock) {
            if (detectEmails != detect) {
                detectEmails = detect
                return true
            }
            return false
        }
    }

    /**
     * Check if any detection is enabled.
     */
    fun isDetectionEnabled(): Boolean {
        synchronized(detectionLock) {
            return detectLinks || detectPhoneNumbers || detectEmails
        }
    }

    /**
     * Apply auto-detection to the given text if any detection props are enabled.
     * Uses Android's Linkify to detect URLs, emails, and phone numbers.
     *
     * Creates a COPY of the spannable before applying Linkify to avoid:
     * 1. Mutating the original spannable (thread safety)
     * 2. Accumulating duplicate spans on repeated calls
     *
     * @param source The source spannable to detect links in
     * @return A new spannable with links detected, or null if no detection was applied
     */
    fun applyDetection(source: Spannable?): Spannable? {
        if (source == null) return null

        synchronized(detectionLock) {
            // Build the Linkify mask based on enabled detection
            var mask = 0
            if (detectLinks) {
                mask = mask or Linkify.WEB_URLS
            }
            if (detectPhoneNumbers) {
                mask = mask or Linkify.PHONE_NUMBERS
            }
            if (detectEmails) {
                mask = mask or Linkify.EMAIL_ADDRESSES
            }

            if (mask == 0) {
                return null
            }

            // Create a copy to avoid mutating the original spannable
            val spannable = SpannableString(source)

            // Apply Linkify to detect and create URLSpans on the copy
            try {
                Linkify.addLinks(spannable, mask)
            } catch (e: RuntimeException) {
                // Linkify can throw RuntimeException or PatternSyntaxException on malformed patterns.
                // Log and continue without detection. We catch RuntimeException specifically to let
                // Errors (OutOfMemoryError, etc.) propagate rather than silently swallowing them.
                Log.w(TAG, "Linkify.addLinks failed", e)
                return null
            }

            return spannable
        }
    }
}
