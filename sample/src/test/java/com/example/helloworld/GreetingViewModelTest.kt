package com.example.helloworld

import org.junit.Assert.assertEquals
import org.junit.Test

class GreetingViewModelTest {

    private val viewModel = GreetingViewModel()

    @Test
    fun initialGreetingIsHelloWorld() {
        assertEquals("Hello, World!", viewModel.uiState.value.greeting)
    }

    @Test
    fun nameInputPersonalisesGreeting() {
        viewModel.onNameChange("Android")
        assertEquals("Hello, Android!", viewModel.uiState.value.greeting)
    }

    @Test
    fun blankNameFallsBackToHelloWorld() {
        viewModel.onNameChange("   ")
        assertEquals("Hello, World!", viewModel.uiState.value.greeting)
    }

    @Test
    fun clearingNameResetsGreeting() {
        viewModel.onNameChange("Android")
        viewModel.onNameChange("")
        assertEquals("Hello, World!", viewModel.uiState.value.greeting)
    }
}
