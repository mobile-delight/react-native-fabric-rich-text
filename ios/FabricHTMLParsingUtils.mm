#import "FabricHTMLParsingUtils.h"

@implementation FabricHTMLParsingUtils

static dispatch_queue_t sSharedParsingQueue;

+ (void)initialize {
    if (self == [FabricHTMLParsingUtils class]) {
        sSharedParsingQueue = dispatch_queue_create(
            "com.connects.htmlrenderer.parsing.shared",
            DISPATCH_QUEUE_SERIAL
        );
    }
}

+ (void)parseHTML:(NSString *)html
       generation:(NSUInteger)generation
   generationRef:(std::atomic<NSUInteger> *)generationRef
       completion:(void (^)(NSAttributedString * _Nullable, NSString * _Nullable))completion {

    dispatch_async(sSharedParsingQueue, ^{
        NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
        NSAttributedString *attributedText = nil;
        NSString *plainText = nil;

        if (data) {
            NSError *error = nil;
            NSDictionary *options = @{
                NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
            };

            attributedText = [[NSAttributedString alloc]
                initWithData:data
                options:options
                documentAttributes:nil
                error:&error];

            if (error) {
                NSLog(@"FabricHTMLParsingUtils: HTML parsing failed: %@", error.localizedDescription);
                attributedText = nil;
            }
        }

        // Compute plain text fallback if parsing failed
        if (!attributedText) {
            NSRegularExpression *regex = [NSRegularExpression
                regularExpressionWithPattern:@"<[^>]+>"
                options:NSRegularExpressionCaseInsensitive
                error:nil];
            plainText = [regex stringByReplacingMatchesInString:html
                                                        options:0
                                                          range:NSMakeRange(0, html.length)
                                                   withTemplate:@""];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            // Check if this result is stale
            if (generationRef && generation != generationRef->load()) {
                return;
            }
            completion(attributedText, plainText);
        });
    });
}

@end
