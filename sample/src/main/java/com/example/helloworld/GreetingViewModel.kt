package com.example.helloworld

import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

data class GreetingUiState(val name: String = "") {
    val greeting: String get() = if (name.isBlank()) "Hello, World!" else "Hello, $name!"
}

class GreetingViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(GreetingUiState())
    val uiState: StateFlow<GreetingUiState> = _uiState.asStateFlow()

    fun onNameChange(name: String) {
        _uiState.update { it.copy(name = name) }
    }
}
