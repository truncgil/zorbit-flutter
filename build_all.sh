#!/bin/bash

# Hata ayıklama için
set -e

# Renk kodları
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Zorbit Uygulama Derleme Scripti${NC}"
echo -e "${YELLOW}================================${NC}"

# Temizlik işlemi
echo -e "${GREEN}1. Temizlik yapılıyor...${NC}"
flutter clean

# Bağımlılıkları yükle
echo -e "${GREEN}2. Bağımlılıklar yükleniyor...${NC}"
flutter pub get

# --------------------------------------
# Telefon/TV sürümünü oluştur
# --------------------------------------
echo -e "\n${YELLOW}Telefon/TV Sürümü Hazırlanıyor...${NC}"

# Mevcut yapılandırmanın yedeğini al
echo -e "${GREEN}1. Yapılandırma dosyaları yedekleniyor...${NC}"
cp android/app/build.gradle.kts android/app/build.gradle.kts.bak
cp android/app/src/main/AndroidManifest.xml android/app/src/main/AndroidManifest.xml.bak
cp android/app/proguard-rules.pro android/app/proguard-rules.pro.bak

# Telefon/TV yapılandırmasını düzenle
echo -e "${GREEN}2. Telefon/TV yapılandırması uygulanıyor...${NC}"
cat > android/app/build.gradle.kts << 'EOL'
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.truncgil.zorbit2"
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
        applicationId = "com.truncgil.zorbit2"
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
EOL

cat > android/app/src/main/AndroidManifest.xml << 'EOL'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <!-- Ortak özellikler -->
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    
    <!-- TV özellikleri -->
    <uses-feature android:name="android.software.leanback" android:required="false" />
    
    <application
        android:label="zorbit"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:banner="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"> <!-- HTTP bağlantılarına izin ver -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
              
            <!-- Mobil telefonlar için intent filter -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
            <!-- Android TV için intent filter -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="http" />
        </intent>
    </queries>
</manifest>
EOL

cat > android/app/proguard-rules.pro << 'EOL'
# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter proguard kuralları
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# WebView kuralları
-keep class com.truncgil.zorbit.** { *; }
-keep class com.truncgil.zorbit2.** { *; }
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Webview ile ilgili kurallar
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
    public void *(android.webkit.WebView, java.lang.String);
}

# Url Launcher için kurallar
-keep class androidx.core.app.CoreComponentFactory { *; }

# Google Play Core sınıfları için keep rule
-keep class com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Google Play Core Ek kurallar
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.common.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.review.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }

# Play Core ve yeni Play kütüphaneleri için keep kuralları
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }

# Flutter kullanımı için keep kuralları
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Diğer Flutter proguard kuralları
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
EOL

# Telefon/TV AAB dosyasını oluştur
echo -e "${GREEN}3. Telefon/TV AAB dosyası oluşturuluyor...${NC}"
flutter build appbundle

# Dosyayı kaydet
echo -e "${GREEN}4. AAB dosyası phone_tv.aab olarak kaydediliyor...${NC}"
cp build/app/outputs/bundle/release/app-release.aab phone_tv.aab

# --------------------------------------
# Wear OS sürümünü oluştur
# --------------------------------------
echo -e "\n${YELLOW}Wear OS Sürümü Hazırlanıyor...${NC}"

# Wear OS yapılandırmasını düzenle
echo -e "${GREEN}1. Wear OS yapılandırması uygulanıyor...${NC}"
cat > android/app/build.gradle.kts << 'EOL'
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
EOL

cat > android/app/src/main/AndroidManifest.xml << 'EOL'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <!-- Ortak özellikler -->
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    
    <!-- Wear OS özellikleri - Zorunlu -->
    <uses-feature android:name="android.hardware.type.watch" android:required="true" />
    
    <application
        android:label="zorbit"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"> <!-- HTTP bağlantılarına izin ver -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
              
            <!-- Wear OS için intent filter -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="http" />
        </intent>
    </queries>
</manifest>
EOL

cat > android/app/proguard-rules.pro << 'EOL'
# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter proguard kuralları
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# WebView kuralları
-keep class com.truncgil.zorbit.** { *; }
-keep class com.truncgil.zorbit2.wear.** { *; }
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Webview ile ilgili kurallar
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
    public void *(android.webkit.WebView, java.lang.String);
}

# Url Launcher için kurallar
-keep class androidx.core.app.CoreComponentFactory { *; }

# Google Play Core sınıfları için keep rule
-keep class com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Google Play Core Ek kurallar
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.common.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.review.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }

# Play Core ve yeni Play kütüphaneleri için keep kuralları
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }

# Flutter kullanımı için keep kuralları
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Diğer Flutter proguard kuralları
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
EOL

# Wear OS AAB dosyasını oluştur
echo -e "${GREEN}2. Wear OS AAB dosyası oluşturuluyor...${NC}"
flutter clean && flutter pub get && flutter build appbundle

# Dosyayı kaydet
echo -e "${GREEN}3. AAB dosyası wear_os.aab olarak kaydediliyor...${NC}"
cp build/app/outputs/bundle/release/app-release.aab wear_os.aab

# Orijinal yapılandırma dosyalarını geri yükle
echo -e "${GREEN}4. Orijinal yapılandırma dosyaları geri yükleniyor...${NC}"
cp android/app/build.gradle.kts.bak android/app/build.gradle.kts
cp android/app/src/main/AndroidManifest.xml.bak android/app/src/main/AndroidManifest.xml
cp android/app/proguard-rules.pro.bak android/app/proguard-rules.pro

echo -e "\n${YELLOW}İşlem Tamamlandı!${NC}"
echo -e "AAB dosyaları:"
echo -e "${GREEN}* Telefon/TV:${NC} $(pwd)/phone_tv.aab"
echo -e "${GREEN}* Wear OS:${NC} $(pwd)/wear_os.aab" 