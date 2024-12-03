#include "flutter_accessory_manager_plugin.h"

#include <windows.h>
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace flutter_accessory_manager
{
  const auto isConnectableKey = L"System.Devices.Aep.Bluetooth.Le.IsConnectable";
  const auto isConnectedKey = L"System.Devices.Aep.IsConnected";
  const auto isPairedKey = L"System.Devices.Aep.IsPaired";
  const auto isPresentKey = L"System.Devices.Aep.IsPresent";
  const auto deviceAddressKey = L"System.Devices.Aep.DeviceAddress";
  const auto signalStrengthKey = L"System.Devices.Aep.SignalStrength";

  std::unique_ptr<FlutterAccessoryCallbackChannel> callbackChannel;

  void FlutterAccessoryManagerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar)
  {
    auto plugin = std::make_unique<FlutterAccessoryManagerPlugin>(registrar);
    FlutterAccessoryPlatformChannel::SetUp(registrar->messenger(), plugin.get());
    callbackChannel = std::make_unique<FlutterAccessoryCallbackChannel>(registrar->messenger());
    registrar->AddPlugin(std::move(plugin));
  }

  FlutterAccessoryManagerPlugin::FlutterAccessoryManagerPlugin(flutter::PluginRegistrarWindows *registrar)
      : uiThreadHandler_(registrar)
  {
  }

  FlutterAccessoryManagerPlugin::~FlutterAccessoryManagerPlugin() {}

  void FlutterAccessoryManagerPlugin::ShowBluetoothAccessoryPicker(
      const flutter::EncodableList &with_names,
      std::function<void(std::optional<FlutterError> reply)> result)
  {
    ShowDevicePicker(result);
  }

  void FlutterAccessoryManagerPlugin::Disconnect(
      const std::string &device_id,
      std::function<void(std::optional<FlutterError> reply)> result)
  {
    DisconnectAsync(device_id, result);
  }

  std::optional<FlutterError> FlutterAccessoryManagerPlugin::StartScan()
  {
    try
    {
      setupDeviceWatcher();
      auto status = deviceWatcher.Status();
      std::cout << "StartingScan, CurrentState: " << DeviceWatcherStatusToString(status) << std::endl;
      if (status != DeviceWatcherStatus::Started)
      {
        deviceWatcher.Start();
      }
    }
    catch (const winrt::hresult_error &err)
    {
      int errorCode = err.code();
      std::cout << "StartScan: " << winrt::to_string(err.message()) << " ErrorCode: " << std::to_string(errorCode) << std::endl;
      return FlutterError(std::to_string(errorCode), winrt::to_string(err.message()));
    }
    catch (...)
    {
      std::cout << "Unknown error StartScan" << std::endl;
      return FlutterError("Unknown error");
    }

    return std::nullopt;
  }

  std::optional<FlutterError> FlutterAccessoryManagerPlugin::StopScan()
  {
    try
    {
      if (deviceWatcher != nullptr)
      {
        auto status = deviceWatcher.Status();
        std::cout << "StoppingScan, CurrentState: " << DeviceWatcherStatusToString(status) << std::endl;

        if (deviceWatcher.Status() == DeviceWatcherStatus::Started)
        {
          deviceWatcher.Stop();
        }
        deviceWatcher.Added(deviceWatcherAddedToken);
        deviceWatcher.Updated(deviceWatcherUpdatedToken);
        deviceWatcher.Removed(deviceWatcherRemovedToken);
        deviceWatcher.EnumerationCompleted(deviceWatcherEnumerationCompletedToken);
        deviceWatcher.Stopped(deviceWatcherStoppedToken);
        deviceWatcher = nullptr;
        deviceWatcherDevices.clear();
      }
    }
    catch (const winrt::hresult_error &err)
    {
      int errorCode = err.code();
      std::cout << "StartScan: " << winrt::to_string(err.message()) << " ErrorCode: " << std::to_string(errorCode) << std::endl;
      return FlutterError(std::to_string(errorCode), winrt::to_string(err.message()));
    }
    catch (...)
    {
      std::cout << "Unknown error StartScan" << std::endl;
      return FlutterError("Unknown error");
    }
    return std::nullopt;
  }

  ErrorOr<bool> FlutterAccessoryManagerPlugin::IsScanning()
  {
    if (deviceWatcher == nullptr)
    {
      return false;
    }
    auto status = deviceWatcher.Status();
    std::cout << "CurrentState: " << DeviceWatcherStatusToString(status) << std::endl;
    return status != DeviceWatcherStatus::Stopped;
  }

  ErrorOr<flutter::EncodableList> FlutterAccessoryManagerPlugin::GetPairedDevices()
  {
    try
    {
      auto selector = Devices::Bluetooth::BluetoothDevice::GetDeviceSelectorFromPairingState(true);
      Enumeration::DeviceInformationCollection devices = async_get(Enumeration::DeviceInformation::FindAllAsync(selector));
      flutter::EncodableList results = flutter::EncodableList();
      for (auto &&deviceInfo : devices)
      {
        try
        {
          auto device = DeviceInfoToBluetoothDevice(deviceInfo);
          results.push_back(flutter::CustomEncodableValue(device));
        }
        catch (...)
        {
        }
      }
      return results;
    }
    catch (const winrt::hresult_error &err)
    {
      int errorCode = err.code();
      std::cout << "GetPairedDevices: " << winrt::to_string(err.message()) << " ErrorCode: " << std::to_string(errorCode) << std::endl;
      return FlutterError(std::to_string(errorCode), winrt::to_string(err.message()));
    }
    catch (...)
    {
      std::cout << "Unknown error GetPairedDevices" << std::endl;
      return FlutterError("Unknown error");
    }
  }

  void FlutterAccessoryManagerPlugin::Pair(
      const std::string &address,
      std::function<void(ErrorOr<bool> reply)> result)
  {
    PairAsync(address, result);
  }

  // Helper methods
  void FlutterAccessoryManagerPlugin::setupDeviceWatcher()
  {
    if (deviceWatcher != nullptr)
      return;

    // Filter Paired or Unpaired Classic+Ble Devices
    auto selector = L"((" + Bluetooth::BluetoothDevice::GetDeviceSelectorFromPairingState(true) +
                    L") OR (" +
                    Bluetooth::BluetoothDevice::GetDeviceSelectorFromPairingState(true) +
                    L")) OR ((" +
                    Bluetooth::BluetoothDevice::GetDeviceSelectorFromPairingState(false) +
                    L") OR (" +
                    Bluetooth::BluetoothDevice::GetDeviceSelectorFromPairingState(false) + L"))";

    // Filter Paired or Unpaired Classic Devices
    // auto selector = L"(" +
    //                 Bluetooth::BluetoothDevice::GetDeviceSelectorFromPairingState(false) +
    //                 L") OR (" +
    //                 Bluetooth::BluetoothDevice::GetDeviceSelectorFromPairingState(true) +
    //                 L")";

    deviceWatcher = DeviceInformation::CreateWatcher(
        selector,
        {
            deviceAddressKey,
            isConnectedKey,
            isPairedKey,
            isPresentKey,
            isConnectableKey,
            signalStrengthKey,
        },
        DeviceInformationKind::AssociationEndpoint);

    deviceWatcherAddedToken = deviceWatcher.Added([this](DeviceWatcher sender, DeviceInformation deviceInfo)
                                                  {
                                                    auto deviceInfoId = deviceInfo.Id();
                                                    std::string deviceId = winrt::to_string(deviceInfoId);
                                                    if (isBluetoothClassic(deviceInfoId))
                                                    {
                                                      deviceWatcherDevices.insert_or_assign(deviceId, deviceInfo);
                                                      auto device = DeviceInfoToBluetoothDevice(deviceInfo);
                                                      uiThreadHandler_.Post([device]
                                                                            { callbackChannel->OnDeviceDiscover(device, SuccessCallback, ErrorCallback); });
                                                    }
                                                    // On Device Added
                                                  });

    deviceWatcherUpdatedToken = deviceWatcher.Updated([this](DeviceWatcher sender, DeviceInformationUpdate deviceInfoUpdate)
                                                      {
                                                        std::string deviceId = winrt::to_string(deviceInfoUpdate.Id());
                                                        auto it = deviceWatcherDevices.find(deviceId);
                                                        if (it != deviceWatcherDevices.end())
                                                        {
                                                          it->second.Update(deviceInfoUpdate);
                                                          auto device = DeviceInfoToBluetoothDevice(it->second);
                                                          uiThreadHandler_.Post([device]
                                                                                { callbackChannel->OnDeviceDiscover(device, SuccessCallback, ErrorCallback); });
                                                        }
                                                        // On Device Updated
                                                      });

    deviceWatcherRemovedToken = deviceWatcher.Removed([this](DeviceWatcher sender, DeviceInformationUpdate args)
                                                      {
                                                        std::string deviceId = winrt::to_string(args.Id());
                                                        deviceWatcherDevices.erase(deviceId);
                                                        std::cout << "DeviceRemoved: " << deviceId << std::endl;
                                                        // On Device Removed
                                                      });

    deviceWatcherEnumerationCompletedToken = deviceWatcher.EnumerationCompleted([this](DeviceWatcher sender, IInspectable args)
                                                                                { std::cout << "DeviceWatcherEvent: EnumerationCompleted" << std::endl; });

    deviceWatcherStoppedToken = deviceWatcher.Stopped([this](DeviceWatcher sender, IInspectable args)
                                                      { std::cout << "DeviceWatcherEvent: Stopped" << std::endl; });
  }

  std::string parsePairingResultStatus(DevicePairingResultStatus status)
  {
    switch (status)
    {
    case DevicePairingResultStatus::Paired:
      return "Paired";
    case DevicePairingResultStatus::NotReadyToPair:
      return "NotReadyToPair";
    case DevicePairingResultStatus::NotPaired:
      return "NotPaired";
    case DevicePairingResultStatus::AlreadyPaired:
      return "AlreadyPaired";
    case DevicePairingResultStatus::ConnectionRejected:
      return "ConnectionRejected";
    case DevicePairingResultStatus::TooManyConnections:
      return "TooManyConnections";
    case DevicePairingResultStatus::HardwareFailure:
      return "HardwareFailure";
    case DevicePairingResultStatus::AuthenticationTimeout:
      return "AuthenticationTimeout";
    case DevicePairingResultStatus::AuthenticationNotAllowed:
      return "AuthenticationNotAllowed";
    case DevicePairingResultStatus::AuthenticationFailure:
      return "AuthenticationFailure";
    case DevicePairingResultStatus::NoSupportedProfiles:
      return "NoSupportedProfiles";
    case DevicePairingResultStatus::ProtectionLevelCouldNotBeMet:
      return "ProtectionLevelCouldNotBeMet";
    case DevicePairingResultStatus::AccessDenied:
      return "AccessDenied";
    case DevicePairingResultStatus::InvalidCeremonyData:
      return "InvalidCeremonyData";
    case DevicePairingResultStatus::PairingCanceled:
      return "PairingCanceled";
    case DevicePairingResultStatus::OperationAlreadyInProgress:
      return "OperationAlreadyInProgress";
    case DevicePairingResultStatus::RequiredHandlerNotRegistered:
      return "RequiredHandlerNotRegistered";
    case DevicePairingResultStatus::RejectedByHandler:
      return "RejectedByHandler";
    case DevicePairingResultStatus::RemoteDeviceHasAssociation:
      return "RemoteDeviceHasAssociation";
    case DevicePairingResultStatus::Failed:
      return "Failed";
    default:
      return "UnknownStatus";
    }
  }

  winrt::fire_and_forget FlutterAccessoryManagerPlugin::ShowDevicePicker(std::function<void(std::optional<FlutterError> reply)> result)
  {
    DevicePicker picker = DevicePicker();
    picker.Filter().SupportedDeviceSelectors().Append(Bluetooth::BluetoothDevice::GetDeviceSelectorFromPairingState(false));
    auto selectedDevice = co_await picker.PickSingleDeviceAsync(Windows::Foundation::Rect(100, 100, 300, 300));
    if (selectedDevice == nullptr)
    {
      result(FlutterError("No device selected"));
      co_return;
    }
    // TODO:Probably This will not work fine on Windows 10
    auto pairResult = co_await selectedDevice.Pairing().PairAsync();
    std::cout << "PairLog: Received pairing status" << parsePairingResultStatus(pairResult.Status()) << std::endl;
    bool isPaired = pairResult.Status() == Enumeration::DevicePairingResultStatus::Paired;
    if (!isPaired)
    {
      result(FlutterError("Pairing Failed"));
    }
    else
    {
      result(std::nullopt);
    }
  }

  winrt::fire_and_forget FlutterAccessoryManagerPlugin::PairAsync(
      const std::string &address,
      std::function<void(ErrorOr<bool> reply)> result)
  {
    try
    {
      auto device = co_await Bluetooth::BluetoothDevice::FromBluetoothAddressAsync(str_to_mac_address(address));
      auto deviceInformation = device.DeviceInformation();
      if (deviceInformation.Pairing().IsPaired())
        result(true);
      else if (!deviceInformation.Pairing().CanPair())
        result(FlutterError("Device is not pairable"));
      else
      {
        // TODO:Probably This will not work fine on Windows 10
        auto pairResult = co_await deviceInformation.Pairing().PairAsync();
        std::cout << "PairLog: Received pairing status" << parsePairingResultStatus(pairResult.Status()) << std::endl;
        bool isPaired = pairResult.Status() == Enumeration::DevicePairingResultStatus::Paired;
        result(isPaired);
      }
    }
    catch (...)
    {
      result(false);
      std::cout << "PairLog: Unknown error" << std::endl;
    }
  }

  winrt::fire_and_forget FlutterAccessoryManagerPlugin::DisconnectAsync(const std::string &device_id, std::function<void(std::optional<FlutterError> reply)> result)
  {
    try
    {
      Bluetooth::BluetoothDevice device = co_await Bluetooth::BluetoothDevice::FromBluetoothAddressAsync(str_to_mac_address(device_id));
      if (device != nullptr && device.ConnectionStatus() == BluetoothConnectionStatus::Connected)
      {
        device.Close();
        device = nullptr;
      }
      else
      {
        std::cout << "Device not connected" << std::endl;
      }
      result(std::nullopt);
    }
    catch (const winrt::hresult_error &err)
    {
      int errorCode = err.code();
      std::cout << "DisconnectAsync: " << winrt::to_string(err.message()) << " ErrorCode: " << std::to_string(errorCode) << std::endl;
      result(FlutterError(std::to_string(errorCode), winrt::to_string(err.message())));
    }
    catch (...)
    {
      std::cout << "DisconnectAsync: Unknown error" << std::endl;
      result(FlutterError("Something Went Wrong"));
    }
  }

  BluetoothDevice FlutterAccessoryManagerPlugin::DeviceInfoToBluetoothDevice(DeviceInformation deviceInfo)
  {
    auto properties = deviceInfo.Properties();
    hstring address = deviceInfo.Id();
    if (properties.HasKey(deviceAddressKey))
    {
      auto bluetoothAddressPropertyValue = properties.Lookup(deviceAddressKey).as<IPropertyValue>();
      if (bluetoothAddressPropertyValue != nullptr)
      {
        address = bluetoothAddressPropertyValue.GetString();
      }
    }

    bool isPaired = deviceInfo.Pairing().IsPaired();
    if (properties.HasKey(isPairedKey))
    {
      auto isPairedPropertyValue = properties.Lookup(isPairedKey).as<IPropertyValue>();
      if (isPairedPropertyValue != nullptr)
      {
        isPaired = isPairedPropertyValue.GetBoolean();
      }
    }

    int64_t rssi = 0;
    if (properties.HasKey(signalStrengthKey))
    {
      auto rssiPropertyValue = properties.Lookup(signalStrengthKey).as<IPropertyValue>();
      if (rssiPropertyValue != nullptr)
      {
        rssi = rssiPropertyValue.GetInt64();
      }
    }

    auto deviceAddress = ParseBluetoothClientId(address);
    std::string name = winrt::to_string(deviceInfo.Name());

    return BluetoothDevice(deviceAddress, &name, isPaired, rssi);
  }

} // namespace flutter_accessory_manager
