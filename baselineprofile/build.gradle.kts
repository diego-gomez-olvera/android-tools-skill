plugins {
    alias(libs.plugins.android.test)
    alias(libs.plugins.baselineprofile)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.example.baselineprofile"
    compileSdk = 36

    defaultConfig {
        minSdk = 26
        targetSdk = 36

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    targetProjectPath = ":sample"
}

dependencies {
    implementation(libs.androidx.uiautomator)
    implementation(libs.androidx.benchmark.macro.junit4)
}
