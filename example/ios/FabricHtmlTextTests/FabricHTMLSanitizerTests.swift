import XCTest
@testable import FabricHtmlText

/**
 * Unit tests for FabricHTMLSanitizer.
 *
 * Verifies that all OWASP XSS vectors are neutralized and
 * safe content passes through unchanged.
 */
final class FabricHTMLSanitizerTests: XCTestCase {
    private var sanitizer: FabricHTMLSanitizer!

    override func setUp() {
        super.setUp()
        sanitizer = FabricHTMLSanitizer()
    }

    override func tearDown() {
        sanitizer = nil
        super.tearDown()
    }

    // MARK: - Edge Cases

    func testReturnsEmptyStringForEmptyInput() {
        XCTAssertEqual(sanitizer.sanitize(""), "")
    }

    func testHandlesWhitespaceOnlyInput() {
        let result = sanitizer.sanitize("   ")
        // Either empty or preserves whitespace is acceptable
        XCTAssertTrue(result.isEmpty || result.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    // MARK: - Safe Content Pass-through

    func testPreservesPlainText() {
        let input = "Just plain text with no tags"
        XCTAssertEqual(sanitizer.sanitize(input), input)
    }

    func testPreservesParagraphElements() {
        let input = "<p>Paragraph text</p>"
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("<p>"))
        XCTAssertTrue(output.contains("Paragraph text"))
    }

    func testPreservesDivElements() {
        let input = "<div>Division content</div>"
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("<div>"))
    }

    func testPreservesHeadingElements() {
        let input = "<h1>H1</h1><h2>H2</h2><h3>H3</h3><h4>H4</h4><h5>H5</h5><h6>H6</h6>"
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("<h1>"))
        XCTAssertTrue(output.contains("<h6>"))
    }

    func testPreservesStrongAndBoldElements() {
        let input = "<strong>Strong</strong> and <b>Bold</b>"
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("<strong>"))
        XCTAssertTrue(output.contains("<b>"))
    }

    func testPreservesEmAndItalicElements() {
        let input = "<em>Emphasis</em> and <i>Italic</i>"
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("<em>"))
        XCTAssertTrue(output.contains("<i>"))
    }

    func testPreservesUnderlineStrikethroughAndDelElements() {
        let input = "<u>Underline</u> <s>Strike</s> <del>Deleted</del>"
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("<u>"))
        XCTAssertTrue(output.contains("<s>"))
        XCTAssertTrue(output.contains("<del>"))
    }

    func testPreservesSpanAndBrElements() {
        let input = "<span>Span text</span><br>"
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("<span>"))
        XCTAssertTrue(output.contains("<br"))
    }

    func testPreservesBlockquoteAndPreElements() {
        let input = "<blockquote>Quote</blockquote><pre>Code</pre>"
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("<blockquote>"))
        XCTAssertTrue(output.contains("<pre>"))
    }

    func testPreservesListElements() {
        let input = "<ul><li>Item 1</li></ul><ol><li>Item 2</li></ol>"
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("<ul>"))
        XCTAssertTrue(output.contains("<ol>"))
        XCTAssertTrue(output.contains("<li>"))
    }

    func testPreservesAnchorWithSafeHttpsHref() {
        let input = #"<a href="https://example.com">Link</a>"#
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("<a"))
        XCTAssertTrue(output.contains("href"))
        XCTAssertTrue(output.contains("https://example.com"))
    }

    func testPreservesMailtoURLs() {
        let input = #"<a href="mailto:test@example.com">Email</a>"#
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("mailto:"))
    }

    func testPreservesTelURLs() {
        let input = #"<a href="tel:+1234567890">Call</a>"#
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("tel:"))
    }

    func testPreservesClassAttribute() {
        let input = #"<div class="container">Content</div>"#
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains(#"class="container""#))
    }

    func testRemovesIdAttributePerYAGNI() {
        // Per YAGNI principle, id attribute is not needed for HTML rendering
        // and was removed to minimize attack surface
        let input = #"<div id="main">Content</div>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("id="), "id attribute should be removed per YAGNI")
        XCTAssertTrue(output.contains("Content"), "Content should be preserved")
    }

    func testPreservesNestedSafeTags() {
        let input = "<p><strong><em>Bold and italic</em></strong></p>"
        let output = sanitizer.sanitize(input)
        XCTAssertTrue(output.contains("<p>"))
        XCTAssertTrue(output.contains("<strong>"))
        XCTAssertTrue(output.contains("<em>"))
    }

    // MARK: - Script Injection (OWASP XSS Vectors)

    func testRemovesScriptTags() {
        let input = "<p>Safe<script>alert(1)</script></p>"
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("script"))
        XCTAssertTrue(output.contains("Safe"))
    }

    func testRemovesSCRIPTTagsCaseInsensitive() {
        let input = "<SCRIPT>alert(1)</SCRIPT>"
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.lowercased().contains("script"))
    }

    func testRemovesScriptSrcTags() {
        let input = #"<script src="evil.js"></script>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("script"))
        XCTAssertFalse(output.contains("evil.js"))
    }

    func testRemovesSvgWithOnloadEvent() {
        let input = #"<svg onload="alert(1)">"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("onload"))
        XCTAssertFalse(output.contains("alert"))
    }

    func testRemovesNestedScriptInSvg() {
        let input = "<svg><script>alert(1)</script></svg>"
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("script"))
    }

    // MARK: - Event Handler Injection (OWASP XSS Vectors)

    func testRemovesOnerrorHandlers() {
        let input = #"<img onerror="alert(1)" src="x">"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("onerror"))
        XCTAssertFalse(output.contains("alert"))
    }

    func testRemovesOnclickHandlers() {
        let input = #"<div onclick="alert(1)">click</div>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("onclick"))
        XCTAssertTrue(output.contains("click"))
    }

    func testRemovesOnloadHandlers() {
        let input = #"<body onload="alert(1)">"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("onload"))
    }

    func testRemovesOnmouseoverHandlers() {
        let input = #"<a onmouseover="alert(1)">hover</a>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("onmouseover"))
    }

    func testRemovesMixedCaseEventHandlers() {
        let input = #"<div OnClIcK="alert(1)">test</div>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.lowercased().contains("onclick"))
    }

    // MARK: - JavaScript URL Injection (OWASP XSS Vectors)

    func testRemovesJavascriptURLs() {
        let input = #"<a href="javascript:alert(1)">click</a>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("javascript"))
    }

    func testRemovesMixedCaseJavaScriptURLs() {
        let input = #"<a href="jAvAsCrIpT:alert(1)">click</a>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.lowercased().contains("javascript"))
    }

    func testRemovesHTMLEncodedJavascriptURLs() {
        let input = #"<a href="&#106;avascript:alert(1)">click</a>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.lowercased().contains("javascript"))
    }

    // MARK: - Data URL Injection (OWASP XSS Vectors)

    func testRemovesDataURLsWithHTMLContent() {
        let input = #"<a href="data:text/html,<script>alert(1)</script>">click</a>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("data:text/html"))
    }

    func testRemovesIframeWithDataURL() {
        let input = #"<iframe src="data:text/html,<script>alert(1)</script>">"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("iframe"))
        XCTAssertFalse(output.contains("data:"))
    }

    // MARK: - CSS Expression Attacks

    func testRemovesStyleAttributeWithJavascriptURL() {
        let input = #"<div style="background:url(javascript:alert(1))">"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("javascript"))
    }

    func testRemovesStyleAttributeWithExpression() {
        let input = #"<div style="width:expression(alert(1))">"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("expression"))
    }

    // MARK: - Dangerous Tags Removal

    func testRemovesIframeTags() {
        let input = #"<iframe src="https://evil.com"></iframe>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("iframe"))
    }

    func testRemovesObjectTags() {
        let input = #"<object data="malware.swf"></object>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("object"))
    }

    func testRemovesEmbedTags() {
        let input = #"<embed src="malware.swf">"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("embed"))
    }

    func testRemovesFormTags() {
        let input = #"<form action="https://evil.com"><input></form>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("form"))
    }

    func testRemovesMetaTags() {
        let input = #"<meta http-equiv="refresh" content="0;url=evil.com">"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("meta"))
    }

    func testRemovesLinkTags() {
        let input = #"<link rel="stylesheet" href="evil.css">"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("link"))
    }

    func testRemovesBaseTags() {
        let input = #"<base href="https://evil.com/">"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("base"))
    }

    // MARK: - Dangerous Attributes Removal

    func testRemovesDataAttributes() {
        let input = #"<div data-evil="payload">content</div>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("data-evil"))
    }

    func testRemovesFormactionAttribute() {
        let input = #"<button formaction="https://evil.com">Submit</button>"#
        let output = sanitizer.sanitize(input)
        XCTAssertFalse(output.contains("formaction"))
    }

    // MARK: - Performance

    func testSanitizesTypicalHTMLQuickly() {
        let input = #"<p>Museum <strong>exhibit</strong> description with <a href="https://example.com">link</a>.</p>"#

        let iterations = 100
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = sanitizer.sanitize(input)
        }
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        let avgMs = elapsed / Double(iterations)

        // Warning only - CI runners have variable performance
        if avgMs >= 1.0 {
            print("⚠️ PERFORMANCE WARNING: Average sanitization time \(avgMs)ms exceeds 1ms target")
        }
    }

    func testPerformanceMeasure() {
        let input = #"<p>Museum <strong>exhibit</strong> description with <a href="https://example.com">link</a>.</p>"#

        measure {
            for _ in 0..<100 {
                _ = sanitizer.sanitize(input)
            }
        }
    }
}
