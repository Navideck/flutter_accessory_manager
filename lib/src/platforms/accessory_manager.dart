import 'dart:typed_data';

import 'package:flutter_accessory_manager/src/flutter_accessory_manager_interface.dart';
import 'package:flutter_accessory_manager/src/generated/bluetooth_hid_manager.g.dart';
import 'package:flutter_accessory_manager/src/generated/flutter_accessory_manager.g.dart';

class AccessoryManager extends FlutterAccessoryManagerInterface {
  static AccessoryManager? _instance;
  static AccessoryManager get instance => _instance ??= AccessoryManager._();

  AccessoryManager._() {
    FlutterAccessoryCallbackChannel.setUp(_AccessoryCallbackHandler());
    BluetoothHidManagerCallbackChannel.setUp(_HidCallbackHandler());
  }

  static final _accessoryManagerChannel = FlutterAccessoryPlatformChannel();
  static final _hidManagerChannel = BluetoothHidManagerPlatformChannel();

  @override
  Future<void> showBluetoothAccessoryPicker({
    List<String>? withNames,
  }) {
    return _accessoryManagerChannel
        .showBluetoothAccessoryPicker(withNames ?? []);
  }

  @override
  Future<void> disconnect(String deviceId) =>
      _hidManagerChannel.disconnect(deviceId);

  @override
  Future<void> startScan() => _accessoryManagerChannel.startScan();

  @override
  Future<void> stopScan() => _accessoryManagerChannel.stopScan();

  @override
  Future<bool> isScanning() => _accessoryManagerChannel.isScanning();

  @override
  Future<bool> pair(String address) => _accessoryManagerChannel.pair(address);

  @override
  Future<List<BluetoothDevice>> getPairedDevices() =>
      _accessoryManagerChannel.getPairedDevices();

  @override
  Future<void> connect(String deviceId) => _hidManagerChannel.connect(deviceId);

  @override
  Future<void> sendReport(String deviceId, Uint8List data) =>
      _hidManagerChannel.sendReport(deviceId, data);

  @override
  Future<void> setupSdp(SdpConfig config) =>
      _hidManagerChannel.setupSdp(config);
}

// Handle callbacks from Native to Flutter
class _AccessoryCallbackHandler extends FlutterAccessoryCallbackChannel {
  @override
  void onDeviceDiscover(BluetoothDevice device) {
    FlutterAccessoryManagerInterface.onBluetoothDeviceDiscover?.call(device);
  }

  @override
  void onDeviceRemoved(BluetoothDevice device) {
    FlutterAccessoryManagerInterface.onBluetoothDeviceRemoved?.call(device);
  }
}

class _HidCallbackHandler extends BluetoothHidManagerCallbackChannel {
  @override
  void onConnectionStateChanged(String deviceId, bool connected) {
    FlutterAccessoryManagerInterface.onConnectionStateChanged
        ?.call(deviceId, connected);
  }

  @override
  ReportReply? onGetReport(String deviceId, ReportType type, int bufferSize) {
    return FlutterAccessoryManagerInterface.onGetReport?.call(
      deviceId,
      type,
      bufferSize,
    );
  }

  @override
  void onSdpServiceRegistrationUpdate(bool registered) {
    FlutterAccessoryManagerInterface.onSdpServiceRegistrationUpdate?.call(
      registered,
    );
  }
}
