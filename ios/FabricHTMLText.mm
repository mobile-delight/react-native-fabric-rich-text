#import "FabricHTMLText.h"
#import "FabricHTMLCoreTextView.h"
#import "FabricHTMLFragmentParser.h"
#import "FabricHTMLTextShadowNode.h"

#import "FabricHTMLTextComponentDescriptor.h"
#import <react/renderer/components/FabricHTMLTextSpec/EventEmitters.h>
#import <react/renderer/components/FabricHTMLTextSpec/Props.h>
#import <react/renderer/components/FabricHTMLTextSpec/RCTComponentViewHelpers.h>

#if __has_include(<React-RCTAppDelegate/RCTAppDelegate.h>)
#import <React-RCTAppDelegate/RCTAppDelegate.h>
#endif

using namespace facebook::react;

@interface FabricHTMLText () <RCTFabricHTMLTextViewProtocol, FabricHTMLCoreTextViewDelegate>
@end

/**
 * Fabric component view for HTML rendering.
 *
 * Architecture (Fragment-Based Rendering):
 * - C++ ShadowNode parses HTML using shared HTMLParser
 * - C++ AttributedString is passed to view via state
 * - FabricHTMLFragmentParser converts C++ fragments to NSAttributedString
 * - FabricHTMLCoreTextView renders using CTFrameDraw
 *
 * This eliminates duplicate HTML parsing between measurement and rendering,
 * ensuring perfect alignment between C++ measurement and iOS rendering.
 */
@implementation FabricHTMLText {
    FabricHTMLCoreTextView *_coreTextView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<FabricHTMLTextComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        static const auto defaultProps = std::make_shared<const FabricHTMLTextProps>();
        _props = defaultProps;

        _coreTextView = [[FabricHTMLCoreTextView alloc] initWithFrame:self.bounds];
        _coreTextView.delegate = self;
        _coreTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        self.contentView = _coreTextView;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _coreTextView.frame = self.bounds;
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

    auto htmlState = std::static_pointer_cast<const ConcreteState<FabricHTMLTextStateData>>(state);
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
    NSAttributedString *nsAttributedString = [FabricHTMLFragmentParser
        buildAttributedStringFromCppAttributedString:attributedString
                                        withLinkUrls:linkUrls];

    _coreTextView.attributedText = nsAttributedString;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &newProps = *std::static_pointer_cast<const FabricHTMLTextProps>(props);
    const auto &oldPropsTyped = oldProps ? *std::static_pointer_cast<const FabricHTMLTextProps>(oldProps) : newProps;

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

    [super updateProps:props oldProps:oldProps];
}

#pragma mark - FabricHTMLCoreTextViewDelegate

- (void)coreTextView:(id)view didTapLinkWithURL:(NSURL *)url type:(HTMLDetectedContentType)type
{
    if (_eventEmitter) {
        auto eventEmitter = std::static_pointer_cast<FabricHTMLTextEventEmitter const>(_eventEmitter);
        facebook::react::FabricHTMLTextEventEmitter::OnLinkPress event;
        event.url = std::string([url.absoluteString UTF8String] ?: "");

        // Convert ObjC enum to C++ string
        switch (type) {
            case HTMLDetectedContentTypeLink:
                event.type = facebook::react::FabricHTMLTextEventEmitter::OnLinkPressType::Link;
                break;
            case HTMLDetectedContentTypeEmail:
                event.type = facebook::react::FabricHTMLTextEventEmitter::OnLinkPressType::Email;
                break;
            case HTMLDetectedContentTypePhone:
                event.type = facebook::react::FabricHTMLTextEventEmitter::OnLinkPressType::Phone;
                break;
        }

        eventEmitter->onLinkPress(event);
    }
}

@end
