/**
 * FabricRichLinkDetectionManager.m
 *
 * Implementation of link/phone/email detection using NSDataDetector.
 */

#import "FabricRichLinkDetectionManager.h"
#import <UIKit/UIKit.h>

/// Debug logging for link detection - set to 0 for production
#define LINK_DETECTION_DEBUG 0

#if LINK_DETECTION_DEBUG
#define DETECTION_LOG(fmt, ...) NSLog(@"[LinkDetection] " fmt, ##__VA_ARGS__)
#else
#define DETECTION_LOG(fmt, ...) do { } while(0)
#endif

@implementation FabricRichLinkDetectionManager

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _detectLinks = NO;
        _detectPhoneNumbers = NO;
        _detectEmails = NO;
    }
    return self;
}

#pragma mark - Public Methods

- (BOOL)isDetectionEnabled {
    return _detectLinks || _detectPhoneNumbers || _detectEmails;
}

- (NSAttributedString *)processAttributedText:(NSAttributedString *)attributedText {
    if (!attributedText || attributedText.length == 0) {
        return attributedText;
    }

    // If no detection is enabled, return the original
    if (![self isDetectionEnabled]) {
        return attributedText;
    }

    NSMutableAttributedString *mutableText = [attributedText mutableCopy];
    NSString *plainText = attributedText.string;

    // Build the data detector types based on enabled detection
    NSTextCheckingTypes checkingTypes = 0;
    if (_detectLinks) {
        checkingTypes |= NSTextCheckingTypeLink;
    }
    if (_detectPhoneNumbers) {
        checkingTypes |= NSTextCheckingTypePhoneNumber;
    }
    // Note: NSDataDetector doesn't have a separate email type; emails are detected as links
    // We'll identify emails by checking if the URL has a mailto: scheme

    if (checkingTypes == 0 && !_detectEmails) {
        return attributedText;
    }

    // If only email detection is enabled, we need to detect links to catch mailto: URLs
    if (_detectEmails && checkingTypes == 0) {
        checkingTypes = NSTextCheckingTypeLink;
    } else if (_detectEmails) {
        checkingTypes |= NSTextCheckingTypeLink;
    }

    NSError *error = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:checkingTypes error:&error];
    if (error) {
        return attributedText;
    }

    NSArray<NSTextCheckingResult *> *matches = [detector matchesInString:plainText
                                                                 options:0
                                                                   range:NSMakeRange(0, plainText.length)];

    for (NSTextCheckingResult *match in matches) {
        NSRange range = match.range;

        // Skip if this range already has a link attribute (explicit <a> tag takes precedence)
        id existingLink = [attributedText attribute:NSLinkAttributeName atIndex:range.location effectiveRange:NULL];
        if (existingLink) {
            continue;
        }

        NSURL *url = nil;
        HTMLDetectedContentType contentType = HTMLDetectedContentTypeLink;

        if (match.resultType == NSTextCheckingTypePhoneNumber) {
            if (!_detectPhoneNumbers) {
                continue;
            }
            NSString *phoneNumber = match.phoneNumber;
            DETECTION_LOG(@"PHONE DETECTION: matched phone='%@' at range=(%lu, %lu)",
                     phoneNumber, (unsigned long)range.location, (unsigned long)range.length);
            if (phoneNumber) {
                // Create tel: URL - remove all non-digit characters, keep + for international
                NSMutableCharacterSet *allowedChars = [NSMutableCharacterSet decimalDigitCharacterSet];
                [allowedChars addCharactersInString:@"+"];
                NSString *cleanedPhone = [[phoneNumber componentsSeparatedByCharactersInSet:
                                           [allowedChars invertedSet]] componentsJoinedByString:@""];

                if (cleanedPhone.length > 0) {
                    // URL-encode the phone number to handle any edge cases
                    NSString *encodedPhone = [cleanedPhone stringByAddingPercentEncodingWithAllowedCharacters:
                                              [NSCharacterSet URLPathAllowedCharacterSet]];
                    NSString *telString = [NSString stringWithFormat:@"tel:%@", encodedPhone ?: cleanedPhone];
                    url = [NSURL URLWithString:telString];
                    contentType = HTMLDetectedContentTypePhone;
                    DETECTION_LOG(@"PHONE DETECTION: created tel URL='%@' from cleaned='%@'", url, cleanedPhone);

                    if (!url) {
                        DETECTION_LOG(@"PHONE DETECTION: WARNING - failed to create URL from telString='%@'", telString);
                    }
                } else {
                    DETECTION_LOG(@"PHONE DETECTION: WARNING - cleaned phone number is empty for input='%@'", phoneNumber);
                }
            } else {
                DETECTION_LOG(@"PHONE DETECTION: WARNING - phone number is nil!");
            }
        } else if (match.resultType == NSTextCheckingTypeLink) {
            url = match.URL;
            if (url) {
                NSString *scheme = url.scheme.lowercaseString;

                // Validate URL scheme to prevent XSS (e.g., javascript: URLs)
                // Only allow safe schemes: http, https, mailto, tel
                static NSSet *allowedSchemes = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    allowedSchemes = [NSSet setWithObjects:@"http", @"https", @"mailto", @"tel", nil];
                });

                if (![allowedSchemes containsObject:scheme]) {
                    continue;  // Skip potentially dangerous URLs
                }

                // Check if it's an email (mailto:) or a regular link
                if ([scheme isEqualToString:@"mailto"]) {
                    if (!_detectEmails) {
                        DETECTION_LOG(@"EMAIL DETECTION: found mailto: but detectEmails=NO, skipping");
                        continue;
                    }
                    contentType = HTMLDetectedContentTypeEmail;
                    DETECTION_LOG(@"EMAIL DETECTION: detected email='%@'", url.absoluteString);
                } else {
                    if (!_detectLinks) {
                        continue;
                    }
                    contentType = HTMLDetectedContentTypeLink;
                    DETECTION_LOG(@"LINK DETECTION: detected link='%@'", url.absoluteString);
                }
            }
        }

        if (url) {
            [mutableText addAttribute:NSLinkAttributeName value:url range:range];
            [mutableText addAttribute:FabricRichDetectedContentTypeKey value:@(contentType) range:range];

            // Add link styling (blue color, underline)
            [mutableText addAttribute:NSForegroundColorAttributeName value:[UIColor systemBlueColor] range:range];
            [mutableText addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:range];

            NSString *matchedText = [plainText substringWithRange:range];
            DETECTION_LOG(@"DETECTION: Added %@ link '%@' -> '%@'",
                     contentType == HTMLDetectedContentTypePhone ? @"PHONE" :
                     contentType == HTMLDetectedContentTypeEmail ? @"EMAIL" : @"WEB",
                     matchedText, url.absoluteString);
        } else {
            DETECTION_LOG(@"DETECTION WARNING: URL is nil for match at range=(%lu, %lu)",
                     (unsigned long)range.location, (unsigned long)range.length);
        }
    }

    DETECTION_LOG(@"DETECTION COMPLETE: Total matches processed=%lu", (unsigned long)matches.count);
    return mutableText;
}

@end
