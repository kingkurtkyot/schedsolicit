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
    if (project.name != "app") {
        afterEvaluate {
            val android = project.extensions.findByName("android")
            if (android != null) {
                for (m in android.javaClass.methods) {
                    if (m.name in listOf("setCompileSdk", "compileSdkVersion", "setCompileSdkVersion")) {
                        try {
                            if (m.parameterTypes.size == 1 && (m.parameterTypes[0] == Int::class.javaPrimitiveType || m.parameterTypes[0] == java.lang.Integer::class.java)) {
                                m.invoke(android, 36)
                                println("Updated ${project.name} compileSdk to 36 via ${m.name}")
                            }
                        } catch (e: Exception) {}
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
