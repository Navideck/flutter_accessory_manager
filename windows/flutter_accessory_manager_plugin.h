#ifndef FLUTTER_PLUGIN_FLUTTER_ACCESSORY_MANAGER_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_ACCESSORY_MANAGER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include "FlutterAccessoryManager.g.h"

#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Devices.Bluetooth.Advertisement.h>
#include <winrt/Windows.Devices.Bluetooth.GenericAttributeProfile.h>
#include <winrt/Windows.Devices.Enumeration.h>
#include <winrt/Windows.Devices.Radios.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.Streams.h>

#include <memory>
#include "ui_thread_handler.hpp"

namespace flutter_accessory_manager
{
    using namespace winrt;
    using namespace winrt::Windows;
    using namespace winrt::Windows::Devices;
    using namespace winrt::Windows::Foundation;
    using namespace winrt::Windows::Foundation::Collections;
    using namespace winrt::Windows::Storage::Streams;
    using namespace winrt::Windows::Devices::Radios;
    using namespace winrt::Windows::Devices::Bluetooth;
    using namespace winrt::Windows::Devices::Bluetooth::Advertisement;
    using namespace winrt::Windows::Devices::Bluetooth::GenericAttributeProfile;
    using namespace Windows::Devices::Enumeration;

    constexpr uint32_t TEN_SECONDS_IN_MSECS = 10000;

    class FlutterAccessoryManagerPlugin : public flutter::Plugin, FlutterAccessoryPlatformChannel
    {
    public:
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

        FlutterAccessoryManagerPlugin(flutter::PluginRegistrarWindows *registrar);
        virtual ~FlutterAccessoryManagerPlugin();

        static void SuccessCallback() {}
        static void ErrorCallback(const FlutterError &error)
        {
            std::cout << "ErrorCallback: " << error.message() << std::endl;
        }

        FlutterAccessoryManagerPlugin(const FlutterAccessoryManagerPlugin &) = delete;
        FlutterAccessoryManagerPlugin &operator=(const FlutterAccessoryManagerPlugin &) = delete;

        UiThreadHandler uiThreadHandler_;
        DeviceWatcher deviceWatcher{nullptr};
        winrt::event_token deviceWatcherAddedToken;
        winrt::event_token deviceWatcherUpdatedToken;
        winrt::event_token deviceWatcherRemovedToken;
        winrt::event_token deviceWatcherEnumerationCompletedToken;
        winrt::event_token deviceWatcherStoppedToken;
        std::unordered_map<std::string, DeviceInformation> deviceWatcherDevices{};

        void setupDeviceWatcher();
        BluetoothDevice DeviceInfoToBluetoothDevice(DeviceInformation deviceInfo);
        winrt::fire_and_forget ShowDevicePicker(std::function<void(std::optional<FlutterError> reply)> result);
        winrt::fire_and_forget PairAsync(const std::string &address, std::function<void(ErrorOr<bool> reply)> result);
        winrt::fire_and_forget DisconnectAsync(const std::string &protocol_string, std::function<void(std::optional<FlutterError> reply)> result);

        // Channel
        void ShowBluetoothAccessoryPicker(std::function<void(std::optional<FlutterError> reply)> result);
        void CloseEaSession(
            const std::string &protocol_string,
            std::function<void(std::optional<FlutterError> reply)> result);
        std::optional<FlutterError> StartScan();
        std::optional<FlutterError> StopScan();
        ErrorOr<bool> IsScanning();
        ErrorOr<flutter::EncodableList> GetPairedDevices();
        void Pair(
            const std::string &address,
            std::function<void(ErrorOr<bool> reply)> result);

        /// To call async functions synchronously
        template <typename async_t>
        static auto async_get(async_t const &async)
        {
            if (async.Status() == Foundation::AsyncStatus::Started)
            {
                wait_for_completed(async, TEN_SECONDS_IN_MSECS);
            }
            try
            {
                return async.GetResults();
            }
            catch (const winrt::hresult_error &err)
            {
                throw FlutterError(winrt::to_string(err.message()));
            }
            catch (...)
            {
                throw FlutterError("Unknown error");
            }
        }

        std::string ParseBluetoothClientId(hstring clientId)
        {
            std::string deviceIdString = winrt::to_string(clientId);
            size_t pos = deviceIdString.find_last_of('-');
            if (pos != std::string::npos)
            {
                return deviceIdString.substr(pos + 1);
            }
            return deviceIdString;
        }

        uint64_t str_to_mac_address(std::string mac_str)
        {
            // TODO: Validate input - Expected Format: XX:XX:XX:XX:XX:XX
            uint64_t mac_address_number = 0;
            uint8_t *mac_ptr = (uint8_t *)&mac_address_number;
            sscanf_s(mac_str.c_str(), "%02hhx:%02hhx:%02hhx:%02hhx:%02hhx:%02hhx", &mac_ptr[5], &mac_ptr[4], &mac_ptr[3],
                     &mac_ptr[2], &mac_ptr[1], &mac_ptr[0]);
            return mac_address_number;
        }

        std::string DeviceWatcherStatusToString(DeviceWatcherStatus result)
        {
            switch (result)
            {
            case DeviceWatcherStatus::Created:
                return "Created";
            case DeviceWatcherStatus::Aborted:
                return "Aborted";
            case DeviceWatcherStatus::EnumerationCompleted:
                return "EnumerationCompleted";
            case DeviceWatcherStatus::Started:
                return "Started";
            case DeviceWatcherStatus::Stopped:
                return "Stopped";
            case DeviceWatcherStatus::Stopping:
                return "Stopping";
            }
            return "";
        }
    };

} // namespace flutter_accessory_manager

#endif
