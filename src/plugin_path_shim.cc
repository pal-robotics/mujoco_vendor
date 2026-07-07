// LD_PRELOAD shim injected by the `simulate` wrapper script in scripts/simulate.
//
// Its constructor runs before the prebuilt simulate binary's main() and loads
// MuJoCo plugin libraries from every package that registered a "mujoco_plugins"
// resource in the ament resource index. 
// Plugin registration is process-global inside libmujoco.so, so plugins loaded
// here are visible to the unmodified binary.
// The binary's own scan of plugins still runs afterwards, unaffected.

#include <cstdio>
#include <exception>
#include <filesystem>
#include <string>
#include <system_error>

#include <ament_index_cpp/get_resource.hpp>
#include <ament_index_cpp/get_resources.hpp>
#include <mujoco/mujoco.h>

namespace {

// Load all .so plugins from a directory, following symlinks.
void loadPluginsFromDirectory(const std::string& plugin_dir) {
  std::error_code ec;
  if (!std::filesystem::is_directory(plugin_dir, ec)) {
    return;
  }

  for (const auto& entry : std::filesystem::directory_iterator(plugin_dir, ec)) {
    if (!entry.is_regular_file(ec)) {
      continue;
    }

    const auto& path = entry.path();
    if (path.extension() != ".so") {
      continue;
    }

    int before = mjp_pluginCount();
    mj_loadPluginLibrary(path.c_str());
    int after = mjp_pluginCount();
    if (after > before) {
      std::printf("Plugins registered by library '%s':\n", path.filename().c_str());
      for (int i = before; i < after; ++i) {
        std::printf("    %s\n", mjp_getPluginAtSlot(i)->name);
      }
    } else {
      std::printf("No plugins loaded from: '%s':\n", path.filename().c_str());
    }
  }
}

__attribute__((constructor))
void loadAmentResourcePlugins() {
  std::printf("Loading plugins from ament resources...\n");

  try {
    // Try to find all packages that registered mujoco plugins via the ament resource index
    auto plugins = ament_index_cpp::get_resources("mujoco_plugins");
    for (const auto& [package_name, _] : plugins) {
      std::string content;
      std::string prefix;
      if (ament_index_cpp::get_resource("mujoco_plugins", package_name, content, &prefix)) {
        const std::string plugin_dir = prefix + "/" + content;
        std::printf("Loading MuJoCo plugins from package '%s': %s\n", package_name.c_str(),
                    plugin_dir.c_str());
        loadPluginsFromDirectory(plugin_dir);
      }
    }
  } catch (const std::exception& e) {
    std::fprintf(stderr, "mujoco_plugin_shim: skipping ament plugin discovery: %s\n", e.what());
  }

  std::printf("Finished loading plugins from ament resources!\n");
}

}  // namespace
