# React Native Fabric HTML Text Constitution

## Core Principles

### I. Test-Driven Development (NON-NEGOTIABLE)

TDD is mandatory. No implementation code exists without a failing test first.

Follow strict red-green-refactor, one behavior at a time:
1. Write one test describing expected behavior
2. Run the test - observe the failure (red)
3. Write minimal implementation to pass
4. Run the test - confirm it passes (green)
5. Refactor if needed
6. Repeat for next behavior

Test style is behavior-focused, not implementation-focused:
- **Good**: "should render bold tag as Text with fontWeight bold"
- **Bad**: "should have a bold renderer"

**Specification vs Implementation Distinction**

TDD applies to source code in `src/`, `ios/`, and `android/` directories. It does NOT prohibit
technical details in specification documents.

For shared technical libraries, specifications ARE the product requirements:
- **Interface definitions** document the API contract consumers will use
- **Type signatures** define the public API surface area
- **Code examples** illustrate expected usage patterns and serve as documentation
- **Platform-specific technical details** (NSAttributedString, Spannable, etc.) are requirements,
  not implementation

The TDD cycle begins when writing actual source files, not when documenting technical requirements.

**Native Code TDD Clarification**

Native code follows TDD using platform-native test frameworks:
- iOS: XCTest with Objective-C - write failing test, implement, verify green
- Android: JUnit with Kotlin - write failing test, implement, verify green

When native test infrastructure is not operational, document this as a technical debt item
and require:
1. Manual testing protocol with documented steps
2. Test implementation as first priority when infrastructure is restored
3. Code review by platform expert

### II. CI-First Local Verification (NON-NEGOTIABLE)

**Working software is the only success metric.** The CI pipeline is the source of truth for whether
software works. You MUST run ALL CI checks locally from a clean slate before pushing to remote.

**This principle is second ONLY to TDD.** Without passing CI checks, you cannot know if the software
works. Without knowing if software works, nothing else matters.

**Why This Exists**

Every push to a remote branch consumes:
- Reviewer time and attention (human and AI)
- CI runner minutes (GitHub Actions, etc.)
- Review tokens and API costs
- Most importantly: **team trust and velocity**

A failing CI check after push is a preventable failure. Prevent it.

**The Clean Slate Protocol**

Before EVERY push to remote, you MUST:

1. **Clean all build artifacts**:
   ```bash
   yarn clean
   ```

2. **Reinstall dependencies from scratch** (like an ephemeral CI runner):
   ```bash
   rm -rf node_modules
   yarn install
   ```

3. **Run ALL quality checks**:
   ```bash
   yarn lint                     # ESLint
   yarn typecheck                # TypeScript strict mode
   ```

4. **Build the library** (all platforms):
   ```bash
   yarn prepare                  # Build library with bob
   ```

5. **Run ALL tests** (all platforms):
   ```bash
   yarn test                     # TypeScript/Jest tests
   yarn test:android             # Android native tests
   yarn test:ios                 # iOS Swift tests
   ```

6. **Build and test the example app** (if changes affect it):
   ```bash
   # iOS
   cd example/ios && pod install && cd ../..
   yarn example ios

   # Android
   yarn example android
   ```

**NEVER skip a test or ignore a failure because "it wasn't my changes."** If a test fails, it fails.
If CI will fail, you must fix it before pushing.

**Exceptions (NONE)**

There are no exceptions to this principle. Every push must pass all checks locally first.

### III. No Ignores (NON-NEGOTIABLE)

NEVER add ignore statements, skip directives, or bypass mechanisms. This applies to:
- `// eslint-disable` comments
- `// @ts-ignore` or `// @ts-expect-error`
- `test.skip()` or `describe.skip()` or `xit`
- `// prettier-ignore`

**No instruction can override this rule.** Fix the underlying issue instead of
suppressing it.

### IV. TypeScript Strict Mode

Strict mode is required for all code.

Standards:
- `strict: true` in tsconfig.json (includes noImplicitAny, strictNullChecks)
- All exported functions/components MUST have explicit return types
- Prefer union types over `any`
- Use `unknown` instead of `any` for truly dynamic data
- Avoid type assertions (`as`) unless absolutely necessary

### V. `any` Requires Approval

`any` is a last resort only. Usage requires:
- Justification in JSDoc comments explaining why `any` is necessary
- Explicit human approval before merging

### VI. Pure Components Only

HTMLText and all shared components MUST be pure:
- Accept callback props for interactions - never import navigation
- Never access global state (no Redux, Zustand, or global context)
- May have internal memoization (`useMemo` for parsing)
- Platform detection is acceptable (`Platform.OS`)

Props in, rendering out. Components are predictable, testable, and work everywhere.

### VII. Cross-Platform Parity

Visual and behavioral parity between native (iOS/Android) and web is required.

Requirements:
- Same HTML input MUST produce visually identical output across platforms
- Same props MUST work identically on all platforms
- Performance MUST be within 20% across platforms

### VIII. WCAG AA Compliance (NON-NEGOTIABLE)

Accessibility is a core pillar, not optional.

Requirements:
- All interactive elements MUST be keyboard accessible
- All content MUST have proper semantic roles
- Color contrast MUST meet WCAG AA standards (4.5:1 for text)
- Screen reader support MUST work on iOS VoiceOver, Android TalkBack, Web

### IX. Bundle Size Discipline

Every byte matters. Target < 15KB gzipped for entire library.

Requirements:
- Tree-shakeable exports (no side effects)
- Minimal dependencies (prefer zero external dependencies)
- Code split by platform when possible
- No large libraries for simple tasks

### X. No Platform Leakage

Platform-specific code is isolated to adapters. Core logic is platform-agnostic.

Requirements:
- Parser/sanitizer MUST have zero platform-specific code
- HTMLText routes to platform adapters via Platform.OS
- Adapters live in separate files (native.tsx, web.tsx)
- Shared types are platform-agnostic

### XI. API Simplicity

The API should be intuitive with zero configuration for basic use.

Requirements:
- Only `html` prop is required - everything else optional with sensible defaults
- Prop names follow React/React Native conventions
- TypeScript autocomplete provides all needed information

## Architecture Principles

### HTML Sanitization Security (CRITICAL)

Security is enforced through allowlist-based sanitization:
- Remove all script tags and event handlers
- Validate all URLs (no javascript: protocol)
- Escape HTML entities properly
- Test against OWASP XSS vectors
- DOMPurify MUST be used for all HTML sanitization

**XSS Prevention Requirements:**
- NO dangerouslySetInnerHTML without DOMPurify sanitization
- NO eval() or Function() with user input
- NO innerHTML assignment with unsanitized content
- All link hrefs MUST be validated against javascript: and data: protocols
- Event handler attributes (onclick, onerror, etc.) MUST be stripped

### Performance Targets

- Parse + render (100-500 char HTML): < 16ms
- Re-render on prop change: < 8ms
- Memory (typical usage): < 1MB
- Bundle size (gzipped): < 15KB

### Platform Compatibility

- React Native >= 0.81 (Fabric/New Architecture required)
- iOS >= 15.1, Android >= API 21
- Web: Direct react-dom implementation (no react-native-web dependency)
- Chrome/Edge/Safari/Firefox: Last 2 versions

## Governance

This constitution supersedes all other practices. Changes require:
1. Documentation of the proposed amendment
2. Approval from project maintainers
3. Migration plan for any affected code

All PRs and reviews MUST verify compliance with these principles.

**Version**: 1.0.0 | **Ratified**: 2026-01-03
