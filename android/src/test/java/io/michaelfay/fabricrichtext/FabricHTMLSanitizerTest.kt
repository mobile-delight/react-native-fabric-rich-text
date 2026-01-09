package io.michaelfay.fabricrichtext

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for FabricRichSanitizer.
 *
 * Verifies that all OWASP XSS vectors are neutralized and
 * safe content passes through unchanged.
 */
class FabricRichSanitizerTest {
    private lateinit var sanitizer: FabricRichSanitizer

    @Before
    fun setUp() {
        sanitizer = FabricRichSanitizer()
    }

    // ========== Edge Cases ==========

    @Test
    fun `returns empty string for null input`() {
        assertEquals("", sanitizer.sanitize(null))
    }

    @Test
    fun `returns empty string for empty string input`() {
        assertEquals("", sanitizer.sanitize(""))
    }

    @Test
    fun `handles whitespace-only input`() {
        val result = sanitizer.sanitize("   ")
        assertTrue(result.isEmpty() || result.isBlank())
    }

    // ========== Safe Content Pass-through ==========

    @Test
    fun `preserves plain text`() {
        val input = "Just plain text with no tags"
        assertEquals(input, sanitizer.sanitize(input))
    }

    @Test
    fun `preserves paragraph elements`() {
        val input = "<p>Paragraph text</p>"
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("<p>"))
        assertTrue(output.contains("Paragraph text"))
    }

    @Test
    fun `preserves div elements`() {
        val input = "<div>Division content</div>"
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("<div>"))
    }

    @Test
    fun `preserves heading elements h1 through h6`() {
        val input = "<h1>H1</h1><h2>H2</h2><h3>H3</h3><h4>H4</h4><h5>H5</h5><h6>H6</h6>"
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("<h1>"))
        assertTrue(output.contains("<h6>"))
    }

    @Test
    fun `preserves strong and bold elements`() {
        val input = "<strong>Strong</strong> and <b>Bold</b>"
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("<strong>"))
        assertTrue(output.contains("<b>"))
    }

    @Test
    fun `preserves em and italic elements`() {
        val input = "<em>Emphasis</em> and <i>Italic</i>"
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("<em>"))
        assertTrue(output.contains("<i>"))
    }

    @Test
    fun `preserves underline strikethrough and del elements`() {
        val input = "<u>Underline</u> <s>Strike</s> <del>Deleted</del>"
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("<u>"))
        assertTrue(output.contains("<s>"))
        assertTrue(output.contains("<del>"))
    }

    @Test
    fun `preserves span and br elements`() {
        val input = "<span>Span text</span><br />"
        val output = sanitizer.sanitize(input)
        assertTrue("Expected span tag, got: $output", output.contains("<span>") && output.contains("Span text"))
        assertTrue("Expected br tag, got: $output", output.contains("<br"))
    }

    @Test
    fun `preserves blockquote and pre elements`() {
        val input = "<blockquote>Quote</blockquote><pre>Code</pre>"
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("<blockquote>"))
        assertTrue(output.contains("<pre>"))
    }

    @Test
    fun `preserves list elements`() {
        val input = "<ul><li>Item 1</li></ul><ol><li>Item 2</li></ol>"
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("<ul>"))
        assertTrue(output.contains("<ol>"))
        assertTrue(output.contains("<li>"))
    }

    @Test
    fun `preserves anchor with safe https href`() {
        val input = """<a href="https://example.com">Link</a>"""
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("<a"))
        assertTrue(output.contains("href"))
        assertTrue(output.contains("https://example.com"))
    }

    @Test
    fun `preserves mailto URLs`() {
        val input = """<a href="mailto:test@example.com">Email</a>"""
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("mailto:"))
    }

    @Test
    fun `preserves tel URLs`() {
        val input = """<a href="tel:+1234567890">Call</a>"""
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("tel:"))
    }

    @Test
    fun `preserves class attribute`() {
        val input = """<div class="container">Content</div>"""
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("""class="container""""))
    }

    @Test
    fun `removes id attribute per YAGNI`() {
        // Per YAGNI principle, id attribute is not needed for HTML rendering
        // and was removed to minimize attack surface
        val input = """<div id="main">Content</div>"""
        val output = sanitizer.sanitize(input)
        assertFalse("id attribute should be removed per YAGNI", output.contains("id="))
        assertTrue("Content should be preserved", output.contains("Content"))
    }

    @Test
    fun `preserves nested safe tags`() {
        val input = "<p><strong><em>Bold and italic</em></strong></p>"
        val output = sanitizer.sanitize(input)
        assertTrue(output.contains("<p>"))
        assertTrue(output.contains("<strong>"))
        assertTrue(output.contains("<em>"))
    }

    // ========== Script Injection (OWASP XSS Vectors) ==========

    @Test
    fun `removes script tags`() {
        val input = "<p>Safe<script>alert(1)</script></p>"
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("script"))
        assertTrue(output.contains("Safe"))
    }

    @Test
    fun `removes SCRIPT tags case insensitive`() {
        val input = "<SCRIPT>alert(1)</SCRIPT>"
        val output = sanitizer.sanitize(input)
        assertFalse(output.lowercase().contains("script"))
    }

    @Test
    fun `removes script src tags`() {
        val input = """<script src="evil.js"></script>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("script"))
        assertFalse(output.contains("evil.js"))
    }

    @Test
    fun `removes svg with onload event`() {
        val input = """<svg onload="alert(1)">"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("onload"))
        assertFalse(output.contains("alert"))
    }

    @Test
    fun `removes nested script in svg`() {
        val input = "<svg><script>alert(1)</script></svg>"
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("script"))
    }

    // ========== Event Handler Injection (OWASP XSS Vectors) ==========

    @Test
    fun `removes onerror handlers`() {
        val input = """<img onerror="alert(1)" src="x">"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("onerror"))
        assertFalse(output.contains("alert"))
    }

    @Test
    fun `removes onclick handlers`() {
        val input = """<div onclick="alert(1)">click</div>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("onclick"))
        assertTrue(output.contains("click"))
    }

    @Test
    fun `removes onload handlers`() {
        val input = """<body onload="alert(1)">"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("onload"))
    }

    @Test
    fun `removes onmouseover handlers`() {
        val input = """<a onmouseover="alert(1)">hover</a>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("onmouseover"))
    }

    @Test
    fun `removes mixed case event handlers`() {
        val input = """<div OnClIcK="alert(1)">test</div>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.lowercase().contains("onclick"))
    }

    // ========== JavaScript URL Injection (OWASP XSS Vectors) ==========

    @Test
    fun `removes javascript URLs`() {
        val input = """<a href="javascript:alert(1)">click</a>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("javascript"))
    }

    @Test
    fun `removes mixed case jAvAsCrIpT URLs`() {
        val input = """<a href="jAvAsCrIpT:alert(1)">click</a>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.lowercase().contains("javascript"))
    }

    @Test
    fun `removes HTML encoded javascript URLs`() {
        val input = """<a href="&#106;avascript:alert(1)">click</a>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.lowercase().contains("javascript"))
    }

    // ========== Data URL Injection (OWASP XSS Vectors) ==========

    @Test
    fun `removes data URLs with HTML content`() {
        val input = """<a href="data:text/html,<script>alert(1)</script>">click</a>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("data:text/html"))
    }

    @Test
    fun `removes iframe with data URL`() {
        val input = """<iframe src="data:text/html,<script>alert(1)</script>">"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("iframe"))
        assertFalse(output.contains("data:"))
    }

    // ========== CSS Expression Attacks ==========

    @Test
    fun `removes style attribute with javascript URL`() {
        val input = """<div style="background:url(javascript:alert(1))">"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("javascript"))
    }

    @Test
    fun `removes style attribute with expression`() {
        val input = """<div style="width:expression(alert(1))">"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("expression"))
    }

    // ========== Dangerous Tags Removal ==========

    @Test
    fun `removes iframe tags`() {
        val input = """<iframe src="https://evil.com"></iframe>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("iframe"))
    }

    @Test
    fun `removes object tags`() {
        val input = """<object data="malware.swf"></object>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("object"))
    }

    @Test
    fun `removes embed tags`() {
        val input = """<embed src="malware.swf">"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("embed"))
    }

    @Test
    fun `removes form tags`() {
        val input = """<form action="https://evil.com"><input></form>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("form"))
    }

    @Test
    fun `removes meta tags`() {
        val input = """<meta http-equiv="refresh" content="0;url=evil.com">"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("meta"))
    }

    @Test
    fun `removes link tags`() {
        val input = """<link rel="stylesheet" href="evil.css">"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("link"))
    }

    @Test
    fun `removes base tags`() {
        val input = """<base href="https://evil.com/">"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("base"))
    }

    // ========== Dangerous Attributes Removal ==========

    @Test
    fun `removes data attributes`() {
        val input = """<div data-evil="payload">content</div>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("data-evil"))
    }

    @Test
    fun `removes formaction attribute`() {
        val input = """<button formaction="https://evil.com">Submit</button>"""
        val output = sanitizer.sanitize(input)
        assertFalse(output.contains("formaction"))
    }

    // ========== Performance ==========

    @Test
    fun `sanitizes typical HTML quickly`() {
        val input = """<p>Museum <strong>exhibit</strong> description with <a href="https://example.com">link</a>.</p>"""

        val startTime = System.nanoTime()
        repeat(100) {
            sanitizer.sanitize(input)
        }
        val endTime = System.nanoTime()

        val averageMs = (endTime - startTime) / 100 / 1_000_000.0
        assertTrue("Average sanitization time should be < 1ms, was ${averageMs}ms", averageMs < 1.0)
    }
}
