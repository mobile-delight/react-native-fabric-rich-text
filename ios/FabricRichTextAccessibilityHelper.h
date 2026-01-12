/**
 * FabricRichTextAccessibilityHelper.h
 *
 * Accessibility calculations and link range queries for VoiceOver support.
 * Provides link bounds, visible link count, and accessibility element building.
 *
 * This is the iOS equivalent of Android's TextAccessibilityHelper.
 * Responsibility: Single-purpose class for accessibility calculations.
 */

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import "FabricRichTextTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface FabricRichTextAccessibilityHelper : NSObject

#pragma mark - Link Range Queries

/**
 * Returns all link ranges in the attributed text.
 * A link is identified by the NSLinkAttributeName attribute.
 *
 * @param attributedText The attributed text to search for links.
 * @return Array of NSValue-wrapped NSRange objects, one per link.
 */
- (NSArray<NSValue *> *)allLinkRangesInText:(NSAttributedString *)attributedText;

/**
 * Returns the line number (0-based) for a character at the given index.
 *
 * @param charIndex The character index to find.
 * @param frame The CoreText frame containing the lines.
 * @return The line number, or -1 if not found.
 */
- (NSInteger)lineForCharacterAtIndex:(NSUInteger)charIndex
                             inFrame:(CTFrameRef)frame;

/**
 * Returns the number of visible (non-truncated) links in the view.
 * When numberOfLines is set, only counts links that start on visible lines.
 *
 * @param frame The CoreText frame.
 * @param numberOfLines Maximum number of lines (0 = no limit).
 * @param attributedText The attributed text to search for links.
 * @return The count of visible links.
 */
- (NSInteger)visibleLinkCountWithFrame:(CTFrameRef)frame
                         numberOfLines:(NSInteger)numberOfLines
                        attributedText:(NSAttributedString *)attributedText;

#pragma mark - Link Bounds

/**
 * Returns the bounding rectangle for the link at the given index.
 * The bounds are in the view's coordinate system (UIKit coordinates).
 *
 * @param index The zero-based index of the link (0 = first link).
 * @param frame The CoreText frame.
 * @param attributedText The attributed text containing the links.
 * @param viewBounds The bounds of the containing view.
 * @return The bounding rectangle, or CGRectZero if index is invalid or no links exist.
 *
 * @note For multi-line links, returns the union of all line segments containing the link.
 */
- (CGRect)boundsForLinkAtIndex:(NSUInteger)index
                       inFrame:(CTFrameRef)frame
                attributedText:(NSAttributedString *)attributedText
                    viewBounds:(CGRect)viewBounds;

#pragma mark - Accessibility Element Building

/**
 * Build accessibility elements for text content and links.
 * The first element is the text content (so VoiceOver reads the full text),
 * followed by individual link elements for navigation.
 *
 * @param frame The CoreText frame.
 * @param numberOfLines Maximum number of lines (0 = no limit).
 * @param attributedText The attributed text.
 * @param containerView The containing view (accessibility container).
 * @param visibleText The visible text for the text element's accessibility label.
 * @return Array of UIAccessibilityElement objects (text content + links).
 */
- (NSArray *)buildAccessibilityElementsWithFrame:(CTFrameRef)frame
                                   numberOfLines:(NSInteger)numberOfLines
                                  attributedText:(NSAttributedString *)attributedText
                                   containerView:(UIView *)containerView
                                     visibleText:(NSString *)visibleText;

@end

NS_ASSUME_NONNULL_END
