#ifndef PLUGIN_REGISTRANT_H_
#define PLUGIN_REGISTRANT_H_

#include <flutter/plugin_registry.h>
#include <future>

[[nodiscard]] std::future<void> RegisterPlugins(flutter::PluginRegistry* registry);

#endif  // PLUGIN_REGISTRANT_H_