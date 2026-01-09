package io.michaelfay.fabricrichtext

import android.graphics.Rect
import android.os.Bundle
import android.text.Spannable
import android.text.style.ClickableSpan
import android.text.style.URLSpan
import android.util.Log
import android.view.View
import android.view.accessibility.AccessibilityEvent
import androidx.core.view.ViewCompat
import androidx.core.view.accessibility.AccessibilityNodeInfoCompat
import androidx.core.view.accessibility.AccessibilityNodeProviderCompat
import androidx.customview.widget.ExploreByTouchHelper

/**
 * Link type for refined accessibility announcements.
 * Detected from the href URL scheme.
 */
enum class LinkType {
    WEB,      // http:// or https:// URLs
    PHONE,    // tel: URLs
    EMAIL,    // mailto: URLs
    GENERIC   // Other URLs (relative, fragment, etc.)
}

/**
 * Accessibility delegate for FabricRichTextView that provides proper TalkBack support
 * for links using ExploreByTouchHelper virtual views.
 *
 * This follows the pattern from React Native's ReactTextViewAccessibilityDelegate,
 * which properly integrates link accessibility with the Android view hierarchy.
 *
 * Key behaviors:
 * - Creates virtual accessibility nodes for each link
 * - Uses plain text contentDescription for links (prevents TalkBack from reading span styles)
 * - Links get roleDescription = "link" and proper bounds
 * - Virtual views only exist when there are links present
 * - Focus order integrates with React Native's view hierarchy
 */
class FabricRichTextAccessibilityDelegate(
    private val hostView: FabricRichTextView,
    originalFocus: Boolean,
    originalImportantForAccessibility: Int
) : ExploreByTouchHelper(hostView) {

    companion object {
        private const val TAG = "A11Y_FHTML_Delegate"
        private val DEBUG = BuildConfig.DEBUG
    }

    init {
        // CRITICAL: ExploreByTouchHelper sets focusable=true and importantForAccessibility=YES
        // in its constructor. We MUST reset these to original values to prevent TalkBack from
        // changing its behavior globally. This matches React Native's ReactAccessibilityDelegate.
        hostView.isFocusable = originalFocus
        hostView.importantForAccessibility = originalImportantForAccessibility
        log("init: reset focusable=$originalFocus, importantForA11y=$originalImportantForAccessibility")
    }

    // Cache of link information - rebuilt when text changes
    private var accessibilityLinks: AccessibilityLinks? = null

    /**
     * Data class holding information about all links in the text
     */
    data class AccessibilityLinks(
        val links: List<LinkInfo>
    ) {
        /**
         * Returns the link at the given character offset, or null if none
         */
        fun getLinkAtOffset(offset: Int): LinkInfo? {
            return links.find { offset >= it.start && offset < it.end }
        }

        /**
         * Returns the link at the given (x, y) coordinates relative to the text layout
         */
        fun getLinkAtPoint(
            hostView: FabricRichTextView,
            x: Float,
            y: Float
        ): LinkInfo? {
            val layout = hostView.customLayout ?: hostView.layout ?: return null
            val line = layout.getLineForVertical(y.toInt())
            val offset = layout.getOffsetForHorizontal(line, x)
            return getLinkAtOffset(offset)
        }
    }

    /**
     * Information about a single link
     */
    data class LinkInfo(
        val id: Int,           // Virtual view ID (index in links list)
        val start: Int,        // Start character offset
        val end: Int,          // End character offset (exclusive)
        val text: String,      // Plain text content of the link
        val span: ClickableSpan, // The actual span for click handling
        val linkType: LinkType // Type of link (web, phone, email, generic)
    )

    private fun log(message: String) {
        if (DEBUG) {
            Log.d(TAG, "[${hostView.hashCode().toString(16)}] $message")
        }
    }

    /**
     * Rebuilds the link cache from the current text content.
     * Should be called when text changes.
     */
    fun updateLinks() {
        val spannable = hostView.stateSpannable
            ?: (hostView.text as? Spannable)
            ?: run {
                log("updateLinks: no spannable, clearing links")
                accessibilityLinks = null
                return
            }

        val spans = spannable.getSpans(0, spannable.length, ClickableSpan::class.java)
        if (spans.isEmpty()) {
            log("updateLinks: no ClickableSpan found, clearing links")
            accessibilityLinks = null
            return
        }

        val linkList = spans.mapIndexed { index, span ->
            val start = spannable.getSpanStart(span)
            val end = spannable.getSpanEnd(span)
            val text = spannable.subSequence(start, end).toString()
            val linkType = detectLinkType(span)
            LinkInfo(
                id = index,
                start = start,
                end = end,
                text = text,
                span = span,
                linkType = linkType
            )
        }.sortedBy { it.start }

        accessibilityLinks = AccessibilityLinks(linkList)
        log("updateLinks: found ${linkList.size} links")
        linkList.forEach { link ->
            log("  Link ${link.id}: '${link.text}' [${link.start}-${link.end}] type=${link.linkType}")
        }
    }

    /**
     * Detects the link type from the span's href URL.
     * Handles both HrefClickableSpan (from HTML) and URLSpan (from Linkify auto-detection).
     */
    private fun detectLinkType(span: ClickableSpan): LinkType {
        val url = when (span) {
            is HrefClickableSpan -> span.href
            is URLSpan -> span.url
            else -> return LinkType.GENERIC
        }

        val href = url.lowercase().trim()
        return when {
            href.startsWith("http://") || href.startsWith("https://") -> LinkType.WEB
            href.startsWith("tel:") -> LinkType.PHONE
            href.startsWith("mailto:") -> LinkType.EMAIL
            else -> LinkType.GENERIC
        }
    }

    /**
     * Safely retrieves a string resource with fallback.
     * Catches only NotFoundException to avoid masking other errors.
     */
    private fun safeGetString(resId: Int, vararg formatArgs: Any, fallback: String): String {
        return try {
            hostView.context.resources.getString(resId, *formatArgs)
        } catch (e: android.content.res.Resources.NotFoundException) {
            // Log missing resource for observability
            Log.w(TAG, "Resource not found: $resId, using fallback: $fallback")
            fallback
        }
    }

    /**
     * Gets the localized role description string for the given link type.
     * Falls back to English defaults if resources are not available (e.g., in tests).
     */
    private fun getRoleDescription(linkType: LinkType): String {
        return when (linkType) {
            LinkType.WEB -> safeGetString(R.string.a11y_link_web, fallback = "web link")
            LinkType.PHONE -> safeGetString(R.string.a11y_link_phone, fallback = "phone number")
            LinkType.EMAIL -> safeGetString(R.string.a11y_link_email, fallback = "email address")
            LinkType.GENERIC -> safeGetString(R.string.a11y_link, fallback = "link")
        }
    }

    /**
     * Gets the localized position string (e.g., "1 of 2").
     * Falls back to English format if resources are not available (e.g., in tests).
     */
    private fun getPositionDescription(position: Int, total: Int): String {
        return safeGetString(R.string.a11y_link_position, position, total, fallback = "$position of $total")
    }

    /**
     * Returns the number of links currently available
     */
    fun getLinkCount(): Int = accessibilityLinks?.links?.size ?: 0

    /**
     * Returns the accessibility node provider only when links exist.
     * When no links are present, returns null to use default TextView accessibility.
     *
     * This follows React Native's pattern where virtual views are only created
     * when there are actually links to navigate to.
     */
    override fun getAccessibilityNodeProvider(host: View): AccessibilityNodeProviderCompat? {
        val links = accessibilityLinks?.links
        if (links != null && links.isNotEmpty()) {
            log("getAccessibilityNodeProvider: returning provider for ${links.size} links")
            return super.getAccessibilityNodeProvider(host)
        }
        log("getAccessibilityNodeProvider: no links, returning null")
        return null
    }

    /**
     * Initializes the accessibility node info for the host view.
     * Ensures the host view uses plain text instead of styled Spannable to prevent
     * TalkBack from reading span formatting (when "Speak text formatting" is enabled).
     */
    override fun onInitializeAccessibilityNodeInfo(host: View, info: AccessibilityNodeInfoCompat) {
        super.onInitializeAccessibilityNodeInfo(host, info)

        // Get plain text description from the view
        val plainText = hostView.contentDescription?.toString()
        if (plainText != null) {
            // Set BOTH text and contentDescription to plain String
            // This prevents TalkBack from reading span formatting even when
            // "Speak text formatting" is enabled in TalkBack settings
            info.text = plainText
            info.contentDescription = plainText
            log("onInitializeAccessibilityNodeInfo(host): set plain text, length=${plainText.length}")
        }
    }

    // MARK: - ExploreByTouchHelper Implementation

    /**
     * Populates the list of virtual view IDs for all accessible links.
     * Called by the accessibility framework to enumerate focusable items.
     */
    override fun getVisibleVirtualViews(virtualViewIds: MutableList<Int>) {
        val links = accessibilityLinks?.links ?: return
        log("getVisibleVirtualViews: returning ${links.size} link IDs")
        links.forEach { link ->
            virtualViewIds.add(link.id)
        }
    }

    /**
     * Returns the virtual view ID at the given screen coordinates,
     * or INVALID_ID if the point is not on a link.
     */
    override fun getVirtualViewAt(x: Float, y: Float): Int {
        val links = accessibilityLinks ?: return INVALID_ID

        // Convert screen coordinates to layout coordinates
        val layoutX = x - hostView.paddingLeft
        val layoutY = y - hostView.paddingTop

        val link = links.getLinkAtPoint(hostView, layoutX, layoutY)
        val result = link?.id ?: INVALID_ID
        log("getVirtualViewAt($x, $y) -> layoutCoords($layoutX, $layoutY) -> $result")
        return result
    }

    /**
     * Populates accessibility information for a virtual view (link).
     * This is where we set contentDescription, bounds, actions, and role.
     *
     * Uses localized strings for:
     * - Role description: "web link", "phone number", "email address", or "link"
     * - Position: "X of Y" format localized to user's language
     */
    override fun onPopulateNodeForVirtualView(
        virtualViewId: Int,
        node: AccessibilityNodeInfoCompat
    ) {
        val links = accessibilityLinks?.links ?: return
        val link = links.getOrNull(virtualViewId) ?: return
        val totalLinks = links.size
        val position = virtualViewId + 1 // 1-indexed for user display

        log("onPopulateNodeForVirtualView: link $virtualViewId '${link.text}' type=${link.linkType}")

        // Build content description with position info if there are multiple links
        val positionSuffix = if (totalLinks > 1) {
            ", ${getPositionDescription(position, totalLinks)}"
        } else {
            ""
        }

        // Set plain text contentDescription with position - prevents TalkBack from reading span styles
        node.contentDescription = "${link.text}$positionSuffix"

        // Set localized role description based on link type
        node.roleDescription = getRoleDescription(link.linkType)

        // Set className to Button for proper link semantics
        node.className = android.widget.Button::class.java.name

        // Mark as clickable and add click action
        node.isClickable = true
        node.isFocusable = true
        node.addAction(AccessibilityNodeInfoCompat.AccessibilityActionCompat.ACTION_CLICK)

        // Calculate and set bounds
        val bounds = calculateLinkBounds(link)
        node.setBoundsInParent(bounds)
        log("  roleDescription: ${node.roleDescription}, position: $position/$totalLinks, bounds: $bounds")
    }

    /**
     * Handles accessibility actions for virtual views.
     * Returns true if the action was handled.
     */
    override fun onPerformActionForVirtualView(
        virtualViewId: Int,
        action: Int,
        arguments: Bundle?
    ): Boolean {
        val links = accessibilityLinks?.links ?: return false
        val link = links.getOrNull(virtualViewId) ?: return false

        log("onPerformActionForVirtualView: link $virtualViewId action $action")

        when (action) {
            AccessibilityNodeInfoCompat.ACTION_CLICK,
            android.view.accessibility.AccessibilityNodeInfo.ACTION_CLICK -> {
                // Perform the click action by triggering the link handler
                val url = when (val span = link.span) {
                    is HrefClickableSpan -> span.href
                    is URLSpan -> span.url
                    else -> {
                        Log.w(TAG, "Unknown span type: ${span.javaClass.simpleName}")
                        return false
                    }
                }

                val type = when (link.linkType) {
                    LinkType.PHONE -> DetectedContentType.PHONE
                    LinkType.EMAIL -> DetectedContentType.EMAIL
                    else -> DetectedContentType.LINK
                }

                return try {
                    hostView.performLinkClick(url, type)
                    log("  clicked link '${link.text}' url='$url' type=$type")
                    true
                } catch (e: IllegalArgumentException) {
                    Log.w(TAG, "Invalid URL argument for link click: $url", e)
                    false
                } catch (e: android.content.ActivityNotFoundException) {
                    Log.w(TAG, "No activity found to handle link: $url", e)
                    false
                } catch (e: SecurityException) {
                    Log.w(TAG, "Security exception clicking link: $url", e)
                    false
                }
            }
            AccessibilityNodeInfoCompat.ACTION_ACCESSIBILITY_FOCUS,
            android.view.accessibility.AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS -> {
                // Handle accessibility focus - just acknowledge it
                log("  accessibility focus gained on link '${link.text}'")
                return true
            }
            AccessibilityNodeInfoCompat.ACTION_CLEAR_ACCESSIBILITY_FOCUS,
            android.view.accessibility.AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS -> {
                // Handle clearing accessibility focus - just acknowledge it
                log("  accessibility focus cleared on link '${link.text}'")
                return true
            }
        }

        return false
    }

    /**
     * Calculates the bounding rectangle for a link in parent (view) coordinates.
     */
    private fun calculateLinkBounds(link: LinkInfo): Rect {
        val layout = hostView.customLayout ?: hostView.layout ?: return Rect()

        val startLine = layout.getLineForOffset(link.start)
        val endLine = layout.getLineForOffset(link.end - 1)

        // For single-line links, calculate precise bounds
        if (startLine == endLine) {
            val left = layout.getPrimaryHorizontal(link.start)
            val right = layout.getPrimaryHorizontal(link.end)
            val top = layout.getLineTop(startLine)
            val bottom = layout.getLineBottom(startLine)

            // Handle RTL text where right < left
            val minX = minOf(left, right).toInt()
            val maxX = maxOf(left, right).toInt()

            return Rect(
                minX + hostView.paddingLeft,
                top + hostView.paddingTop,
                maxX + hostView.paddingLeft,
                bottom + hostView.paddingTop
            )
        }

        // For multi-line links, union all line segments
        var minLeft = Int.MAX_VALUE
        var maxRight = Int.MIN_VALUE
        var top = Int.MAX_VALUE
        var bottom = Int.MIN_VALUE

        for (line in startLine..endLine) {
            val lineStart = layout.getLineStart(line)
            val lineEnd = layout.getLineEnd(line)

            val segmentStart = maxOf(link.start, lineStart)
            val segmentEnd = minOf(link.end, lineEnd)

            if (segmentStart >= segmentEnd) continue

            val left = layout.getPrimaryHorizontal(segmentStart)
            val right = layout.getPrimaryHorizontal(segmentEnd)

            minLeft = minOf(minLeft, minOf(left, right).toInt())
            maxRight = maxOf(maxRight, maxOf(left, right).toInt())
            top = minOf(top, layout.getLineTop(line))
            bottom = maxOf(bottom, layout.getLineBottom(line))
        }

        return Rect(
            minLeft + hostView.paddingLeft,
            top + hostView.paddingTop,
            maxRight + hostView.paddingLeft,
            bottom + hostView.paddingTop
        )
    }

    // MARK: - Event Dispatching

    /**
     * Sends an accessibility event for a link (e.g., focus gained)
     */
    fun sendAccessibilityEventForLink(linkId: Int, eventType: Int) {
        sendEventForVirtualView(linkId, eventType)
    }

    /**
     * Invalidates the virtual view hierarchy, causing getVisibleVirtualViews
     * to be called again.
     */
    fun invalidateVirtualViews() {
        invalidateRoot()
    }
}
