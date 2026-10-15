import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de assinatura do release (android/key.properties, fora do git). Sem ela o
// release assina com a chave de debug — serve para testar, nunca para a loja.
val chaves = Properties().apply {
    val arquivo = rootProject.file("key.properties")
    if (arquivo.exists()) arquivo.inputStream().use { load(it) }
}

android {
    namespace = "com.carlos.paclingo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // o plugin de notificações (lembrete diário) usa as APIs novas de data/hora do Java: precisa de "desugaring"
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.carlos.paclingo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (chaves.isNotEmpty()) {
            create("release") {
                keyAlias = chaves.getProperty("keyAlias")
                keyPassword = chaves.getProperty("keyPassword")
                storeFile = file(chaves.getProperty("storeFile"))
                storePassword = chaves.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // lembrete diário (flutter_local_notifications): ver compileOptions acima
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
