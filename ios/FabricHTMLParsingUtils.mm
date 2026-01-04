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
       completion:(void (^)(NSUInteger, NSAttributedString * _Nullable, NSString * _Nullable))completion {

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

        // If parsing failed, don't attempt unsafe regex fallback
        // Regex cannot safely parse HTML (fails on comments, CDATA, quoted angle brackets, etc.)
        // Return nil for both to indicate error - caller should handle gracefully
        if (!attributedText) {
            plainText = nil;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            // Return generation so caller can check for staleness
            completion(generation, attributedText, plainText);
        });
    });
}

@end
