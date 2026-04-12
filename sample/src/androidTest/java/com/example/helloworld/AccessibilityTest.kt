package com.example.helloworld

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.isRoot
import androidx.test.espresso.accessibility.AccessibilityChecks
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.BeforeClass
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AccessibilityTest {

    companion object {

        @BeforeClass
        @JvmStatic
        fun enableAccessibilityChecks() {
            // ATF intercepts every Espresso View interaction and scans for violations.
            AccessibilityChecks.enable().setRunChecksFromRootView(true)
        }
    }

    // createAndroidComposeRule launches the activity and exposes the Compose
    // semantics API — needed because Compose renders via Canvas, not Views.
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun mainScreen_passesAccessibilityChecks() {
        // Compose semantics check: verifies the node is in the a11y tree.
        composeTestRule.onNodeWithText("Hello, World!").assertIsDisplayed()

        // ATF scan: onView(isRoot()) touches the View hierarchy so AccessibilityChecks
        // fires and inspects the full tree (including the ComposeView subtree).
        onView(isRoot()).check(matches(isDisplayed()))
    }

    @Test
    fun greeting_isInSemanticTree() {
        composeTestRule.onNodeWithText("Hello, World!").assertIsDisplayed()
    }

    @Test
    fun nameField_hasLabel() {
        // Verifies the text field exposes "Your name" in the Compose semantic tree —
        // the source of truth for TalkBack, unlike uiautomator dump (View layer).
        composeTestRule
            .onNode(hasSetTextAction() and hasText("Your name"))
            .assertIsDisplayed()
    }

    @Test
    fun nameField_isInteractive() {
        // hasSetTextAction() confirms the node is editable and reachable by TalkBack.
        composeTestRule
            .onNode(hasSetTextAction())
            .assertIsDisplayed()
    }
}
