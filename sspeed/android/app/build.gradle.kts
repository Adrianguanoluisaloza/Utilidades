import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Cargar configuración de firma
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.speed7delivery.app"

    // Estos valores los expone el plugin de Flutter; están OK en Kotlin DSL
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Actualizado para usar Java 21 (compatible con JDK 21-25)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }
    
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
        }
    }

    defaultConfig {
        applicationId = "com.speed7delivery.app"
        minSdk = flutter.minSdkVersion       // ✅ Kotlin DSL (no usar minSdkVersion 21)
        targetSdk = flutter.targetSdkVersion // ✅
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // ✅ Configuración optimizada para producción
            isMinifyEnabled = true
            isShrinkResources = true
            
            // Usar firma de release propia
            signingConfig = signingConfigs.getByName("release")
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
        }
    }
    
    // ✅ OPTIMIZACIÓN: Dividir APK por arquitectura (reduce tamaño)
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true // También genera un APK universal
        }
    }
}

// Forzar toolchain Java 21 para Kotlin
kotlin {
    jvmToolchain(21)
}

flutter {
    source = "../.."
}

dependencies {
    // Google Play Core para Flutter deferred components
    implementation("com.google.android.play:core:1.10.3")
    implementation("com.google.android.play:core-ktx:1.8.1")
}

// ❌ NO pongas NADA más fuera de android{} / flutter{}.
// El bloque que te estaba rompiendo era este (elíminalo por completo):
// defaultConfig {
//     ...
//     minSdkVersion 21
// }
