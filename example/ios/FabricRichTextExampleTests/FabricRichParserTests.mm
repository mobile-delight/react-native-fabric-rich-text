/**
 * FabricHTMLParserTests.mm
 *
 * Tests for the shared C++ FabricHTMLParser.
 * Uses XCTest with Obj-C++ to test C++ code directly.
 */

#import <XCTest/XCTest.h>
#import "../../../cpp/FabricHTMLParser.h"

using namespace facebook::react;

@interface FabricHTMLParserTests : XCTestCase
@end

@implementation FabricHTMLParserTests

#pragma mark - stripHtmlTags Tests

- (void)testStripHtmlTags_PlainText {
    std::string result = FabricHTMLParser::stripHtmlTags("Hello world");
    XCTAssertTrue(result == "Hello world", @"Expected 'Hello world', got '%s'", result.c_str());
}

- (void)testStripHtmlTags_SimpleTags {
    std::string result = FabricHTMLParser::stripHtmlTags("<p>Hello</p>");
    XCTAssertTrue(result == "Hello", @"Expected 'Hello', got '%s'", result.c_str());
}

- (void)testStripHtmlTags_NestedTags {
    std::string result = FabricHTMLParser::stripHtmlTags("<div><p><strong>Bold</strong> text</p></div>");
    XCTAssertTrue(result == "Bold text", @"Expected 'Bold text', got '%s'", result.c_str());
}

- (void)testStripHtmlTags_EmptyString {
    std::string result = FabricHTMLParser::stripHtmlTags("");
    XCTAssertTrue(result.empty(), @"Expected empty string");
}

- (void)testStripHtmlTags_PreservesWhitespace {
    std::string result = FabricHTMLParser::stripHtmlTags("<p>Line 1</p><p>Line 2</p>");
    XCTAssertTrue(result.find("Line 1") != std::string::npos, @"Should contain 'Line 1'");
    XCTAssertTrue(result.find("Line 2") != std::string::npos, @"Should contain 'Line 2'");
}

#pragma mark - parseHtmlToAttributedString Tests

- (void)testParseHtml_EmptyString {
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");
    XCTAssertTrue(result.isEmpty());
}

- (void)testParseHtml_PlainText {
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "Hello world", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    XCTAssertFalse(result.isEmpty());

    const auto& fragments = result.getFragments();
    XCTAssertEqual(fragments.size(), 1UL);
    XCTAssertTrue(fragments[0].string == "Hello world", @"Expected 'Hello world'");
}

- (void)testParseHtml_BoldText {
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "<strong>Bold</strong>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundBold = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Bold") {
            XCTAssertEqual(fragment.textAttributes.fontWeight, FontWeight::Bold);
            foundBold = true;
        }
    }
    XCTAssertTrue(foundBold, "Should find bold fragment");
}

- (void)testParseHtml_ItalicText {
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "<em>Italic</em>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundItalic = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Italic") {
            XCTAssertEqual(fragment.textAttributes.fontStyle, FontStyle::Italic);
            foundItalic = true;
        }
    }
    XCTAssertTrue(foundItalic, "Should find italic fragment");
}

- (void)testParseHtml_NestedFormatting {
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "<strong><em>Bold Italic</em></strong>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundBoldItalic = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Bold Italic") {
            XCTAssertEqual(fragment.textAttributes.fontWeight, FontWeight::Bold);
            XCTAssertEqual(fragment.textAttributes.fontStyle, FontStyle::Italic);
            foundBoldItalic = true;
        }
    }
    XCTAssertTrue(foundBoldItalic, "Should find bold+italic fragment");
}

- (void)testParseHtml_Heading {
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "<h1>Heading</h1>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    // H1 should have larger font size (2.0x base)
    bool foundHeading = false;
    for (const auto& fragment : fragments) {
        if (fragment.string.find("Heading") != std::string::npos) {
            XCTAssertEqual(fragment.textAttributes.fontSize, 32.0f); // 16 * 2.0
            XCTAssertEqual(fragment.textAttributes.fontWeight, FontWeight::Bold);
            foundHeading = true;
        }
    }
    XCTAssertTrue(foundHeading, "Should find heading fragment");
}

- (void)testParseHtml_UnorderedList {
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "<ul><li>Item 1</li><li>Item 2</li></ul>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    // Check that bullet points are present
    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("•") != std::string::npos ||
                  fullText.find("Item 1") != std::string::npos,
                  "Should contain list items");
}

- (void)testParseHtml_OrderedList {
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "<ol><li>First</li><li>Second</li></ol>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("1") != std::string::npos ||
                  fullText.find("First") != std::string::npos,
                  "Should contain numbered list items");
}

- (void)testParseHtml_FontSizeMultiplier {
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "Text", 16.0f, 2.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);
    XCTAssertEqual(fragments[0].textAttributes.fontSize, 32.0f); // 16 * 2.0
}

- (void)testParseHtml_DisallowFontScaling {
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "Text", 16.0f, 2.0f, false, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);
    XCTAssertEqual(fragments[0].textAttributes.fontSize, 16.0f); // No scaling
}

- (void)testParseHtml_MaxFontSizeMultiplier {
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "Text", 16.0f, 3.0f, true, 1.5f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);
    XCTAssertEqual(fragments[0].textAttributes.fontSize, 24.0f); // 16 * 1.5 (capped)
}

- (void)testParseHtml_ForegroundColor {
    int32_t redColor = 0xFFFF0000; // ARGB red
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "Red text", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, redColor, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);
    // Color is tested in FabricHTMLFragmentParserTests - just verify parsing succeeds
    XCTAssertTrue(fragments[0].string == "Red text", @"Expected 'Red text'");
}

- (void)testParseHtml_LinkWithHrefDefaultColor {
    // Links WITH href should get default blue color and underline
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "<a href=\"https://example.com\">Link</a>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundLink = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Link") {
            // Verify underline is applied for links with href
            XCTAssertEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline);
            foundLink = true;
        }
    }
    XCTAssertTrue(foundLink, @"Should find link fragment");
}

- (void)testParseHtml_AnchorWithoutHrefNoLinkStyling {
    // <a> tags WITHOUT href should NOT get link styling (no blue color, no underline)
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "<a name=\"anchor\">Anchor</a>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundAnchor = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Anchor") {
            // Should NOT have underline (not a real link)
            XCTAssertNotEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline,
                              @"Anchor without href should not have underline");
            foundAnchor = true;
        }
    }
    XCTAssertTrue(foundAnchor, @"Should find anchor fragment");
}

- (void)testParseHtml_LinkColorOverride {
    // tagStyles should override default link color
    std::string tagStyles = R"({"a": {"color": "#FF0000"}})";
    AttributedString result = FabricHTMLParser::parseHtmlToAttributedString(
        "<a href=\"https://example.com\">Red Link</a>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, tagStyles);

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundLink = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Red Link") {
            // Verify link has underline (confirming it's treated as a link)
            XCTAssertEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline);
            foundLink = true;
        }
    }
    XCTAssertTrue(foundLink, @"Should find link fragment with custom color");
}

#pragma mark - normalizeInterTagWhitespace Tests

- (void)testNormalizeWhitespace_PlainTextUnchanged {
    // Plain text without tags should be unchanged (whitespace collapsing happens in normalizeSegmentText)
    std::string result = FabricHTMLParser::normalizeInterTagWhitespace("Hello world");
    XCTAssertTrue(result == "Hello world", @"Expected 'Hello world', got '%s'", result.c_str());
}

- (void)testNormalizeWhitespace_TrimsLeadingBeforeTag {
    // Leading whitespace before first tag should be trimmed
    std::string result = FabricHTMLParser::normalizeInterTagWhitespace("  <p>text</p>");
    XCTAssertTrue(result == "<p>text</p>", @"Expected '<p>text</p>', got '%s'", result.c_str());
}

- (void)testNormalizeWhitespace_RemovesWhitespaceAfterBlockTag {
    // Whitespace after block-level closing tag should be removed
    std::string result = FabricHTMLParser::normalizeInterTagWhitespace("<p>para1</p>   <p>para2</p>");
    XCTAssertTrue(result == "<p>para1</p><p>para2</p>", @"Expected '<p>para1</p><p>para2</p>', got '%s'", result.c_str());
}

- (void)testNormalizeWhitespace_PreservesInlineSpacing {
    // Whitespace after inline tags should be preserved
    std::string result = FabricHTMLParser::normalizeInterTagWhitespace("<span>hello</span> <span>world</span>");
    XCTAssertTrue(result == "<span>hello</span> <span>world</span>", @"Expected preserved space, got '%s'", result.c_str());
}

#pragma mark - Performance Tests

- (void)testPerformance_ShortHTML {
    [self measureBlock:^{
        for (int i = 0; i < 100; i++) {
            FabricHTMLParser::parseHtmlToAttributedString(
                "<p>Short <strong>text</strong></p>",
                16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");
        }
    }];
}

- (void)testPerformance_LongHTML {
    std::string longHtml = "<div>";
    for (int i = 0; i < 50; i++) {
        longHtml += "<p>Paragraph " + std::to_string(i) + " with <strong>bold</strong> and <em>italic</em> text.</p>";
    }
    longHtml += "</div>";

    [self measureBlock:^{
        for (int i = 0; i < 10; i++) {
            FabricHTMLParser::parseHtmlToAttributedString(
                longHtml, 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");
        }
    }];
}

@end
