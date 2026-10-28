import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties().apply {
    if (signingPropertiesFile.isFile) {
        signingPropertiesFile.reader(Charsets.UTF_8).use { load(it) }
    }
}

val validateReleaseSigning = tasks.register("validateReleaseSigning") {
    doLast {
        check(signingPropertiesFile.isFile) { "Configure android/key.properties before building a release." }
        check(listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all {
            !signingProperties.getProperty(it).isNullOrBlank()
        }) { "Missing release signing properties." }
    }
}

android {
    namespace = "com.corevent.corevent_work_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.corevent.corevent_work_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = signingProperties.getProperty("keyAlias")
            keyPassword = signingProperties.getProperty("keyPassword")
            storePassword = signingProperties.getProperty("storePassword")
            storeFile = signingProperties.getProperty("storeFile")?.let { file(it) }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        val variantName = variant.name.replaceFirstChar { it.uppercaseChar() }
        tasks.configureEach {
            if (name == "pre${variantName}Build") dependsOn(validateReleaseSigning)
        }
    }
}
