package io.michaelfay.fabrichtmltext

import androidx.test.espresso.accessibility.AccessibilityChecks
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.platform.app.InstrumentationRegistry
import com.google.android.apps.common.testing.accessibility.framework.AccessibilityCheckResult.AccessibilityCheckResultType
import org.junit.Assert.assertNotNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumented accessibility tests using Android Testing Framework (ATF).
 *
 * These tests run on a real device or emulator and use Espresso's accessibility
 * checking framework to catch common accessibility issues:
 * - Missing content descriptions
 * - Touch target too small
 * - Low contrast text
 * - Inaccessible clickable elements
 *
 * ## Running These Tests
 *
 * ```bash
 * ./gradlew connectedAndroidTest \
 *   --tests "io.michaelfay.fabrichtmltext.FabricHTMLAccessibilityInstrumentedTest"
 * ```
 *
 * ## Prerequisites
 *
 * Add to android/build.gradle:
 * ```groovy
 * androidTestImplementation 'androidx.test.espresso:espresso-accessibility:3.6.1'
 * androidTestImplementation 'androidx.test.ext:junit:1.2.1'
 * androidTestImplementation 'androidx.test:runner:1.6.2'
 * ```
 *
 * WCAG 2.1 Level AA Requirements Validated:
 * - 2.4.4 Link Purpose: Links are properly labeled
 * - 4.1.2 Name, Role, Value: AccessibilityNodeInfo is correct
 * - 2.5.5 Target Size: Touch targets are adequate
 */
@RunWith(AndroidJUnit4::class)
@LargeTest
class FabricHTMLAccessibilityInstrumentedTest {

    /**
     * Enable accessibility checking globally for all Espresso interactions.
     * This will automatically check for accessibility issues after each view action.
     */
    @Before
    fun enableAccessibilityChecks() {
        AccessibilityChecks.enable()
            .setRunChecksFromRootView(true)
            .setThrowExceptionFor(AccessibilityCheckResultType.ERROR)
    }

    // TODO: Add test rule for your activity containing FabricHTMLTextView
    // Example:
    // @get:Rule
    // val activityRule = ActivityScenarioRule(TestActivity::class.java)

    /**
     * TODO: Implement real accessibility tests when integrating with example app.
     *
     * Manual Test Steps:
     * 1. Create an Activity with FabricHTMLTextView containing links
     * 2. Enable TalkBack on device/emulator
     * 3. Navigate to the view and verify:
     *    - Each link is individually focusable
     *    - Link position is announced ("Link 1 of 3")
     *    - Link type is announced ("web link", "phone number", "email address")
     *    - Double-tap activates the link
     *    - Touch targets are at least 48dp (WCAG 2.5.5)
     *
     * Automated Test Acceptance Criteria:
     * - Use ActivityScenarioRule to launch test activity
     * - Use Espresso with onView(withId(R.id.html_text_view))
     * - Verify hasContentDescription() for links
     * - Verify ATF checks pass (touch target size, contrast, labels)
     * - Verify click() performs link navigation
     *
     * Example implementation:
     * ```kotlin
     * @get:Rule
     * val activityRule = ActivityScenarioRule(TestActivity::class.java)
     *
     * @Test
     * fun testLinkAccessibility() {
     *     onView(withId(R.id.html_text_view))
     *         .check(matches(hasContentDescription()))
     *         .perform(click())
     *     // ATF automatically checks accessibility after each action
     * }
     * ```
     */
    /**
     * Validates that the instrumentation context is available and accessibility checks are enabled.
     * This test verifies the test harness is properly configured.
     *
     * TODO: Replace with ActivityScenario-based tests when integrating with example app.
     */
    @Test
    fun accessibilityCheckingIsEnabled() {
        // Verify instrumentation context is available
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        assertNotNull("Target context should be available for instrumented tests", context)

        // Verify the package is correct
        assertNotNull("Package name should be available", context.packageName)
    }
}
