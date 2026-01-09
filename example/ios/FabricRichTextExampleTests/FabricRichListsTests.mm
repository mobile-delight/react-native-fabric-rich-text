/**
 * FabricHTMLListsTests.mm
 *
 * Tests for list parsing functionality in FabricHTMLParser.
 * Mirrors Android FabricHTMLListsTest.kt for cross-platform parity.
 */

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "../../../cpp/FabricHTMLParser.h"
#import "../../../ios/FabricHTMLFragmentParser.h"

using namespace facebook::react;

@interface FabricHTMLListsTests : XCTestCase
@end

@implementation FabricHTMLListsTests

#pragma mark - Helper Methods

- (AttributedString)parseHTML:(NSString *)html {
    std::string htmlStr = [html UTF8String] ?: "";
    return FabricHTMLParser::parseHtmlToAttributedString(
        htmlStr, 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");
}

- (NSString *)fullTextFromFragments:(const AttributedString&)cpp {
    std::string fullText;
    const auto& fragments = cpp.getFragments();
    for (const auto& fragment : fragments) {
        fullText += fragment.string;
    }
    return [NSString stringWithUTF8String:fullText.c_str()];
}

#pragma mark - Unordered List Tests (FR-006)

- (void)testUnorderedListInsertsBulletMarkers {
    AttributedString cpp = [self parseHTML:@"<ul><li>First</li><li>Second</li></ul>"];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"\u2022"] || [text containsString:@"•"],
                  @"Should contain bullet marker");
    XCTAssertTrue([text containsString:@"First"], @"Should contain First");
    XCTAssertTrue([text containsString:@"Second"], @"Should contain Second");
}

- (void)testUnorderedListUsesUnicodeBullet {
    AttributedString cpp = [self parseHTML:@"<ul><li>Item</li></ul>"];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"\u2022"], @"Should use Unicode bullet U+2022");
}

- (void)testUnorderedListMultipleItemsHaveBullets {
    AttributedString cpp = [self parseHTML:@"<ul><li>A</li><li>B</li><li>C</li></ul>"];

    NSString *text = [self fullTextFromFragments:cpp];
    NSUInteger bulletCount = [[text componentsSeparatedByString:@"\u2022"] count] - 1;
    XCTAssertEqual(bulletCount, 3UL, @"Should have 3 bullet markers");
}

#pragma mark - Ordered List Tests (FR-007)

- (void)testOrderedListInsertsSequentialNumbers {
    AttributedString cpp = [self parseHTML:@"<ol><li>First</li><li>Second</li><li>Third</li></ol>"];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"1."], @"Should contain '1.'");
    XCTAssertTrue([text containsString:@"2."], @"Should contain '2.'");
    XCTAssertTrue([text containsString:@"3."], @"Should contain '3.'");
}

- (void)testOrderedListNumberingRestartsForSeparateLists {
    AttributedString cpp = [self parseHTML:@"<ol><li>A</li><li>B</li></ol><ol><li>X</li><li>Y</li></ol>"];

    NSString *text = [self fullTextFromFragments:cpp];
    NSUInteger oneCount = [[text componentsSeparatedByString:@"1."] count] - 1;
    XCTAssertEqual(oneCount, 2UL, @"Should have two '1.' markers for separate lists");
}

#pragma mark - Orphaned List Item Tests (FR-008)

- (void)testOrphanedListItemRendersWithBullet {
    // Orphaned <li> tags (not inside <ul> or <ol>) still render with a bullet
    // for graceful degradation - they still look like list items
    AttributedString cpp = [self parseHTML:@"<li>Orphan</li>"];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"Orphan"], @"Should contain orphan text");
    XCTAssertTrue([text containsString:@"\u2022"], @"Should have bullet marker for graceful degradation");
    XCTAssertFalse([text containsString:@"1."], @"Should NOT have number marker (not in <ol>)");
}

- (void)testOrphanedListItemNoMarkerNoIndentation {
    AttributedString cpp = [self parseHTML:@"Before<li>Middle</li>After"];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"Before"], @"Should contain Before");
    XCTAssertTrue([text containsString:@"Middle"], @"Should contain Middle");
    XCTAssertTrue([text containsString:@"After"], @"Should contain After");
}

#pragma mark - Nested List Tests (FR-010)

- (void)testNestedListIncreasesIndentation {
    NSString *html = @"<ul><li>Level 1</li><li><ul><li>Level 2</li></ul></li></ul>";
    AttributedString cpp = [self parseHTML:html];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"Level 1"], @"Should contain Level 1");
    XCTAssertTrue([text containsString:@"Level 2"], @"Should contain Level 2");
}

- (void)testNestedListCapsAtLevel3 {
    NSString *html = @"<ul><li>L1<ul><li>L2<ul><li>L3<ul><li>L4</li></ul></li></ul></li></ul></li></ul>";
    AttributedString cpp = [self parseHTML:html];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"L1"], @"Should contain L1");
    XCTAssertTrue([text containsString:@"L4"], @"Should contain L4 (styled as L3)");
}

#pragma mark - Mixed Content in Lists

- (void)testListWithBoldContent {
    AttributedString cpp = [self parseHTML:@"<ul><li><strong>Bold item</strong></li></ul>"];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"Bold item"], @"Should contain bold item text");
    XCTAssertTrue([text containsString:@"\u2022"], @"Should have bullet marker");

    const auto& fragments = cpp.getFragments();
    bool foundBold = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Bold item") {
            XCTAssertEqual(fragment.textAttributes.fontWeight, FontWeight::Bold);
            foundBold = true;
        }
    }
    XCTAssertTrue(foundBold, @"Should have bold style");
}

- (void)testListWithLinkContent {
    AttributedString cpp = [self parseHTML:@"<ul><li><a href=\"https://example.com\">Link</a></li></ul>"];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"Link"], @"Should contain link text");
    XCTAssertTrue([text containsString:@"\u2022"], @"Should have bullet marker");

    const auto& fragments = cpp.getFragments();
    bool foundLink = false;
    for (const auto& fragment : fragments) {
        if (fragment.string == "Link") {
            XCTAssertEqual(fragment.textAttributes.textDecorationLineType, TextDecorationLineType::Underline);
            foundLink = true;
        }
    }
    XCTAssertTrue(foundLink, @"Should have link span");
}

#pragma mark - Empty List Tests

- (void)testEmptyListRendersNothing {
    AttributedString cpp = [self parseHTML:@"<ul></ul>"];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertEqual(text.length, 0UL, @"Empty list should render as empty");
}

- (void)testEmptyListItemRendersMarkerOnly {
    AttributedString cpp = [self parseHTML:@"<ul><li></li></ul>"];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"\u2022"], @"Should have bullet marker for empty item");
}

#pragma mark - Accessibility Tests

- (void)testListAccessibilityContainsAllContent {
    AttributedString cpp = [self parseHTML:@"<ul><li>Item 1</li><li>Item 2</li></ul>"];

    NSString *text = [self fullTextFromFragments:cpp];
    XCTAssertTrue([text containsString:@"Item 1"], @"Should contain Item 1 for accessibility");
    XCTAssertTrue([text containsString:@"Item 2"], @"Should contain Item 2 for accessibility");
}

@end
