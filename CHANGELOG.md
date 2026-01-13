# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-beta.1] - 2026-01-12

First public beta release.

### Features

- **Native Fabric component** - High-performance HTML text renderer built on React Native's New Architecture
- **Cross-platform support** - iOS, Android, and Web with consistent behavior
- **HTML rendering** - Support for common HTML tags (p, div, h1-h6, strong, em, u, s, a, ul, ol, li, br, span, bdi, bdo)
- **Link handling** - `onLinkPress` callback with URL, email, and phone number support
- **Auto-detection** - Automatic detection of URLs, emails, and phone numbers via `detectLinks`, `detectEmails`, `detectPhoneNumbers` props
- **RTL support** - Full Right-to-Left text support with `writingDirection` prop and `dir` attribute
- **BDI/BDO elements** - Bidirectional isolation and override for mixed-direction content
- **NativeWind integration** - Pre-configured `/nativewind` export for Tailwind CSS styling
- **Line truncation** - `numberOfLines` prop with animated height transitions
- **Custom tag styles** - Per-tag styling via `tagStyles` prop
- **XSS protection** - Built-in HTML sanitization with configurable allowlists
- **Accessibility** - Full VoiceOver/TalkBack support with link navigation and focus events
- **Font scaling** - `allowFontScaling` and `maxFontSizeMultiplier` props for accessibility
- **Measurement callback** - `onRichTextMeasurement` for detecting text truncation

### Security

- Defense-in-depth URL validation and attribute escaping
- Sanitization using sanitize-html (native) and DOMPurify (web)
- Exported `ALLOWED_TAGS` and `ALLOWED_ATTR` for transparency

### Requirements

- React Native >= 0.81 (New Architecture / Fabric required)
- iOS >= 15.1
- Android API >= 21

## [1.0.0-alpha.0] - 2025-12-15

Initial alpha release for internal testing.
