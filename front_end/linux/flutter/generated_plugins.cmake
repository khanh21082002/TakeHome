#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGINS
)

list(APPEND FLUTTER_FFI_PLUGINS
)

set(PLUGIN_BUNDLED_LIBS)

foreach(plugin_name ${FLUTTER_PLUGINS})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin_name}/linux plugins/${plugin_name})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin_name}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBS $<TARGET_FILE:${plugin_name}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBS ${${plugin_name}_bundled_libraries})
endforeach(plugin_name)

foreach(ffi_plugin_name ${FLUTTER_FFI_PLUGINS})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin_name}/linux plugins/${ffi_plugin_name})
  list(APPEND PLUGIN_BUNDLED_LIBS ${${ffi_plugin_name}_bundled_libraries})
endforeach(ffi_plugin_name)