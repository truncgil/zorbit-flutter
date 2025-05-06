plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.truncgil.zorbit2.wear"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            storeFile = file("keystore/zorbit_key.jks")
            storePassword = "14981498" // key.properties'ten alınan şifre
            keyAlias = "zorbit"
            keyPassword = "14981498" // key.properties'ten alınan şifre
        }
    }

    defaultConfig {
        applicationId = "com.truncgil.zorbit2.wear"
        minSdk = 21
        targetSdk = 35
        versionCode = 40003  // Yeni bir sürüm kodu - önceki tüm sürüm kodlarından büyük
        versionName = "1.0.0"
        
        // Android 14 (SDK 34) sorunu için özel çözüm
        buildConfigField("boolean", "ENABLE_DEFERRED_COMPONENTS", "false")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }

    configurations.all {
        // Android 14+ için Play Core bağımlılık sorununu çöz
        resolutionStrategy {
            force("com.google.android.play:core-common:2.0.3")
            
            // Play Core'un eski sürümlerini hariç tut
            eachDependency {
                if (requested.group == "com.google.android.play" && requested.name == "core") {
                    useTarget("com.google.android.play:core-common:2.0.3")
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Play Services için temel bağımlılıklar - Android 14 (SDK 34+) uyumlu
    implementation("com.google.android.play:core-common:2.0.3")
    
    // Play Core yerine güncel modüller
    implementation("com.google.android.play:app-update:2.1.0") {
        exclude(group = "com.google.android.play", module = "core")
    }
    
    // Flutter'ın kullandığı splitinstall API'si için gerekli
    implementation("com.google.android.play:feature-delivery:2.1.0") {
        exclude(group = "com.google.android.play", module = "core")
    }
    
    // Flutter deferred components için SplitCompat API'si
    implementation("androidx.core:core:1.10.0")
} 