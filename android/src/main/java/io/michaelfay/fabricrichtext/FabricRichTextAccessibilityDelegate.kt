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
        private const val DEBUG = true
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
     * Gets the localized role description string for the given link type.
     * Falls back to English defaults if resources are not available (e.g., in tests).
     */
    private fun getRoleDescription(linkType: LinkType): String {
        return try {
            val resources = hostView.context.resources
            when (linkType) {
                LinkType.WEB -> resources.getString(R.string.a11y_link_web)
                LinkType.PHONE -> resources.getString(R.string.a11y_link_phone)
                LinkType.EMAIL -> resources.getString(R.string.a11y_link_email)
                LinkType.GENERIC -> resources.getString(R.string.a11y_link)
            }
        } catch (e: Exception) {
            // Fallback for test environments where resources may not be available
            when (linkType) {
                LinkType.WEB -> "web link"
                LinkType.PHONE -> "phone number"
                LinkType.EMAIL -> "email address"
                LinkType.GENERIC -> "link"
            }
        }
    }

    /**
     * Gets the localized position string (e.g., "1 of 2").
     * Falls back to English format if resources are not available (e.g., in tests).
     */
    private fun getPositionDescription(position: Int, total: Int): String {
        return try {
            hostView.context.resources.getString(R.string.a11y_link_position, position, total)
        } catch (e: Exception) {
            // Fallback for test environments
            "$position of $total"
        }
    }

    /**
     * Returns the number of links currently available
     */
    fun getLinkCount(): Int = accessibilityLinks?.links?.size ?: 0

    /**
     * Returns the number of visible links (on non-truncated lines).
     * When numberOfLines is set, only counts links that start on visible lines.
     */
    fun getVisibleLinkCount(): Int = getVisibleLinks().size

    /**
     * Returns only links that are on visible (non-truncated) lines.
     * Uses the host view's isCharacterOnVisibleLine() to filter links.
     */
    private fun getVisibleLinks(): List<LinkInfo> {
        val links = accessibilityLinks?.links ?: return emptyList()
        return links.filter { link ->
            hostView.isCharacterOnVisibleLine(link.start)
        }
    }

    /**
     * Returns the accessibility node provider only when visible links exist.
     * When no visible links are present (either no links at all, or all links are
     * on truncated lines), returns null to use default TextView accessibility.
     *
     * This follows React Native's pattern where virtual views are only created
     * when there are actually links to navigate to.
     */
    override fun getAccessibilityNodeProvider(host: View): AccessibilityNodeProviderCompat? {
        val visibleLinks = getVisibleLinks()
        if (visibleLinks.isNotEmpty()) {
            log("getAccessibilityNodeProvider: returning provider for ${visibleLinks.size} visible links")
            return super.getAccessibilityNodeProvider(host)
        }
        log("getAccessibilityNodeProvider: no visible links, returning null")
        return null
    }

    /**
     * Initializes the accessibility node info for the host view.
     * Uses the visible text (truncated if applicable) to prevent TalkBack from
     * reading span formatting and to ensure only visible content is announced.
     */
    override fun onInitializeAccessibilityNodeInfo(host: View, info: AccessibilityNodeInfoCompat) {
        super.onInitializeAccessibilityNodeInfo(host, info)

        // Get visible text from the view (truncated if applicable)
        val visibleText = hostView.getVisibleTextForAccessibility()
        if (visibleText.isNotEmpty()) {
            // Set BOTH text and contentDescription to visible text
            // This prevents TalkBack from reading span formatting and
            // ensures only visible (non-truncated) text is announced
            info.text = visibleText
            info.contentDescription = visibleText
            log("onInitializeAccessibilityNodeInfo(host): set visible text, length=${visibleText.length}")
        }
    }

    // MARK: - ExploreByTouchHelper Implementation

    /**
     * Populates the list of virtual view IDs for visible (non-truncated) links.
     * Called by the accessibility framework to enumerate focusable items.
     * Only includes links that start on visible lines when numberOfLines is set.
     */
    override fun getVisibleVirtualViews(virtualViewIds: MutableList<Int>) {
        val visibleLinks = getVisibleLinks()
        log("getVisibleVirtualViews: returning ${visibleLinks.size} visible link IDs (of ${accessibilityLinks?.links?.size ?: 0} total)")
        visibleLinks.forEach { link ->
            virtualViewIds.add(link.id)
        }
    }

    /**
     * Returns the virtual view ID at the given screen coordinates,
     * or INVALID_ID if the point is not on a visible link.
     * Only returns link IDs for links on non-truncated lines.
     */
    override fun getVirtualViewAt(x: Float, y: Float): Int {
        val links = accessibilityLinks ?: return INVALID_ID

        // Convert screen coordinates to layout coordinates
        val layoutX = x - hostView.paddingLeft
        val layoutY = y - hostView.paddingTop

        val link = links.getLinkAtPoint(hostView, layoutX, layoutY)
        // Only return link if it's on a visible line
        val result = if (link != null && hostView.isCharacterOnVisibleLine(link.start)) {
            link.id
        } else {
            INVALID_ID
        }
        log("getVirtualViewAt($x, $y) -> layoutCoords($layoutX, $layoutY) -> $result")
        return result
    }

    /**
     * Populates accessibility information for a virtual view (link).
     * This is where we set contentDescription, bounds, actions, and role.
     *
     * Uses localized strings for:
     * - Role description: "web link", "phone number", "email address", or "link"
     * - Position: "X of Y" format localized to user's language (uses visible link count)
     */
    override fun onPopulateNodeForVirtualView(
        virtualViewId: Int,
        node: AccessibilityNodeInfoCompat
    ) {
        val links = accessibilityLinks?.links ?: return
        val link = links.getOrNull(virtualViewId) ?: return

        // Use visible links for position calculation
        val visibleLinks = getVisibleLinks()
        val visiblePosition = visibleLinks.indexOfFirst { it.id == virtualViewId }
        if (visiblePosition == -1) {
            // Link is not visible (on truncated line) - shouldn't happen but handle gracefully
            log("onPopulateNodeForVirtualView: link $virtualViewId not visible, skipping")
            return
        }

        val totalVisible = visibleLinks.size
        val position = visiblePosition + 1 // 1-indexed for user display

        log("onPopulateNodeForVirtualView: link $virtualViewId '${link.text}' type=${link.linkType}")

        // Build content description with position info if there are multiple visible links
        val positionSuffix = if (totalVisible > 1) {
            ", ${getPositionDescription(position, totalVisible)}"
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
        log("  roleDescription: ${node.roleDescription}, position: $position/$totalVisible, bounds: $bounds")
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
                try {
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

                    hostView.performLinkClick(url, type)
                    log("  clicked link '${link.text}' url='$url' type=$type")
                    return true
                } catch (e: Exception) {
                    Log.w(TAG, "Error clicking link", e)
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
