import UIKit

/**
 * Shared test utilities for FabricHtmlText tests.
 */
enum TestHelpers {

    /**
     * Creates an NSAttributedString from HTML content for testing.
     *
     * Note: This currently uses Apple's NSAttributedString HTML parser.
     * For tests that need to validate production behavior, consider using
     * FabricHTMLFragmentParser directly.
     *
     * TODO: Consider adding a variant that uses FabricHTMLFragmentParser
     * for production-accurate testing.
     *
     * - Parameter html: The HTML string to parse
     * - Returns: An NSAttributedString representation of the HTML
     */
    static func createAttributedString(from html: String) -> NSAttributedString {
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
