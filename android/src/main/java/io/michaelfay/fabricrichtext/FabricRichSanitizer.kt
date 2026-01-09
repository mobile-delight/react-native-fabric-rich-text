package io.michaelfay.fabricrichtext

import android.util.Log
import org.owasp.html.HtmlPolicyBuilder
import org.owasp.html.PolicyFactory

/**
 * HTML Sanitizer using OWASP Java HTML Sanitizer.
 *
 * Provides XSS protection by sanitizing HTML content before
 * it reaches the native Android HTML parser (Html.fromHtml).
 *
 * Security approach:
 * - Allowlist-based: Only allows known-safe tags and attributes
 * - URL protocol validation: Only http, https, mailto, tel allowed
 * - All event handlers and script content stripped
 */
class FabricRichSanitizer {
    companion object {
        private const val TAG = "FabricRichSanitizer"
    }

    /**
     * OWASP policy factory configured with our allowlist.
     * Uses FabricGeneratedConstants for tag/protocol lists (generated from src/core/constants.ts).
     * Thread-safe and reusable.
     */
    private val policy: PolicyFactory = HtmlPolicyBuilder()
        .allowElements(*FabricGeneratedConstants.ALLOWED_TAGS)
        .allowWithoutAttributes(*FabricGeneratedConstants.ALLOWED_TAGS)
        .allowAttributes("href").onElements("a")
        // Allow class attribute for styling (id removed per YAGNI - not used in rendering)
        .allowAttributes("class").globally()
        .allowUrlProtocols(*FabricGeneratedConstants.ALLOWED_PROTOCOLS)
        .toFactory()

    /**
     * Regex pattern to match whitespace between tags.
     * Matches `>` followed by one or more whitespace characters followed by `<`.
     */
    private val interTagWhitespacePattern = Regex(">\\s+<")

    /**
     * Sanitize HTML content to remove XSS vectors.
     *
     * @param html The raw HTML string to sanitize (nullable)
     * @return Sanitized HTML string safe for rendering, or empty string if input is null/error
     */
    fun sanitize(html: String?): String {
        if (html.isNullOrEmpty()) {
            return ""
        }

        return try {
            // Normalize inter-tag whitespace from source formatting (JSX indentation, etc.)
            // BEFORE sanitizing so OWASP processes clean input.
            // Browsers ignore whitespace between block elements; we do the same.
            val normalized = html.replace(interTagWhitespacePattern, "><")

            policy.sanitize(normalized).trim()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to sanitize HTML: ${e.message}", e)
            ""
        }
    }
}
