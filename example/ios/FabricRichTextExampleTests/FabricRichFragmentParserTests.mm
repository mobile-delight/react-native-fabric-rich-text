/**
 * FabricRichFragmentParserTests.mm
 *
 * Tests for FabricRichFragmentParser which converts C++ AttributedString to NSAttributedString.
 * This tests the iOS rendering path that receives parsed data from the C++ layer.
 */

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "../../../ios/FabricRichFragmentParser.h"
#import "../../../cpp/FabricMarkupParser.h"

using namespace facebook::react;

@interface FabricRichFragmentParserTests : XCTestCase
@end

@implementation FabricRichFragmentParserTests

#pragma mark - Helper Methods

- (AttributedString)parseHTML:(NSString *)html {
    std::string htmlStr = [html UTF8String] ?: "";
    return FabricMarkupParser::parseMarkupToAttributedString(
        htmlStr, 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFF000000, "");
}

#pragma mark - Basic Conversion Tests

- (void)testEmptyAttributedString {
    AttributedString empty;
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:empty];
    XCTAssertNotNil(result);
    XCTAssertEqual(result.length, 0UL);
}

- (void)testPlainText {
    AttributedString cpp = [self parseHTML:@"Hello world"];
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    XCTAssertEqualObjects(result.string, @"Hello world");
}

- (void)testBoldText {
    AttributedString cpp = [self parseHTML:@"<strong>Bold</strong>"];
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    XCTAssertTrue([result.string containsString:@"Bold"]);

    // Find the bold text and check its font
    [result enumerateAttribute:NSFontAttributeName
                       inRange:NSMakeRange(0, result.length)
                       options:0
                    usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont *font = value;
        if (font) {
            NSString *text = [result.string substringWithRange:range];
            if ([text containsString:@"Bold"]) {
                XCTAssertTrue(font.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold,
                              @"Bold text should have bold font trait");
                *stop = YES;
            }
        }
    }];
}

- (void)testItalicText {
    AttributedString cpp = [self parseHTML:@"<em>Italic</em>"];
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    XCTAssertTrue([result.string containsString:@"Italic"]);

    [result enumerateAttribute:NSFontAttributeName
                       inRange:NSMakeRange(0, result.length)
                       options:0
                    usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont *font = value;
        if (font) {
            NSString *text = [result.string substringWithRange:range];
            if ([text containsString:@"Italic"]) {
                XCTAssertTrue(font.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic,
                              @"Italic text should have italic font trait");
                *stop = YES;
            }
        }
    }];
}

- (void)testBoldItalicText {
    AttributedString cpp = [self parseHTML:@"<strong><em>Both</em></strong>"];
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    [result enumerateAttribute:NSFontAttributeName
                       inRange:NSMakeRange(0, result.length)
                       options:0
                    usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont *font = value;
        if (font) {
            NSString *text = [result.string substringWithRange:range];
            if ([text containsString:@"Both"]) {
                UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
                XCTAssertTrue(traits & UIFontDescriptorTraitBold, @"Should have bold trait");
                XCTAssertTrue(traits & UIFontDescriptorTraitItalic, @"Should have italic trait");
                *stop = YES;
            }
        }
    }];
}

- (void)testFontSize {
    AttributedString cpp = [self parseHTML:@"<h1>Heading</h1>"];
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    __block BOOL foundLargeFont = NO;
    [result enumerateAttribute:NSFontAttributeName
                       inRange:NSMakeRange(0, result.length)
                       options:0
                    usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont *font = value;
        if (font && font.pointSize > 20) { // H1 should be 32pt (16 * 2.0)
            foundLargeFont = YES;
            *stop = YES;
        }
    }];
    XCTAssertTrue(foundLargeFont, @"H1 should have larger font size");
}

#pragma mark - Text Decoration Tests

- (void)testUnderlineText {
    AttributedString cpp = [self parseHTML:@"<u>Underlined</u>"];
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    __block BOOL foundUnderline = NO;
    [result enumerateAttribute:NSUnderlineStyleAttributeName
                       inRange:NSMakeRange(0, result.length)
                       options:0
                    usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            NSInteger style = [value integerValue];
            if (style == NSUnderlineStyleSingle) {
                foundUnderline = YES;
                *stop = YES;
            }
        }
    }];
    XCTAssertTrue(foundUnderline, @"Should have underline attribute");
}

- (void)testStrikethroughText {
    AttributedString cpp = [self parseHTML:@"<s>Strikethrough</s>"];
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    __block BOOL foundStrikethrough = NO;
    [result enumerateAttribute:NSStrikethroughStyleAttributeName
                       inRange:NSMakeRange(0, result.length)
                       options:0
                    usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            NSInteger style = [value integerValue];
            if (style == NSUnderlineStyleSingle) {
                foundStrikethrough = YES;
                *stop = YES;
            }
        }
    }];
    XCTAssertTrue(foundStrikethrough, @"Should have strikethrough attribute");
}

#pragma mark - Color Tests

- (void)testForegroundColor {
    // Parse with red foreground color (0xFFFF0000 = ARGB red)
    std::string html = "Red text";
    AttributedString cpp = FabricMarkupParser::parseMarkupToAttributedString(
        html, 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 0.0f, 0xFFFF0000, "");

    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    UIColor *color = [result attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
    XCTAssertNotNil(color, @"Should have foreground color");

    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    XCTAssertEqualWithAccuracy(red, 1.0, 0.01, @"Red component should be 1.0");
    XCTAssertEqualWithAccuracy(green, 0.0, 0.01, @"Green component should be 0.0");
    XCTAssertEqualWithAccuracy(blue, 0.0, 0.01, @"Blue component should be 0.0");
}

#pragma mark - Letter Spacing Tests

- (void)testLetterSpacing {
    std::string html = "Spaced";
    AttributedString cpp = FabricMarkupParser::parseMarkupToAttributedString(
        html, 16.0f, 1.0f, true, 0.0f, 0.0f, "", "", "", 2.0f, 0xFF000000, "");

    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    NSNumber *kern = [result attribute:NSKernAttributeName atIndex:0 effectiveRange:nil];
    XCTAssertNotNil(kern, @"Should have kern attribute");
    XCTAssertEqualWithAccuracy(kern.floatValue, 2.0, 0.01, @"Kern should be 2.0");
}

#pragma mark - List Tests

- (void)testUnorderedList {
    AttributedString cpp = [self parseHTML:@"<ul><li>Item 1</li><li>Item 2</li></ul>"];
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    XCTAssertTrue([result.string containsString:@"Item 1"], @"Should contain first item");
    XCTAssertTrue([result.string containsString:@"Item 2"], @"Should contain second item");
}

- (void)testOrderedList {
    AttributedString cpp = [self parseHTML:@"<ol><li>First</li><li>Second</li></ol>"];
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    XCTAssertTrue([result.string containsString:@"First"], @"Should contain first item");
    XCTAssertTrue([result.string containsString:@"Second"], @"Should contain second item");
}

#pragma mark - Complex HTML Tests

- (void)testMixedFormatting {
    AttributedString cpp = [self parseHTML:@"<p>Normal <strong>bold</strong> and <em>italic</em> text</p>"];
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    XCTAssertTrue([result.string containsString:@"Normal"], @"Should contain normal text");
    XCTAssertTrue([result.string containsString:@"bold"], @"Should contain bold text");
    XCTAssertTrue([result.string containsString:@"italic"], @"Should contain italic text");
}

- (void)testMultipleParagraphs {
    AttributedString cpp = [self parseHTML:@"<p>First paragraph</p><p>Second paragraph</p>"];
    NSAttributedString *result = [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];

    XCTAssertTrue([result.string containsString:@"First"], @"Should contain first paragraph");
    XCTAssertTrue([result.string containsString:@"Second"], @"Should contain second paragraph");
}

#pragma mark - Performance Tests

- (void)testPerformance_Conversion {
    // Pre-parse HTML
    AttributedString cpp = [self parseHTML:@"<div><p>Test <strong>bold</strong> and <em>italic</em></p></div>"];

    [self measureBlock:^{
        for (int i = 0; i < 1000; i++) {
            [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];
        }
    }];
}

- (void)testPerformance_FullPipeline {
    NSString *html = @"<div><p>Paragraph with <strong>bold</strong>, <em>italic</em>, and <u>underline</u>.</p></div>";

    [self measureBlock:^{
        for (int i = 0; i < 100; i++) {
            AttributedString cpp = [self parseHTML:html];
            [FabricRichFragmentParser buildAttributedStringFromCppAttributedString:cpp];
        }
    }];
}

@end
