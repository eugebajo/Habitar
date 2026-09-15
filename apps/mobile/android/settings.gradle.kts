pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    // Etapa 3 (notificaciones push): lee apps/mobile/android/app/google-services.json
    // (ya en su lugar) para inicializar Firebase sin necesitar
    // firebase_options.dart - suficiente para Android, que es la unica
    // plataforma con un google-services.json cargado hoy.
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
