plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_app_traducctorpantallas"
    compileSdk = 36  // Android 15 (requerido por speech_to_text)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.traductor.flotante"
        minSdk = 24  // Android 7.0 (necesario para MediaProjection y ML Kit)
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        
        // Habilitar multidex si es necesario
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("androidx.cardview:cardview:1.0.0")
    implementation("com.google.android.material:material:1.11.0")
}

flutter {
    source = "../.."
}
