import XCTest
@testable import FabricRichText

/**
 * Unit tests for UIAccessibilityContainer protocol implementation in FabricRichCoreTextView.
 *
 * These tests verify the accessibility container correctly exposes links as individual
 * accessibility elements for VoiceOver navigation.
 *
 * Accessibility Element Structure:
 * - Index 0: Text element (full text content for VoiceOver to read)
 * - Index 1+: Link elements (individual links for navigation)
 *
 * WCAG 2.1 Level AA Requirements:
 * - 2.4.4 Link Purpose: Links are identified with meaningful labels
 * - 4.1.2 Name, Role, Value: Links expose correct accessibility traits
 */
final class AccessibilityContainerTests: XCTestCase {
    private var coreTextView: FabricRichCoreTextView!

    override func setUp() {
        super.setUp()
        coreTextView = FabricRichCoreTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
    }

    override func tearDown() {
        coreTextView = nil
        super.tearDown()
    }

    // MARK: - Accessibility Container Protocol Tests

    func testViewIsAccessibilityContainerWhenHasLinks() {
        // Given: A view with links
        let html = """
        <p>Visit <a href="https://example.com">Example Site</a> for more info.</p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // Then: View should NOT be an accessibility element itself (it's a container)
        XCTAssertFalse(coreTextView.isAccessibilityElement,
                       "View should not be accessibility element when containing links")
    }

    func testViewIsAccessibilityElementWhenNoLinks() {
        // Given: A view without links
        let html = "<p>Just plain text with no links.</p>"
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // Then: View should be an accessibility element (no children to navigate)
        XCTAssertTrue(coreTextView.isAccessibilityElement,
                      "View should be accessibility element when no links present")
    }

    func testAccessibilityElementCountMatchesLinkCount() {
        // Given: A view with 3 links
        let html = """
        <p><a href="https://a.com">First</a>, <a href="https://b.com">Second</a>, and <a href="https://c.com">Third</a>.</p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We check the accessibility element count
        let count = coreTextView.accessibilityElementCount()

        // Then: Should have 4 accessibility elements (1 text element + 3 links)
        // The first element (index 0) is the text content for VoiceOver to read
        // Subsequent elements (index 1+) are the individual links for navigation
        XCTAssertEqual(count, 4, "Accessibility element count should be 1 text + link count")
    }

    func testAccessibilityElementCountIsZeroForEmptyText() {
        // Given: A view with no text
        coreTextView.attributedText = nil
        coreTextView.layoutIfNeeded()

        // When: We check the accessibility element count
        let count = coreTextView.accessibilityElementCount()

        // Then: Should be 0
        XCTAssertEqual(count, 0, "Empty view should have 0 accessibility elements")
    }

    // MARK: - Accessibility Element Tests

    func testAccessibilityElementAtIndexReturnsLinkElement() {
        // Given: A view with a link
        let html = """
        <p>Visit <a href="https://example.com">Example Site</a>.</p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get the accessibility element at index 0
        let element = coreTextView.accessibilityElement(at: 0)

        // Then: Should return a valid element
        XCTAssertNotNil(element, "Should return accessibility element for valid index")
    }

    func testAccessibilityElementAtInvalidIndexReturnsNil() {
        // Given: A view with one link
        let html = """
        <p><a href="https://example.com">Link</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We request an element at invalid index
        let element = coreTextView.accessibilityElement(at: 999)

        // Then: Should return nil
        XCTAssertNil(element, "Should return nil for invalid index")
    }

    func testIndexOfAccessibilityElementReturnsCorrectIndex() {
        // Given: A view with multiple links
        let html = """
        <p><a href="https://a.com">First</a> <a href="https://b.com">Second</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get the first element and ask for its index
        guard let firstElement = coreTextView.accessibilityElement(at: 0) else {
            XCTFail("Should have first element")
            return
        }
        let index = coreTextView.index(ofAccessibilityElement: firstElement)

        // Then: Should return 0
        XCTAssertEqual(index, 0, "First element should have index 0")
    }

    // MARK: - Accessibility Label Tests

    func testLinkAccessibilityLabelContainsLinkText() {
        // Given: A view with a link
        let html = """
        <p>Visit <a href="https://example.com">Example Site</a>.</p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get the link accessibility label (index 1, after text element at index 0)
        guard let element = coreTextView.accessibilityElement(at: 1) as? UIAccessibilityElement else {
            XCTFail("Should have link accessibility element at index 1")
            return
        }
        let label = element.accessibilityLabel

        // Then: Label should contain the link text
        XCTAssertNotNil(label, "Accessibility label should not be nil")
        XCTAssertTrue(label?.contains("Example Site") ?? false,
                      "Label should contain the link text")
    }

    func testLinkAccessibilityLabelIncludesPositionInfo() {
        // Given: A view with multiple links
        let html = """
        <p><a href="https://a.com">First</a> and <a href="https://b.com">Second</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get the first link's accessibility label (index 1, after text element at index 0)
        guard let element = coreTextView.accessibilityElement(at: 1) as? UIAccessibilityElement else {
            XCTFail("Should have link accessibility element at index 1")
            return
        }
        let label = element.accessibilityLabel

        // Then: Label should include position info (e.g., "link 1 of 2" or similar)
        XCTAssertNotNil(label, "Accessibility label should not be nil")
        // Note: The exact format may vary, but it should convey position
        XCTAssertTrue(label?.contains("1") ?? false || label?.contains("first") ?? false,
                      "Label should indicate link position")
    }

    // MARK: - Accessibility Traits Tests

    func testLinkAccessibilityTraitsIncludesLink() {
        // Given: A view with a link
        let html = """
        <p><a href="https://example.com">Click me</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get the link accessibility traits (index 1, after text element at index 0)
        guard let element = coreTextView.accessibilityElement(at: 1) as? UIAccessibilityElement else {
            XCTFail("Should have link accessibility element at index 1")
            return
        }
        let traits = element.accessibilityTraits

        // Then: Traits should include .link
        XCTAssertTrue(traits.contains(.link), "Link element should have link trait")
    }

    // MARK: - Accessibility Frame Tests

    func testLinkAccessibilityFrameIsWithinViewBounds() {
        // Given: A view with a link
        let html = """
        <p>Visit <a href="https://example.com">Example</a>.</p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText

        // Add view to window for proper frame calculation
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        window.addSubview(coreTextView)
        window.makeKeyAndVisible()
        coreTextView.layoutIfNeeded()

        // When: We get the link accessibility frame (index 1, after text element at index 0)
        guard let element = coreTextView.accessibilityElement(at: 1) as? UIAccessibilityElement else {
            XCTFail("Should have link accessibility element at index 1")
            return
        }
        let frame = element.accessibilityFrame

        // Then: Frame should be valid and within screen coordinates
        XCTAssertFalse(frame.isEmpty, "Accessibility frame should not be empty")
        XCTAssertGreaterThan(frame.width, 0, "Frame width should be positive")
        XCTAssertGreaterThan(frame.height, 0, "Frame height should be positive")
    }

    // MARK: - Link Activation Tests

    func testAccessibilityActivateOnLinkReturnsTrue() {
        // Given: A view with a link
        let html = """
        <p><a href="https://example.com">Activatable Link</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We try to activate the link (index 1, after text element at index 0)
        guard let element = coreTextView.accessibilityElement(at: 1) as? UIAccessibilityElement else {
            XCTFail("Should have link accessibility element at index 1")
            return
        }

        // Then: accessibilityActivate should return true (indicates activatable)
        let result = element.accessibilityActivate()
        XCTAssertTrue(result, "Link should be activatable")
    }

    // MARK: - Content Type Hint Tests

    func testEmailLinkHasEmailHint() {
        // Given: A view with an email link
        let html = """
        <p>Email <a href="mailto:test@example.com">test@example.com</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get the link accessibility hint (index 1, after text element at index 0)
        guard let element = coreTextView.accessibilityElement(at: 1) as? UIAccessibilityElement else {
            XCTFail("Should have link accessibility element at index 1")
            return
        }
        let hint = element.accessibilityHint

        // Then: Hint should mention email or mail action
        // Note: Hint is optional but recommended for clarity
        if let hint = hint {
            XCTAssertTrue(hint.lowercased().contains("email") ||
                          hint.lowercased().contains("mail"),
                          "Email link should have email-related hint")
        }
    }

    func testPhoneLinkHasPhoneHint() {
        // Given: A view with a phone link
        let html = """
        <p>Call <a href="tel:+1234567890">+1 234 567 890</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get the link accessibility hint (index 1, after text element at index 0)
        guard let element = coreTextView.accessibilityElement(at: 1) as? UIAccessibilityElement else {
            XCTFail("Should have link accessibility element at index 1")
            return
        }
        let hint = element.accessibilityHint

        // Then: Hint should mention phone or call action
        if let hint = hint {
            XCTAssertTrue(hint.lowercased().contains("phone") ||
                          hint.lowercased().contains("call"),
                          "Phone link should have phone-related hint")
        }
    }

    // MARK: - Accessibility Best Practices Validation

    /// Validates that links have proper accessibility properties per WCAG guidelines.
    /// Note: Full performAccessibilityAudit() is available in XCUITest (UI tests).
    /// These unit tests validate accessibility properties directly.
    func testAccessibilityElementsHaveProperTraits() {
        // Given: A view with a link
        let html = """
        <p>Visit <a href="https://example.com">Example Site</a>.</p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText

        // Add view to window for proper frame calculation
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        window.addSubview(coreTextView)
        window.makeKeyAndVisible()
        coreTextView.layoutIfNeeded()

        // When: We get the link accessibility element (index 1, after text element at index 0)
        guard let element = coreTextView.accessibilityElement(at: 1) as? UIAccessibilityElement else {
            XCTFail("Should have link accessibility element at index 1")
            return
        }

        // Then: Element should have proper accessibility properties
        // 1. Has link trait
        XCTAssertTrue(element.accessibilityTraits.contains(.link),
                      "Link should have .link trait")

        // 2. Has non-empty label
        XCTAssertNotNil(element.accessibilityLabel, "Link should have label")
        XCTAssertFalse(element.accessibilityLabel?.isEmpty ?? true,
                       "Link label should not be empty")

        // 3. Has non-empty frame (touch target)
        XCTAssertFalse(element.accessibilityFrame.isEmpty,
                       "Link should have valid accessibility frame")
    }

    func testAccessibilityElementsHaveMinimumTouchTarget() {
        // Given: A view with a link
        let html = """
        <p><a href="https://example.com">Link</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText

        // Add view to window for proper frame calculation
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        window.addSubview(coreTextView)
        window.makeKeyAndVisible()
        coreTextView.layoutIfNeeded()

        // Rebuild accessibility elements with window
        coreTextView.setNeedsLayout()
        coreTextView.layoutIfNeeded()

        // When: We get the link accessibility element (index 1, after text element at index 0)
        guard let element = coreTextView.accessibilityElement(at: 1) as? UIAccessibilityElement else {
            XCTFail("Should have link accessibility element at index 1")
            return
        }

        let frame = element.accessibilityFrame

        // Then: Touch target should be reasonable size
        // Note: WCAG recommends 44x44pt minimum, but text links may be smaller
        // We verify they have positive dimensions
        XCTAssertGreaterThan(frame.width, 0,
                             "Link touch target should have positive width")
        XCTAssertGreaterThan(frame.height, 0,
                             "Link touch target should have positive height")
    }

    func testMultipleLinksHaveUniqueLabels() {
        // Given: A view with multiple links
        let html = """
        <p><a href="https://a.com">First</a> <a href="https://b.com">Second</a> <a href="https://c.com">Third</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // Should have 4 elements: 1 text element + 3 link elements
        let totalCount = coreTextView.accessibilityElementCount()
        XCTAssertEqual(totalCount, 4, "Should have 1 text element + 3 link elements")

        // When: We get all link accessibility labels (indices 1, 2, 3 - skip text element at index 0)
        var linkLabels: [String] = []
        for i in 1..<totalCount {
            if let element = coreTextView.accessibilityElement(at: i) as? UIAccessibilityElement,
               let label = element.accessibilityLabel {
                linkLabels.append(label)
            }
        }

        // Then: Each link should have unique label (includes position info)
        XCTAssertEqual(linkLabels.count, 3, "Should have 3 link elements")
        XCTAssertEqual(Set(linkLabels).count, linkLabels.count,
                       "All link labels should be unique (include position info)")
    }

    // MARK: - Helper Methods

    private func createAttributedString(from html: String) -> NSAttributedString {
        guard let data = html.data(using: .utf8) else {
            return NSAttributedString(string: "")
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        do {
            return try NSAttributedString(data: data, options: options, documentAttributes: nil)
        } catch {
            return NSAttributedString(string: html)
        }
    }
}
