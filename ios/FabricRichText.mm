#import "FabricRichText.h"
#import "FabricRichCoreTextView.h"
#import "FabricRichFragmentParser.h"
#import "FabricRichTextShadowNode.h"

#import "FabricRichTextComponentDescriptor.h"
#import <react/renderer/components/FabricRichTextSpec/EventEmitters.h>
#import <react/renderer/components/FabricRichTextSpec/Props.h>
#import <react/renderer/components/FabricRichTextSpec/RCTComponentViewHelpers.h>

#if __has_include(<React-RCTAppDelegate/RCTAppDelegate.h>)
#import <React-RCTAppDelegate/RCTAppDelegate.h>
#endif

using namespace facebook::react;

@interface FabricRichText () <RCTFabricRichTextViewProtocol, FabricRichCoreTextViewDelegate>
@end

/**
 * Fabric component view for HTML rendering.
 *
 * Architecture (Fragment-Based Rendering):
 * - C++ ShadowNode parses HTML using shared HTMLParser
 * - C++ AttributedString is passed to view via state
 * - FabricRichFragmentParser converts C++ fragments to NSAttributedString
 * - FabricRichCoreTextView renders using CTFrameDraw
 *
 * This eliminates duplicate HTML parsing between measurement and rendering,
 * ensuring perfect alignment between C++ measurement and iOS rendering.
 */
@implementation FabricRichText {
    FabricRichCoreTextView *_coreTextView;
    CGFloat _previousHeight;
    BOOL _hasInitializedLayout;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<FabricRichTextComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        static const auto defaultProps = std::make_shared<const FabricRichTextProps>();
        _props = defaultProps;

        _coreTextView = [[FabricRichCoreTextView alloc] initWithFrame:self.bounds];
        _coreTextView.delegate = self;
        _coreTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        self.contentView = _coreTextView;

        _previousHeight = 0;
        _hasInitializedLayout = NO;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat newHeight = self.bounds.size.height;
    CGFloat animDuration = _coreTextView.animationDuration;

    // Check if we should animate the height change
    if (_hasInitializedLayout && newHeight != _previousHeight && animDuration > 0) {
        // Animate the content view's frame change
        [UIView animateWithDuration:animDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            self->_coreTextView.frame = self.bounds;
        } completion:nil];
    } else {
        _coreTextView.frame = self.bounds;
    }

    _previousHeight = newHeight;
    _hasInitializedLayout = YES;
}

- (UIView *)renderer
{
    return _coreTextView;
}

#pragma mark - State Handling

- (void)updateState:(const State::Shared &)state oldState:(const State::Shared &)oldState
{
    [super updateState:state oldState:oldState];

    if (!state) {
        return;
    }

    auto htmlState = std::static_pointer_cast<const ConcreteState<FabricRichTextStateData>>(state);
    if (!htmlState) {
        return;
    }

    const auto& stateData = htmlState->getData();
    const auto& attributedString = stateData.attributedString;
    const auto& linkUrls = stateData.linkUrls;

    if (attributedString.isEmpty()) {
        _coreTextView.attributedText = nil;
        return;
    }

    // Convert C++ AttributedString to NSAttributedString using fragment parser
    // Pass link URLs so NSLinkAttributeName can be set for clickable links
    NSAttributedString *nsAttributedString = [FabricRichFragmentParser
        buildAttributedStringFromCppAttributedString:attributedString
                                        withLinkUrls:linkUrls];

    // Extract numberOfLines, animationDuration, and writingDirection from state
    int numberOfLines = stateData.numberOfLines;
    Float animationDuration = stateData.animationDuration;
    bool isRTL = (stateData.writingDirection == WritingDirectionState::RTL);

    // Extract accessibility label from state (built by C++ parser with proper pauses)
    NSString *a11yLabel = nil;
    if (!stateData.accessibilityLabel.empty()) {
        a11yLabel = [[NSString alloc] initWithUTF8String:stateData.accessibilityLabel.c_str()];
    }

    // Update CoreText view properties
    _coreTextView.numberOfLines = numberOfLines;
    _coreTextView.animationDuration = animationDuration;
    _coreTextView.isRTL = isRTL;
    _coreTextView.resolvedAccessibilityLabel = a11yLabel;
    _coreTextView.attributedText = nsAttributedString;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &newProps = *std::static_pointer_cast<const FabricRichTextProps>(props);
    const auto &oldPropsTyped = oldProps ? *std::static_pointer_cast<const FabricRichTextProps>(oldProps) : newProps;

    // Update detection props
    if (!oldProps || newProps.detectLinks != oldPropsTyped.detectLinks) {
        _coreTextView.detectLinks = newProps.detectLinks;
    }
    if (!oldProps || newProps.detectPhoneNumbers != oldPropsTyped.detectPhoneNumbers) {
        _coreTextView.detectPhoneNumbers = newProps.detectPhoneNumbers;
    }
    if (!oldProps || newProps.detectEmails != oldPropsTyped.detectEmails) {
        _coreTextView.detectEmails = newProps.detectEmails;
    }

    // Update textAlign prop for RTL alignment swap
    if (!oldProps || newProps.textAlign != oldPropsTyped.textAlign) {
        NSString *textAlign = newProps.textAlign.empty() ? nil : [NSString stringWithUTF8String:newProps.textAlign.c_str()];
        _coreTextView.textAlign = textAlign;
    }

    // Check if React accessibilityLabel prop overrides the C++ built one
    // The React prop (from ViewProps) takes precedence over the auto-generated label
    if (!oldProps || newProps.accessibilityLabel != oldPropsTyped.accessibilityLabel) {
        if (!newProps.accessibilityLabel.empty()) {
            NSString *reactA11yLabel = [NSString stringWithUTF8String:newProps.accessibilityLabel.c_str()];
            _coreTextView.resolvedAccessibilityLabel = reactA11yLabel;
        }
        // If React prop is empty/not set, keep the C++ parsed one (set in updateState)
    }

    [super updateProps:props oldProps:oldProps];
}

#pragma mark - FabricRichCoreTextViewDelegate

- (void)coreTextView:(id)view didTapLinkWithURL:(NSURL *)url type:(HTMLDetectedContentType)type
{
    if (_eventEmitter) {
        auto eventEmitter = std::static_pointer_cast<FabricRichTextEventEmitter const>(_eventEmitter);
        facebook::react::FabricRichTextEventEmitter::OnLinkPress event;
        event.url = std::string([url.absoluteString UTF8String] ?: "");

        // Convert ObjC enum to C++ string
        switch (type) {
            case HTMLDetectedContentTypeLink:
                event.type = facebook::react::FabricRichTextEventEmitter::OnLinkPressType::Link;
                break;
            case HTMLDetectedContentTypeEmail:
                event.type = facebook::react::FabricRichTextEventEmitter::OnLinkPressType::Email;
                break;
            case HTMLDetectedContentTypePhone:
                event.type = facebook::react::FabricRichTextEventEmitter::OnLinkPressType::Phone;
                break;
        }

        eventEmitter->onLinkPress(event);
    }
}

@end
