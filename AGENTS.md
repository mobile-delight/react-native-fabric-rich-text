# React Native Fabric HTML Text — AI Agent Guidelines

This document enforces the project constitution for AI agents. Read `.specify/memory/constitution.md` for the full governance rules.

## Project Overview

A Fabric-first HTML text renderer for React Native. This library parses HTML strings and renders them as native Text components with proper styling, using React Native's new architecture (Fabric).

**Security context**: This library renders user-provided HTML content. XSS prevention and proper sanitization are critical security requirements.

**Key characteristics**:
- Cross-platform (iOS, Android, Web)
- Fabric-native (uses TurboModules and Fabric components)
- DOMPurify-based sanitization
- Allowlist-only HTML tags and attributes

## Non-Negotiable Operating Principles

### 1. Epistemic Humility — Trust the Tools, Not Yourself

**The problem is ALWAYS in YOUR code.** When the tooling, compiler, linter, or test runner says something is wrong, assume IT is right and YOU are wrong.

- You cannot "run" code mentally. You can only guess. Your guesses are often wrong.
- If a test fails → the test is telling you something. Listen.
- If the compiler rejects your code → the compiler is correct. Fix YOUR code.
- If the linter warns you → the linter knows something you forgot. Heed the warning.

**Never dismiss tool output:**
- "That's a false positive" → It almost never is. Investigate properly.
- "That test is flaky" → The test is exposing a real race condition. Fix it.
- "The linter is being pedantic" → The linter is preventing future bugs. Comply.

**Proven confidence vs. false confidence:**
- **False**: "This should work" / "I'm confident this is correct" / "The logic looks right"
- **Proven**: "All tests pass" / "The linter found no issues" / "TypeScript compiles cleanly"

**The only way to KNOW if code works is to RUN THE CHECKS.**

### 2. TDD by Behavior — Tests First, Always

No implementation code without a failing test first. Tests validate **behavior**, not internal structure.

**The cycle**: Problem statement → Failing test → Minimal code → Pass → Refactor

- Tests MUST assert observable outcomes, NEVER implementation details
- A test that cannot fail is not a test; delete it

**Good test names:**
- "should render bold tag as Text with fontWeight bold"
- "should strip script tags from input"
- "should reject javascript: protocol in href"

**Bad test names:**
- "should have a bold renderer"
- "should call sanitize function"

### 3. Clean Slate Protocol — Before Every Push

Before EVERY `git push`, run the full CI suite locally from a clean slate:

```bash
# 1. Clean all build artifacts
yarn clean

# 2. Fresh dependency installation
rm -rf node_modules && yarn install

# 3. Run ALL quality checks
yarn lint
yarn typecheck

# 4. Build the library
yarn prepare

# 5. Run ALL tests
yarn test
yarn test:android   # if native code changed
yarn test:ios       # if native code changed
```

**There are NO exceptions:**
- "I only changed a comment" → Run the checks
- "It's just a typo fix" → Run the checks
- "The CI will catch it" → You catch it first

### 4. No Bypasses — Ever

NEVER use:
- `test.skip()`, `it.skip()`, `describe.skip()`, `xit`, `xdescribe`
- `// @ts-ignore`, `// @ts-expect-error`
- `// eslint-disable`, `// eslint-disable-next-line`
- `// prettier-ignore`

If a rule is wrong, fix the rule globally. Do not suppress locally.

### 5. Security First — XSS Prevention

This library renders HTML. Security is paramount.

**NEVER:**
- Use `dangerouslySetInnerHTML` without `DOMPurify.sanitize()`
- Assign to `.innerHTML` or `.outerHTML` directly
- Use `eval()`, `Function()`, or `new Function()` with dynamic content
- Allow `javascript:`, `data:`, or `vbscript:` protocols in URLs
- Pass through event handler attributes (`onclick`, `onerror`, etc.)

**ALWAYS:**
- Sanitize ALL HTML input through DOMPurify before rendering
- Validate URL protocols against allowlist (http, https, mailto, tel)
- Use allowlist-only approach for tags and attributes
- Test against OWASP XSS vectors

## Commands

```bash
# Quality gate (run before every push)
yarn lint && yarn typecheck && yarn test && yarn prepare

# Individual checks
yarn test              # Run Jest tests with coverage
yarn typecheck         # TypeScript strict mode check
yarn lint              # ESLint
yarn prepare           # Build library with bob

# Native tests
yarn test:android      # Android native tests
yarn test:ios          # iOS Swift tests

# Example app
yarn example start     # Start Metro bundler
yarn example ios       # Run iOS example
yarn example android   # Run Android example
```

## Type Policy

**Implementation code (strict):**
- NO `any` type without JSDoc justification and human approval
- NO `// @ts-ignore` or `// @ts-expect-error`
- Use `unknown` + type narrowing for external/dynamic data
- All exported functions MUST have explicit return types
- Prefer union types over `any`

**Test code (pragmatic):**
- MAY use looser types for test fixtures
- MUST NOT weaken behavior assertions
- MUST still pass strict TypeScript checks

## Project Structure

```text
src/
├── index.tsx                    # Public exports
├── FabricHTMLTextNativeComponent.ts  # Codegen native component
├── components/
│   ├── HTMLText.tsx             # Native adapter router
│   └── HTMLText.web.tsx         # Web implementation
├── adapters/
│   ├── native.tsx               # Native (iOS/Android) adapter
│   └── web/
│       └── StyleConverter.ts    # Web style utilities
├── core/                        # Platform-agnostic (CRITICAL)
│   ├── sanitize.ts              # Native sanitization
│   ├── sanitize.web.ts          # Web sanitization (DOMPurify)
│   ├── allowedHtml.ts           # Tag/attribute allowlists
│   └── constants.ts             # Shared constants
├── types/
│   ├── HTMLTextNativeProps.ts   # Component prop types
│   └── codegen.d.ts             # Codegen type declarations
└── __tests__/                   # Co-located tests

ios/                             # iOS native module (Objective-C)
android/                         # Android native module (Kotlin)
cpp/                             # Shared C++ (if applicable)
example/                         # Example app for testing
e2e/                             # End-to-end tests (Appium)
```

**Architecture rules:**
- `src/core/` MUST have zero platform-specific code
- Platform detection uses `Platform.OS` in adapters only
- Components are pure (props in, rendering out)

## CI/CD

- GitHub Actions on all PRs and pushes to `main`
- Same gates as local quality commands
- Any failure blocks merge
- No allow-failure jobs

**CI runs:**
- TypeScript typecheck
- ESLint
- Jest tests (with coverage)
- Library build (`yarn prepare`)
- Native tests (iOS, Android)

## Cross-Platform Requirements

- Same HTML input MUST produce visually identical output across platforms
- Same props MUST work identically on all platforms
- Performance MUST be within 20% across platforms

**Platform compatibility:**
- React Native >= 0.81 (Fabric/New Architecture required)
- iOS >= 15.1
- Android >= API 21
- Web: Direct react-dom implementation (no react-native-web dependency)
- Browsers: Chrome/Edge/Safari/Firefox (last 2 versions)

## Constitution Reference

Full governance rules: `.specify/memory/constitution.md`

**NON-NEGOTIABLE principles:**
- I. Test-Driven Development
- II. CI-First Local Verification
- III. No Ignores
- IV. TypeScript Strict Mode
- V. `any` Requires Approval
- VIII. WCAG AA Compliance
- HTML Sanitization Security (CRITICAL)

## Contributing

1. Fork the repository
2. Create a feature branch from `main`
3. Follow TDD: write failing test → implement → verify green
4. Run full quality gate locally before pushing
5. Open PR with clear description of changes
6. Address all review feedback

**PR requirements:**
- All CI checks pass
- No constitution violations
- Security-sensitive changes require extra scrutiny
- One concern per PR (atomic changes)

## Dependencies

**Runtime:**
- `dompurify` — HTML sanitization (required for security)

**Peer:**
- `react` >= 18
- `react-native` >= 0.80

**Dev:**
- TypeScript 5.x (strict mode)
- Jest 30.x
- ESLint 9.x
- react-native-builder-bob

## Active Technologies

- TypeScript 5.9.x with strict mode
- React Native 0.81.x (Fabric/New Architecture)
- React 19.x / react-dom 19.x (for web)
- DOMPurify 3.x for HTML sanitization
- Jest 30.x + React Testing Library for tests
- react-native-builder-bob for library builds
- Yarn 4.x with workspaces
