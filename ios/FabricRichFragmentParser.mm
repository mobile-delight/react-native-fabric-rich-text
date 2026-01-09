/**
 * FabricRichFragmentParser.mm
 *
 * Implementation of C++ AttributedString to NSAttributedString conversion.
 */

#import "FabricRichFragmentParser.h"
#import <CoreText/CoreText.h>

#if __has_include(<FabricHtmlText/FabricHtmlText-Swift.h>)
#import <FabricHtmlText/FabricHtmlText-Swift.h>
#elif __has_include("NativeTestHarness-Swift.h")
#import "NativeTestHarness-Swift.h"
#else
#import "FabricRichText-Swift.h"
#endif

using namespace facebook::react;

@implementation FabricRichFragmentParser

+ (NSAttributedString *)buildAttributedStringFromCppAttributedString:
    (const AttributedString &)attributedString {
    // Call the version with empty link URLs for backwards compatibility
    return [self buildAttributedStringFromCppAttributedString:attributedString
                                                 withLinkUrls:std::vector<std::string>()];
}

+ (NSAttributedString *)buildAttributedStringFromCppAttributedString:
    (const AttributedString &)attributedString
    withLinkUrls:(const std::vector<std::string> &)linkUrls {

    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];

    const auto& fragments = attributedString.getFragments();
    size_t fragmentIndex = 0;

    for (const auto& fragment : fragments) {
        if (fragment.string.empty()) {
            fragmentIndex++;
            continue;
        }

        NSString *text = [[NSString alloc] initWithUTF8String:fragment.string.c_str()];
        if (!text) {
            fragmentIndex++;
            continue;
        }

        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        const auto& textAttrs = fragment.textAttributes;

        // Font size
        CGFloat fontSize = textAttrs.fontSize > 0 ? textAttrs.fontSize : FabricGeneratedConstants.defaultFontSize;

        // Font weight and style
        BOOL isBold = textAttrs.fontWeight == FontWeight::Bold ||
                      textAttrs.fontWeight == FontWeight::Black ||
                      textAttrs.fontWeight == FontWeight::Heavy ||
                      textAttrs.fontWeight == FontWeight::Semibold;

        BOOL isItalic = textAttrs.fontStyle == FontStyle::Italic;

        // Build font with weight and style
        UIFont *font;
        if (isBold && isItalic) {
            UIFontDescriptor *descriptor = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody]
                fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
            font = [UIFont fontWithDescriptor:descriptor size:fontSize];
            if (!font) {
                // Fallback if combined traits not available
                font = [UIFont boldSystemFontOfSize:fontSize];
            }
        } else if (isBold) {
            font = [UIFont boldSystemFontOfSize:fontSize];
        } else if (isItalic) {
            font = [UIFont italicSystemFontOfSize:fontSize];
        } else {
            font = [UIFont systemFontOfSize:fontSize];
        }
        attributes[NSFontAttributeName] = font;

        // Foreground color
        if (textAttrs.foregroundColor) {
            auto colorValue = *textAttrs.foregroundColor;
            // Extract RGBA components (SharedColor is a 32-bit ARGB value)
            CGFloat alpha = ((colorValue >> 24) & 0xFF) / 255.0;
            CGFloat red = ((colorValue >> 16) & 0xFF) / 255.0;
            CGFloat green = ((colorValue >> 8) & 0xFF) / 255.0;
            CGFloat blue = (colorValue & 0xFF) / 255.0;
            UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
            attributes[NSForegroundColorAttributeName] = color;
        }

        // Background color
        if (textAttrs.backgroundColor) {
            auto colorValue = *textAttrs.backgroundColor;
            CGFloat alpha = ((colorValue >> 24) & 0xFF) / 255.0;
            CGFloat red = ((colorValue >> 16) & 0xFF) / 255.0;
            CGFloat green = ((colorValue >> 8) & 0xFF) / 255.0;
            CGFloat blue = (colorValue & 0xFF) / 255.0;
            UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
            attributes[NSBackgroundColorAttributeName] = color;
        }

        // Text decoration (underline, strikethrough)
        if (textAttrs.textDecorationLineType.has_value()) {
            switch (*textAttrs.textDecorationLineType) {
                case TextDecorationLineType::Underline:
                    attributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
                    break;
                case TextDecorationLineType::Strikethrough:
                    attributes[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
                    break;
                case TextDecorationLineType::UnderlineStrikethrough:
                    attributes[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
                    attributes[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
                    break;
                default:
                    break;
            }
        }

        // Letter spacing
        if (!std::isnan(textAttrs.letterSpacing) && textAttrs.letterSpacing != 0) {
            attributes[NSKernAttributeName] = @(textAttrs.letterSpacing);
        }

        // Line height via paragraph style
        if (!std::isnan(textAttrs.lineHeight) && textAttrs.lineHeight > 0) {
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.minimumLineHeight = textAttrs.lineHeight;
            paragraphStyle.maximumLineHeight = textAttrs.lineHeight;
            attributes[NSParagraphStyleAttributeName] = paragraphStyle;
        }

        // Link URL - set NSLinkAttributeName for clickable links
        // Validate URL scheme to prevent XSS (e.g., javascript: URLs)
        if (fragmentIndex < linkUrls.size()) {
            const std::string& linkUrl = linkUrls[fragmentIndex];
            if (!linkUrl.empty()) {
                NSString *urlString = [[NSString alloc] initWithUTF8String:linkUrl.c_str()];
                if (urlString) {
                    NSURL *url = [NSURL URLWithString:urlString];
                    if (url) {
                        // Only allow safe URL schemes: http, https, mailto, tel
                        static NSSet *allowedSchemes = nil;
                        static dispatch_once_t onceToken;
                        dispatch_once(&onceToken, ^{
                            allowedSchemes = [NSSet setWithObjects:@"http", @"https", @"mailto", @"tel", nil];
                        });

                        NSString *scheme = url.scheme.lowercaseString;
                        if ([allowedSchemes containsObject:scheme]) {
                            attributes[NSLinkAttributeName] = url;
                        }
                        // Skip potentially dangerous URLs (javascript:, data:, vbscript:, etc.)
                    }
                }
            }
        }

        NSAttributedString *fragmentString = [[NSAttributedString alloc]
            initWithString:text
                attributes:attributes];
        [result appendAttributedString:fragmentString];
        fragmentIndex++;
    }

    return result;
}

@end
