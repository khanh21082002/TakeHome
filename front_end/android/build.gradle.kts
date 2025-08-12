allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val customBuildDirectory: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(customBuildDirectory)

subprojects {
    val subprojectBuildDir: Directory = customBuildDirectory.dir(project.name)
    project.layout.buildDirectory.value(subprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}