import 'dart:typed_data';

import 'package:flutter_accessory_manager/src/flutter_accessory_manager_interface.dart';
import 'package:flutter_accessory_manager/src/generated/flutter_accessory_manager.g.dart';

class AccessoryManager extends FlutterAccessoryManagerInterface {
  static AccessoryManager? _instance;
  static AccessoryManager get instance => _instance ??= AccessoryManager._();

  AccessoryManager._() {
    FlutterAccessoryCallbackChannel.setUp(_CallbackHandler());
  }

  static final _channel = FlutterAccessoryPlatformChannel();

  @override
  Future<void> showBluetoothAccessoryPicker({
    List<String>? withNames,
  }) {
    return _channel.showBluetoothAccessoryPicker(withNames ?? []);
  }

  @override
  Future<void> disconnect(String deviceId) => _channel.disconnect(deviceId);

  @override
  Future<void> startScan() => _channel.startScan();

  @override
  Future<void> stopScan() => _channel.stopScan();

  @override
  Future<bool> isScanning() => _channel.isScanning();

  @override
  Future<bool> pair(String address) => _channel.pair(address);

  @override
  Future<List<BluetoothDevice>> getPairedDevices() =>
      _channel.getPairedDevices();

  @override
  Future<void> connect(String deviceId) => _channel.connect(deviceId);

  @override
  Future<void> sendReport(String deviceId, Uint8List data) =>
      _channel.sendReport(deviceId, data);

  @override
  Future<void> setupSdp(SdpConfig config) => _channel.setupSdp(config);
}

// Handle callbacks from Native to Flutter
class _CallbackHandler extends FlutterAccessoryCallbackChannel {
  @override
  void onDeviceDiscover(BluetoothDevice device) {
    FlutterAccessoryManagerInterface.onBluetoothDeviceDiscover?.call(device);
  }

  @override
  void onDeviceRemoved(BluetoothDevice device) {
    FlutterAccessoryManagerInterface.onBluetoothDeviceRemoved?.call(device);
  }
}
