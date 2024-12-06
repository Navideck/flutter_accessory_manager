#include "include/flutter_accessory_manager/flutter_accessory_manager_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_accessory_manager_plugin.h"

void FlutterAccessoryManagerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_accessory_manager::FlutterAccessoryManagerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
