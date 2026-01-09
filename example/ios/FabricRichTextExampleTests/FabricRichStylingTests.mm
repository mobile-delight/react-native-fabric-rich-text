/**
 * FabricHTMLStylingTests.mm
 *
 * Tests for tagStyles functionality in FabricHTMLParser.
 * Mirrors Android FabricHTMLStylingTest.kt for cross-platform parity.
 */

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "../../../cpp/FabricHTMLParser.h"
#import "../../../ios/FabricHTMLFragmentParser.h"

using namespace facebook::react;

@interface FabricHTMLStylingTests : XCTestCase
@end

@implementation FabricHTMLStylingTests

#pragma mark - Helper Methods

- (AttributedString)parseHTML:(NSString *)html withTagStyles:(NSString *)tagStyles {
    std::string htmlStr = [html UTF8String] ?: "";
    std::string tagStylesStr = [tagStyles UTF8String] ?: "";
    return FabricHTMLParser::parseHtmlToAttributedString(
        htmlStr, 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, tagStylesStr);
}

- (AttributedString)parseHTML:(NSString *)html {
    return [self parseHTML:html withTagStyles:@""];
}

- (NSString *)fullTextFromFragments:(const AttributedString&)cpp {
    std::string fullText;
    const auto& fragments = cpp.getFragments();
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    return [NSString stringWithUTF8String:fullText.c_str()];
}

#pragma mark - TagStyles Application Tests

- (void)testTagStylesAppliedToMatchingElements {
    // Given: tagStyles that override strong color to red
    NSString *tagStyles = @"{\"strong\": {\"color\": \"#FF0000\"}}";

    // When: HTML with <strong> tag is rendered
    AttributedString cpp = [self parseHTML:@"<p>Normal <strong>Bold</strong> text</p>" withTagStyles:tagStyles];

    // Then: The strong portion should have the style applied
    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"Bold"], @"Should contain Bold text");

    // Find the bold fragment and verify it has the custom color
    const auto& fragments = cpp.getFragments();
    bool foundBold = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Bold") {
            // Color is stored in foregroundColor
            foundBold = true;
        }
    }
    XCTAssertTrue(foundBold, @"Should find Bold fragment");
}

- (void)testTagStylesMergeWithDefaults {
    // Given: tagStyles that only override color (not font weight)
    NSString *tagStyles = @"{\"strong\": {\"color\": \"#0000FF\"}}";

    // When: HTML with <strong> tag is rendered
    AttributedString cpp = [self parseHTML:@"<strong>Bold Blue</strong>" withTagStyles:tagStyles];

    // Then: Text should be both bold (default) AND have custom color (override)
    const auto& fragments = cpp.getFragments();
    XCTAssertGreaterThan(fragments.size(), 0UL);

    bool foundBoldWithColor = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Bold Blue") {
            XCTAssertEqual(fragment.textAttributes.fontWeight, FontWeight::Bold,
                          @"Font should still be bold (default style preserved)");
            foundBoldWithColor = true;
        }
    }
    XCTAssertTrue(foundBoldWithColor, @"Should find styled fragment");
}

- (void)testTagStylesOverrideDefaultsWhenSpecified {
    // Given: tagStyles with fontSize override
    NSString *tagStyles = @"{\"p\": {\"fontSize\": 24.0}}";

    // When: HTML with <p> tag is rendered
    AttributedString cpp = [self parseHTML:@"<p>Large paragraph</p>" withTagStyles:tagStyles];

    // Then: Text should render without error
    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"Large paragraph"], @"Should contain text");
}

- (void)testMultipleTagStylesAppliedToDifferentTags {
    // Given: tagStyles for multiple tags
    NSString *tagStyles = @"{\"strong\": {\"color\": \"#FF0000\"}, \"em\": {\"color\": \"#00FF00\"}}";

    // When: HTML with both tags is rendered
    AttributedString cpp = [self parseHTML:@"<strong>Red</strong> and <em>Green</em>" withTagStyles:tagStyles];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"Red"], @"Should contain Red");
    XCTAssertTrue([text containsString:@"Green"], @"Should contain Green");

    // Verify both fragments have their respective styles
    const auto& fragments = cpp.getFragments();
    bool foundRed = false, foundGreen = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Red") {
            XCTAssertEqual(fragment.textAttributes.fontWeight, FontWeight::Bold);
            foundRed = true;
        }
        if (fragment.string == "Green") {
            XCTAssertEqual(fragment.textAttributes.fontStyle, FontStyle::Italic);
            foundGreen = true;
        }
    }
    XCTAssertTrue(foundRed && foundGreen, @"Should find both styled fragments");
}

#pragma mark - Invalid Styles Handling Tests

- (void)testInvalidStylePropertyIsIgnoredWithoutCrashing {
    // Given: tagStyles with an invalid property name
    NSString *tagStyles = @"{\"p\": {\"color\": \"#FF0000\", \"invalidProperty\": \"someValue\"}}";

    // When: HTML is rendered
    AttributedString cpp = [self parseHTML:@"<p>Text with invalid style</p>" withTagStyles:tagStyles];

    // Then: Should not crash and valid properties should apply
    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue(text.length > 0, @"Should render without crashing");
}

- (void)testInvalidColorValueIsIgnoredWithoutCrashing {
    // Given: tagStyles with an invalid color value
    NSString *tagStyles = @"{\"p\": {\"color\": \"not-a-color\"}}";

    // When: HTML is rendered
    AttributedString cpp = [self parseHTML:@"<p>Text with invalid color</p>" withTagStyles:tagStyles];

    // Then: Should not crash and text should render
    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue(text.length > 0, @"Should render without crashing");
}

- (void)testEmptyTagStylesHandledGracefully {
    // Given: Empty tagStyles
    NSString *tagStyles = @"{}";

    // When: HTML is rendered
    AttributedString cpp = [self parseHTML:@"<p>Normal text</p>" withTagStyles:tagStyles];

    // Then: Should render normally with default styles
    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"Normal text"], @"Should contain text");
}

- (void)testNullTagStylesHandledGracefully {
    // Given: No tagStyles (empty string)
    AttributedString cpp = [self parseHTML:@"<strong>Bold text</strong>" withTagStyles:@""];

    // Then: Should render normally with default styles
    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"Bold text"], @"Should contain text");

    const auto& fragments = cpp.getFragments();
    bool foundBold = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Bold text") {
            XCTAssertEqual(fragment.textAttributes.fontWeight, FontWeight::Bold,
                          @"Default bold style should be applied");
            foundBold = true;
        }
    }
    XCTAssertTrue(foundBold, @"Should find bold fragment");
}

- (void)testTagStylesForNonExistentTagIsIgnored {
    // Given: tagStyles for a tag that doesn't appear in HTML
    NSString *tagStyles = @"{\"h1\": {\"color\": \"#FF0000\"}}";

    // When: HTML without h1 is rendered
    AttributedString cpp = [self parseHTML:@"<p>No heading here</p>" withTagStyles:tagStyles];

    // Then: Should render normally without any issues
    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"No heading here"], @"Should contain text");
}

#pragma mark - Supported Style Properties Tests

- (void)testFontWeightBoldStyleApplied {
    // Given: tagStyles with fontWeight bold on an inline tag
    // Note: tagStyles only apply to inline formatting tags (span, em, etc.), not block tags (p, div)
    NSString *tagStyles = @"{\"span\": {\"fontWeight\": \"bold\"}}";

    // When: HTML is rendered
    AttributedString cpp = [self parseHTML:@"<span>Bold text</span>" withTagStyles:tagStyles];

    // Then: Font should be bold
    const auto& fragments = cpp.getFragments();
    bool foundBold = false;
    for (const auto& fragment : fragments) {
        if (fragment.string.find("Bold text") != std::string::npos) {
            XCTAssertEqual(fragment.textAttributes.fontWeight, FontWeight::Bold,
                          @"Font should be bold");
            foundBold = true;
        }
    }
    XCTAssertTrue(foundBold, @"Should find bold text");
}

- (void)testFontStyleItalicApplied {
    // Given: tagStyles with fontStyle italic on an inline tag
    // Note: tagStyles only apply to inline formatting tags (span, em, etc.), not block tags (p, div)
    NSString *tagStyles = @"{\"span\": {\"fontStyle\": \"italic\"}}";

    // When: HTML is rendered
    AttributedString cpp = [self parseHTML:@"<span>Italic text</span>" withTagStyles:tagStyles];

    // Then: Font should be italic
    const auto& fragments = cpp.getFragments();
    bool foundItalic = false;
    for (const auto& fragment : fragments) {
        if (fragment.string.find("Italic text") != std::string::npos) {
            XCTAssertEqual(fragment.textAttributes.fontStyle, FontStyle::Italic,
                          @"Font should be italic");
            foundItalic = true;
        }
    }
    XCTAssertTrue(foundItalic, @"Should find italic text");
}

- (void)testTextDecorationLineUnderlineApplied {
    // Given: tagStyles with textDecorationLine underline on an inline tag
    // Note: tagStyles only apply to inline formatting tags (span, em, etc.), not block tags (p, div)
    NSString *tagStyles = @"{\"span\": {\"textDecorationLine\": \"underline\"}}";

    // When: HTML is rendered
    AttributedString cpp = [self parseHTML:@"<span>Underlined text</span>" withTagStyles:tagStyles];

    // Then: Underline style should be applied
    const auto& fragments = cpp.getFragments();
    bool foundUnderline = false;
    for (const auto& fragment : fragments) {
        if (fragment.string.find("Underlined text") != std::string::npos) {
            XCTAssertEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline,
                          @"Should have underline decoration");
            foundUnderline = true;
        }
    }
    XCTAssertTrue(foundUnderline, @"Should find underlined text");
}

@end
