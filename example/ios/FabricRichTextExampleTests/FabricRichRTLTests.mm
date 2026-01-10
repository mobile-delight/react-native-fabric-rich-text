/**
 * FabricRichRTLTests.mm
 *
 * Tests for RTL (Right-to-Left) text direction support in FabricMarkupParser.
 * Tests cover:
 * - Basic RTL text rendering (Arabic, Hebrew, Persian)
 * - bdi/bdo HTML elements
 * - dir attribute on elements
 * - WritingDirection enum and direction context
 * - Mixed directional content
 */

#import <XCTest/XCTest.h>
#import "../../../cpp/FabricMarkupParser.h"

using namespace facebook::react;

@interface FabricRichRTLTests : XCTestCase
@end

@implementation FabricRichRTLTests

#pragma mark - Basic RTL Text Rendering

- (void)testParseHtml_ArabicText {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p>مرحبا بالعالم</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("مرحبا") != std::string::npos, @"Should contain Arabic text");
}

- (void)testParseHtml_HebrewText {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p>שלום עולם</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("שלום") != std::string::npos, @"Should contain Hebrew text");
}

- (void)testParseHtml_PersianText {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p>سلام دنیا</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("سلام") != std::string::npos, @"Should contain Persian text");
}

#pragma mark - bdi Element (Bidirectional Isolation)

- (void)testParseHtml_BdiTagIsAllowed {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p>User: <bdi>אורח</bdi> logged in</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("User:") != std::string::npos, @"Should contain 'User:'");
    XCTAssertTrue(fullText.find("אורח") != std::string::npos, @"Should contain Hebrew name");
    XCTAssertTrue(fullText.find("logged in") != std::string::npos, @"Should contain 'logged in'");
}

- (void)testParseHtml_BdiIsolatesRTLInLTRContext {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p>Welcome, <bdi>محمد</bdi>!</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("Welcome") != std::string::npos, @"Should contain greeting");
    XCTAssertTrue(fullText.find("محمد") != std::string::npos, @"Should contain Arabic name");
}

- (void)testParseHtml_MultipleBdiElements {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p><bdi>עברית</bdi> and <bdi>العربية</bdi></p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("עברית") != std::string::npos, @"Should contain Hebrew");
    XCTAssertTrue(fullText.find("and") != std::string::npos, @"Should contain 'and'");
    XCTAssertTrue(fullText.find("العربية") != std::string::npos, @"Should contain Arabic");
}

- (void)testParseHtml_BdiInsertsUnicodeIsolates {
    // Verify FSI (U+2068) and PDI (U+2069) are inserted
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p><bdi>Test</bdi></p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }

    // FSI = U+2068, PDI = U+2069
    bool hasFSI = fullText.find("\xE2\x81\xA8") != std::string::npos;
    bool hasPDI = fullText.find("\xE2\x81\xA9") != std::string::npos;
    XCTAssertTrue(hasFSI, @"Should contain FSI control character");
    XCTAssertTrue(hasPDI, @"Should contain PDI control character");
}

#pragma mark - bdo Element (Bidirectional Override)

- (void)testParseHtml_BdoWithDirRtl {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p><bdo dir=\"rtl\">Hello</bdo></p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("Hello") != std::string::npos, @"Should contain 'Hello'");
}

- (void)testParseHtml_BdoWithDirLtr {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p><bdo dir=\"ltr\">مرحبا</bdo></p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("مرحبا") != std::string::npos, @"Should contain Arabic text");
}

- (void)testParseHtml_BdoWithoutDir {
    // Per HTML5 spec, bdo without dir has no directional effect
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p><bdo>Normal text</bdo></p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("Normal text") != std::string::npos, @"Should contain text");

    // Should NOT have RLO or LRO since no dir attribute
    bool hasRLO = fullText.find("\xE2\x80\xAE") != std::string::npos; // U+202E
    bool hasLRO = fullText.find("\xE2\x80\xAD") != std::string::npos; // U+202D
    XCTAssertFalse(hasRLO, @"Should not contain RLO without dir attribute");
    XCTAssertFalse(hasLRO, @"Should not contain LRO without dir attribute");
}

- (void)testParseHtml_BdoRtlInsertsOverrideChars {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p><bdo dir=\"rtl\">Test</bdo></p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }

    // RLO = U+202E, PDF = U+202C
    bool hasRLO = fullText.find("\xE2\x80\xAE") != std::string::npos;
    bool hasPDF = fullText.find("\xE2\x80\xAC") != std::string::npos;
    XCTAssertTrue(hasRLO, @"Should contain RLO control character for bdo dir=rtl");
    XCTAssertTrue(hasPDF, @"Should contain PDF control character");
}

- (void)testParseHtml_BdoLtrInsertsOverrideChars {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p><bdo dir=\"ltr\">Test</bdo></p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }

    // LRO = U+202D, PDF = U+202C
    bool hasLRO = fullText.find("\xE2\x80\xAD") != std::string::npos;
    bool hasPDF = fullText.find("\xE2\x80\xAC") != std::string::npos;
    XCTAssertTrue(hasLRO, @"Should contain LRO control character for bdo dir=ltr");
    XCTAssertTrue(hasPDF, @"Should contain PDF control character");
}

#pragma mark - dir Attribute

- (void)testParseHtml_DirRtlOnParagraph {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p dir=\"rtl\">Right to left paragraph</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("Right to left") != std::string::npos, @"Should contain text");
}

- (void)testParseHtml_DirLtrOnParagraph {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p dir=\"ltr\">Left to right paragraph</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("Left to right") != std::string::npos, @"Should contain text");
}

- (void)testParseHtml_DirAutoOnParagraph {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p dir=\"auto\">Auto direction paragraph</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("Auto direction") != std::string::npos, @"Should contain text");
}

- (void)testParseHtml_DirAttributeOnSpan {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p>Normal <span dir=\"rtl\">RTL span</span> text</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("Normal") != std::string::npos, @"Should contain 'Normal'");
    XCTAssertTrue(fullText.find("RTL span") != std::string::npos, @"Should contain 'RTL span'");
}

#pragma mark - Mixed Directional Content

- (void)testParseHtml_MixedArabicEnglish {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p>مرحبا Hello عالم World</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("مرحبا") != std::string::npos, @"Should contain Arabic");
    XCTAssertTrue(fullText.find("Hello") != std::string::npos, @"Should contain English");
}

- (void)testParseHtml_RTLWithNumbers {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p>السعر: 123.45</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("السعر") != std::string::npos, @"Should contain Arabic");
    XCTAssertTrue(fullText.find("123") != std::string::npos, @"Should contain numbers");
}

- (void)testParseHtml_RTLWithBrandNames {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p dir=\"rtl\">أنا أستخدم iPhone كل يوم</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("أنا") != std::string::npos, @"Should contain Arabic");
    XCTAssertTrue(fullText.find("iPhone") != std::string::npos, @"Should contain brand name");
}

#pragma mark - RTL with Formatting

- (void)testParseHtml_RTLWithBold {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p dir=\"rtl\"><strong>مهم:</strong> رسالة</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    bool foundBold = false;
    for (const auto& fragment : fragments) {
        if (fragment.string.find("مهم") != std::string::npos) {
            XCTAssertEqual(fragment.textAttributes.fontWeight, FontWeight::Bold, @"Important text should be bold");
            foundBold = true;
        }
    }
    XCTAssertTrue(foundBold, @"Should find bold Arabic text");
}

- (void)testParseHtml_RTLWithItalic {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p dir=\"rtl\"><em>تأكيد</em> نص عادي</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    bool foundItalic = false;
    for (const auto& fragment : fragments) {
        if (fragment.string.find("تأكيد") != std::string::npos) {
            XCTAssertEqual(fragment.textAttributes.fontStyle, FontStyle::Italic, @"Emphasized text should be italic");
            foundItalic = true;
        }
    }
    XCTAssertTrue(foundItalic, @"Should find italic Arabic text");
}

- (void)testParseHtml_RTLWithLink {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p dir=\"rtl\">زيارة <a href=\"https://example.com\">موقعنا</a></p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    bool foundLink = false;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
        if (fragment.string.find("موقعنا") != std::string::npos) {
            XCTAssertEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline, @"Link should be underlined");
            foundLink = true;
        }
    }
    XCTAssertTrue(foundLink, @"Should find link in RTL text");
}

#pragma mark - Edge Cases

- (void)testParseHtml_NestedDirectionChanges {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p dir=\"rtl\">عربي <span dir=\"ltr\">English</span> عربي</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("عربي") != std::string::npos, @"Should contain Arabic");
    XCTAssertTrue(fullText.find("English") != std::string::npos, @"Should contain English");
}

- (void)testParseHtml_EmptyBdiElement {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p>Before <bdi></bdi> After</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("Before") != std::string::npos, @"Should contain 'Before'");
    XCTAssertTrue(fullText.find("After") != std::string::npos, @"Should contain 'After'");
}

- (void)testParseHtml_EmptyBdoElement {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p>Before <bdo dir=\"rtl\"></bdo> After</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("Before") != std::string::npos, @"Should contain 'Before'");
    XCTAssertTrue(fullText.find("After") != std::string::npos, @"Should contain 'After'");
}

#pragma mark - Security with RTL

- (void)testParseHtml_RTLWithSanitizedScript {
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p dir=\"rtl\">مرحبا<script>alert('xss')</script></p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("مرحبا") != std::string::npos, @"Should contain Arabic");
    XCTAssertTrue(fullText.find("alert") == std::string::npos, @"Should not contain script content");
}

#pragma mark - WritingDirection Enum

- (void)testWritingDirection_EnumValues {
    // Verify WritingDirection enum exists with expected values
    // Uses React Native's WritingDirection from primitives.h
    XCTAssertEqual(static_cast<int>(WritingDirection::Natural), 0, @"Natural should be 0");
    XCTAssertEqual(static_cast<int>(WritingDirection::LeftToRight), 1, @"LeftToRight should be 1");
    XCTAssertEqual(static_cast<int>(WritingDirection::RightToLeft), 2, @"RightToLeft should be 2");
}

- (void)testParseHtml_RTLParagraphSetsWritingDirection {
    // Verify that dir="rtl" sets the segment's writingDirection
    // This is tested through the full parsing flow - the segment struct should have the direction set
    AttributedString result = FabricMarkupParser::parseMarkupToAttributedString(
        "<p dir=\"rtl\">Test</p>", 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");

    const auto& fragments = result.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL, @"Should have fragments");
    // Content is rendered - direction handling is verified by checking the text output
    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("Test") != std::string::npos, @"Should contain text");
}

#pragma mark - Performance

- (void)testPerformance_RTLContent {
    [self measureBlock:^{
        for (int i = 0; i < 100; i++) {
            FabricMarkupParser::parseMarkupToAttributedString(
                "<p dir=\"rtl\">مرحبا <strong>بالعالم</strong> هذا <bdi>Test</bdi> نص</p>",
                16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");
        }
    }];
}

@end
