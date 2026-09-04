allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                if (getNamespace.invoke(android) == null) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    val pkgName = if (manifestFile.exists()) {
                        val match = Regex("""package="([^"]+)"""").find(manifestFile.readText())
                        match?.groupValues?.get(1) ?: "com.plugin.${project.name}"
                    } else {
                        "com.plugin.${project.name}"
                    }
                    setNamespace.invoke(android, pkgName)
                }
            } catch (_: Exception) {}
        }
    }

    val configureCompileSdk: Project.() -> Unit = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val getCompileSdkVersion = android.javaClass.methods.find { it.name == "getCompileSdkVersion" }
                val currentSdk = getCompileSdkVersion?.invoke(android)?.toString()?.replace("android-", "")?.toIntOrNull() ?: 0
                if (currentSdk in 1..33) {
                    val setCompileSdkVersion = android.javaClass.methods.find {
                        (it.name == "compileSdkVersion" || it.name == "setCompileSdkVersion") &&
                        it.parameterTypes.isNotEmpty() &&
                        (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == Integer::class.java)
                    }
                    setCompileSdkVersion?.invoke(android, 34)
                    println("Set ${project.name} compileSdkVersion from $currentSdk to 34")
                }
            } catch (e: Exception) {
                println("Error setting compileSdkVersion on ${project.name}: $e")
            }
        }
    }

    if (state.executed) {
        configureCompileSdk()
    } else {
        afterEvaluate {
            configureCompileSdk()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
