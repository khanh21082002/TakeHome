func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
    let plugins = [
        "FLTFirebaseFirestorePlugin",
        "FLTFirebaseAuthPlugin", 
        "FLTFirebaseCorePlugin",
        "FLTFirebaseStoragePlugin",
        "SwiftPdfRenderPlugin"
    ]
    
    for plugin in plugins {
        registry.registrar(forPlugin: plugin).register()
    }
}