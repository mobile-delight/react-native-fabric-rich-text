import XCTest
@testable import FabricRichText

/**
 * Unit tests for link bounds calculation in FabricRichCoreTextView.
 *
 * These tests verify the `boundsForLinkAtIndex:` method correctly calculates
 * bounding rectangles for links in the text using CoreText frame analysis.
 *
 * TDD Requirement: These tests should FAIL initially until T006 is implemented.
 */
final class LinkBoundsTests: XCTestCase {
    private var coreTextView: FabricRichCoreTextView!

    override func setUp() {
        super.setUp()
        coreTextView = FabricRichCoreTextView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
    }

    override func tearDown() {
        coreTextView = nil
        super.tearDown()
    }

    // MARK: - Basic Link Bounds Tests

    func testBoundsForLinkReturnsValidRect() {
        // Given: A view with a single link
        let html = """
        <p>Visit <a href="https://example.com">Example Site</a> for more info.</p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get the bounds for link at index 0
        let bounds = coreTextView.boundsForLink(at: 0)

        // Then: The bounds should be a valid non-zero rect
        XCTAssertFalse(bounds.isNull, "Bounds should not be null for valid link")
        XCTAssertFalse(bounds.isEmpty, "Bounds should not be empty for valid link")
        XCTAssertGreaterThan(bounds.width, 0, "Bounds width should be positive")
        XCTAssertGreaterThan(bounds.height, 0, "Bounds height should be positive")
    }

    func testBoundsForInvalidIndexReturnsZeroRect() {
        // Given: A view with one link
        let html = """
        <p>Visit <a href="https://example.com">Example</a>.</p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We request bounds for an invalid index
        let bounds = coreTextView.boundsForLink(at: 999)

        // Then: Should return zero rect
        XCTAssertTrue(bounds.isEmpty || bounds.equalTo(CGRect.zero),
                      "Bounds for invalid index should be zero or empty")
    }

    func testBoundsForEmptyTextReturnsZeroRect() {
        // Given: A view with no text
        coreTextView.attributedText = nil
        coreTextView.layoutIfNeeded()

        // When: We request any bounds
        let bounds = coreTextView.boundsForLink(at: 0)

        // Then: Should return zero rect
        XCTAssertTrue(bounds.isEmpty || bounds.equalTo(CGRect.zero),
                      "Bounds for empty text should be zero or empty")
    }

    // MARK: - Multiple Links Tests

    func testBoundsForMultipleLinks() {
        // Given: A view with multiple links
        let html = """
        <p>Visit <a href="https://a.com">First</a> and <a href="https://b.com">Second</a> links.</p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get bounds for each link
        let firstBounds = coreTextView.boundsForLink(at: 0)
        let secondBounds = coreTextView.boundsForLink(at: 1)

        // Then: Both should have valid bounds
        XCTAssertFalse(firstBounds.isEmpty, "First link should have valid bounds")
        XCTAssertFalse(secondBounds.isEmpty, "Second link should have valid bounds")

        // And: Second link should be to the right of first (assuming LTR text)
        XCTAssertGreaterThan(secondBounds.minX, firstBounds.minX,
                             "Second link should be positioned after first")
    }

    func testBoundsForLinksDoNotOverlap() {
        // Given: A view with adjacent links
        let html = """
        <p><a href="https://a.com">Link One</a> <a href="https://b.com">Link Two</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get bounds for both links
        let firstBounds = coreTextView.boundsForLink(at: 0)
        let secondBounds = coreTextView.boundsForLink(at: 1)

        // Then: They should not overlap significantly
        let intersection = firstBounds.intersection(secondBounds)
        XCTAssertTrue(intersection.isNull || intersection.width < 1,
                      "Link bounds should not overlap")
    }

    // MARK: - Multi-Line Link Tests

    func testBoundsForMultiLineLinkReturnsUnion() {
        // Given: A view with a link that spans multiple lines (narrow width)
        coreTextView.frame = CGRect(x: 0, y: 0, width: 100, height: 200)
        let html = """
        <p><a href="https://example.com">This is a very long link text that will wrap to multiple lines</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get the bounds
        let bounds = coreTextView.boundsForLink(at: 0)

        // Then: The bounds should span multiple line heights
        XCTAssertGreaterThan(bounds.height, 30,
                             "Multi-line link should have height spanning multiple lines")
    }

    // MARK: - Bounds Coordinate Tests

    func testBoundsAreInViewCoordinates() {
        // Given: A view with a link
        let html = """
        <p>Visit <a href="https://example.com">Example</a>.</p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get the bounds
        let bounds = coreTextView.boundsForLink(at: 0)

        // Then: Bounds should be within the view's bounds
        XCTAssertGreaterThanOrEqual(bounds.minX, 0, "Bounds minX should be >= 0")
        XCTAssertGreaterThanOrEqual(bounds.minY, 0, "Bounds minY should be >= 0")
        XCTAssertLessThanOrEqual(bounds.maxX, coreTextView.bounds.width,
                                  "Bounds maxX should be <= view width")
        XCTAssertLessThanOrEqual(bounds.maxY, coreTextView.bounds.height,
                                  "Bounds maxY should be <= view height")
    }

    // MARK: - Visible Link Count Tests

    func testVisibleLinkCountWithNoTruncation() {
        // Given: A view with 3 links and no truncation
        let html = """
        <p><a href="https://a.com">A</a> <a href="https://b.com">B</a> <a href="https://c.com">C</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.numberOfLines = 0 // No limit
        coreTextView.layoutIfNeeded()

        // When: We get the visible link count
        let count = coreTextView.visibleLinkCount

        // Then: All 3 links should be visible
        XCTAssertEqual(count, 3, "All 3 links should be visible when no truncation")
    }

    func testVisibleLinkCountWithTruncation() {
        // Given: A narrow view that will truncate content
        coreTextView.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        let html = """
        <p><a href="https://a.com">First Link</a> <a href="https://b.com">Second Link</a> <a href="https://c.com">Third Link</a></p>
        """
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.numberOfLines = 1 // Force single line
        coreTextView.layoutIfNeeded()

        // When: We get the visible link count
        let count = coreTextView.visibleLinkCount

        // Then: Only links on visible lines should be counted
        XCTAssertLessThan(count, 3, "Truncated view should have fewer visible links")
    }

    func testVisibleLinkCountWithNoLinks() {
        // Given: A view with no links
        let html = "<p>Just plain text with no links.</p>"
        let attributedText = createAttributedString(from: html)
        coreTextView.attributedText = attributedText
        coreTextView.layoutIfNeeded()

        // When: We get the visible link count
        let count = coreTextView.visibleLinkCount

        // Then: Should be zero
        XCTAssertEqual(count, 0, "View with no links should have count of 0")
    }

    // MARK: - Helper Methods

    private func createAttributedString(from html: String) -> NSAttributedString {
        // Simple HTML to attributed string conversion for testing
        // This mimics what FabricRichFragmentParser produces
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
