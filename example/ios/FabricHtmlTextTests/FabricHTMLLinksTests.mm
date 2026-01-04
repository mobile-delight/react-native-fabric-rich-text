/**
 * FabricHTMLLinksTests.mm
 *
 * Tests for link parsing functionality in FabricHTMLParser.
 * Mirrors Android FabricHTMLLinksTest.kt for cross-platform parity.
 */

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "../../../cpp/FabricHTMLParser.h"
#import "../../../ios/FabricHTMLFragmentParser.h"

using namespace facebook::react;

@interface FabricHTMLLinksTests : XCTestCase
@end

@implementation FabricHTMLLinksTests

#pragma mark - Helper Methods

- (FabricHTMLParser::ParseResult)parseHTMLWithLinks:(NSString *)html {
    std::string htmlStr = [html UTF8String] ?: "";
    return FabricHTMLParser::parseHtmlWithLinkUrls(
        htmlStr, 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");
}

- (AttributedString)parseHTML:(NSString *)html {
    return [self parseHTMLWithLinks:html].attributedString;
}

- (NSAttributedString *)parseToNSAttributedString:(NSString *)html {
    auto result = [self parseHTMLWithLinks:html];
    return [FabricHTMLFragmentParser buildAttributedStringFromCppAttributedString:result.attributedString
                                                                     withLinkUrls:result.linkUrls];
}

#pragma mark - Link Parsing Tests (FR-001)

- (void)testLinkTagParsesHrefAndAppliesAttributes {
    NSAttributedString *result = [self parseToNSAttributedString:@"<a href=\"https://example.com\">Click here</a>"];

    XCTAssertEqualObjects(result.string, @"Click here");

    // Verify link URL is stored
    NSURL *linkURL = [result attribute:NSLinkAttributeName atIndex:0 effectiveRange:nil];
    XCTAssertNotNil(linkURL, @"Should have NSLinkAttributeName");
}

- (void)testLinkTagAppliesUnderline {
    AttributedString cpp = [self parseHTML:@"<a href=\"https://example.com\">Underlined</a>"];

    const auto& fragments = cpp.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundUnderline = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Underlined") {
            XCTAssertEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline);
            foundUnderline = true;
        }
    }
    XCTAssertTrue(foundUnderline, @"Link should have underline decoration");
}

#pragma mark - Link URL Types (FR-002)

- (void)testLinkTagWithRelativeURL {
    // Relative URLs don't have a scheme (http/https/mailto/tel) so they get
    // underline styling but not NSLinkAttributeName for security reasons.
    // The component handles relative URL taps through the onLinkPress callback.
    AttributedString cpp = [self parseHTML:@"<a href=\"/path/to/page\">Relative</a>"];

    const auto& fragments = cpp.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundLink = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Relative") {
            XCTAssertEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline,
                          @"Relative link should have underline styling");
            foundLink = true;
        }
    }
    XCTAssertTrue(foundLink, @"Should find relative link fragment");
}

- (void)testLinkTagWithAnchorFragment {
    AttributedString cpp = [self parseHTML:@"<a href=\"#section\">Jump</a>"];

    const auto& fragments = cpp.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundLink = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Jump") {
            XCTAssertEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline,
                          @"Anchor link should have underline");
            foundLink = true;
        }
    }
    XCTAssertTrue(foundLink, @"Should find anchor link fragment");
}

- (void)testLinkTagWithMailtoURL {
    AttributedString cpp = [self parseHTML:@"<a href=\"mailto:test@example.com\">Email</a>"];

    const auto& fragments = cpp.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundLink = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Email") {
            XCTAssertEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline,
                          @"Mailto link should have underline");
            foundLink = true;
        }
    }
    XCTAssertTrue(foundLink, @"Should find mailto link fragment");
}

#pragma mark - Empty/Invalid Link Tests (Edge Cases)

- (void)testLinkTagWithEmptyHrefRendersAsPlainText {
    AttributedString cpp = [self parseHTML:@"<a href=\"\">No link</a>"];

    const auto& fragments = cpp.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("No link") != std::string::npos, @"Should contain text");

    // Verify NO underline for empty href
    for (const auto& fragment : fragments) {
        if (fragment.string.find("No link") != std::string::npos) {
            XCTAssertNotEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline,
                             @"Empty href should NOT have underline");
        }
    }
}

- (void)testLinkTagWithNoHrefRendersAsPlainText {
    AttributedString cpp = [self parseHTML:@"<a>No href attribute</a>"];

    const auto& fragments = cpp.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    std::string fullText;
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    XCTAssertTrue(fullText.find("No href attribute") != std::string::npos, @"Should contain text");

    // Verify NO underline for missing href
    for (const auto& fragment : fragments) {
        if (fragment.string.find("No href") != std::string::npos) {
            XCTAssertNotEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline,
                             @"Missing href should NOT have underline");
        }
    }
}

#pragma mark - Nested Formatting in Links

- (void)testLinkTagWithBoldText {
    AttributedString cpp = [self parseHTML:@"<a href=\"https://example.com\"><strong>Bold link</strong></a>"];

    const auto& fragments = cpp.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundBoldLink = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Bold link") {
            XCTAssertEqual(fragment.textAttributes.fontWeight, FontWeight::Bold,
                          @"Should have bold font weight");
            XCTAssertEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline,
                          @"Should have underline for link");
            foundBoldLink = true;
        }
    }
    XCTAssertTrue(foundBoldLink, @"Should find bold link fragment");
}

- (void)testLinkTagWithItalicText {
    AttributedString cpp = [self parseHTML:@"<a href=\"https://example.com\"><em>Italic link</em></a>"];

    const auto& fragments = cpp.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundItalicLink = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Italic link") {
            XCTAssertEqual(fragment.textAttributes.fontStyle, FontStyle::Italic,
                          @"Should have italic font style");
            XCTAssertEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline,
                          @"Should have underline for link");
            foundItalicLink = true;
        }
    }
    XCTAssertTrue(foundItalicLink, @"Should find italic link fragment");
}

#pragma mark - Multiple Links

- (void)testMultipleLinksInSameParagraph {
    AttributedString cpp = [self parseHTML:@"Visit <a href=\"https://a.com\">A</a> or <a href=\"https://b.com\">B</a>"];

    const auto& fragments = cpp.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    int linkCount = 0;
    for (const auto& fragment : fragments) {
        if (fragment.textAttributes.textDecorationLineType == TextDecorationLineType::Underline) {
            linkCount++;
        }
    }
    XCTAssertEqual(linkCount, 2, @"Should have two links with underlines");
}

#pragma mark - Link Click Accessibility

- (void)testLinkAccessibleViaNSAttributedString {
    NSAttributedString *result = [self parseToNSAttributedString:@"<a href=\"https://example.com\">Accessible link</a>"];

    // VoiceOver and other accessibility tools can access links via NSLinkAttributeName
    __block BOOL hasLink = NO;
    [result enumerateAttribute:NSLinkAttributeName
                       inRange:NSMakeRange(0, result.length)
                       options:0
                    usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            hasLink = YES;
            *stop = YES;
        }
    }];
    XCTAssertTrue(hasLink, @"Link should be accessible via NSLinkAttributeName");
}

@end
