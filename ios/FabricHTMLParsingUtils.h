#import <UIKit/UIKit.h>
#import <atomic>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility for async HTML parsing with generation tracking.
 *
 * Provides a shared serial queue for HTML parsing operations to avoid
 * creating per-instance queues. Uses generation tracking to handle
 * stale results when props change rapidly.
 *
 * Shared between HTMLLabelView and HTMLTextView.
 */
@interface FabricHTMLParsingUtils : NSObject

/**
 * Parse sanitized HTML on a background queue and return results on main queue.
 *
 * @param html The sanitized HTML string to parse
 * @param generation The generation counter at parse time
 * @param generationRef Pointer to the atomic generation counter for staleness check
 * @param completion Callback with attributed text (or nil) and plain text fallback
 */
+ (void)parseHTML:(NSString *)html
       generation:(NSUInteger)generation
   generationRef:(std::atomic<NSUInteger> *)generationRef
       completion:(void (^)(NSAttributedString * _Nullable attributedText,
                            NSString * _Nullable plainText))completion;

@end

NS_ASSUME_NONNULL_END
