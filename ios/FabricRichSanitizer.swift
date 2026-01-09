import Foundation
import SwiftSoup

/// HTML Sanitizer using SwiftSoup.
///
/// Provides XSS protection by sanitizing HTML content before
/// it reaches the native iOS HTML parser (NSAttributedString).
///
/// Security approach:
/// - Allowlist-based: Only allows known-safe tags and attributes
/// - URL protocol validation: Only http, https, mailto, tel allowed
/// - All event handlers and script content stripped
@objc public final class FabricRichSanitizer: NSObject {
  /**
   * Allowed HTML tags - uses FabricGeneratedConstants (from src/core/constants.ts).
   * Run `yarn codegen:constants` to regenerate.
   */
  private static var allowedTags: [String] { FabricGeneratedConstants.allowedTags }

  /**
   * Allowed URL protocols - uses FabricGeneratedConstants (from src/core/constants.ts).
   */
  private static var allowedProtocols: [String] { FabricGeneratedConstants.allowedProtocols }

  /**
   * Custom allowlist configured with our security policy.
   * Note: SwiftSoup uses "Whitelist" class name; we use "allowlist" terminology.
   */
  private let allowlist: Whitelist

  /**
   * Output settings configured to disable pretty-printing.
   * SwiftSoup's default pretty-print adds newlines/indentation between tags,
   * which becomes unwanted text content when parsed.
   */
  private let outputSettings: OutputSettings

  public override init() {
    outputSettings = OutputSettings()
    _ = outputSettings.prettyPrint(pretty: false)
    // Start with no tags allowed, then add our safe list
    allowlist = Whitelist.none()

    // Add allowed tags
    do {
      for tag in FabricRichSanitizer.allowedTags {
        try allowlist.addTags(tag)
      }

      // Allow href on anchor tags with protocol restrictions
      try allowlist.addAttributes("a", "href")
      for proto in FabricRichSanitizer.allowedProtocols {
        try allowlist.addProtocols("a", "href", proto)
      }

      // Allow class attribute for styling (id removed per YAGNI - not used in rendering)
      for tag in FabricRichSanitizer.allowedTags {
        try allowlist.addAttributes(tag, "class")
      }
    } catch {
      // Initialization errors should not occur with valid config
      // Log error in debug builds
      #if DEBUG
        print("FabricRichSanitizer: Failed to configure allowlist: \(error)")
      #endif
    }

    super.init()
  }

  /**
   * Sanitize HTML content to remove XSS vectors.
   *
   * - Parameter html: The raw HTML string to sanitize
   * - Returns: Sanitized HTML string safe for rendering, or empty string on error
   */
  @objc public func sanitize(_ html: String) -> String {
    guard !html.isEmpty else {
      return ""
    }

    do {
      // Normalize inter-tag whitespace from source formatting (JSX indentation, etc.)
      // BEFORE sanitizing so SwiftSoup processes clean input.
      // Browsers ignore whitespace between block elements; we do the same.
      let normalized = html.replacingOccurrences(
        of: ">\\s+<",
        with: "><",
        options: .regularExpression
      )

      // Sanitize with pretty-printing disabled to prevent SwiftSoup from adding whitespace
      var clean = try SwiftSoup.clean(normalized, "", allowlist, outputSettings) ?? ""

      // Trim leading/trailing whitespace
      clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

      return clean
    } catch {
      // Log in all builds - silent failures cause debugging nightmares in production
      NSLog("FabricRichSanitizer: Failed to sanitize HTML: %@", String(describing: error))
      return ""
    }
  }
}
