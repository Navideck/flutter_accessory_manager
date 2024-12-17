import 'dart:typed_data';

import 'package:flutter_accessory_manager/src/generated/external_accessory.g.dart';
import 'package:flutter_accessory_manager/src/generated/flutter_accessory_manager.g.dart';

abstract class FlutterAccessoryManagerInterface {
  static AccessoryCallback? accessoryConnected;
  static AccessoryCallback? accessoryDisconnected;
  static BluetoothDeviceCallback? onBluetoothDeviceDiscover;
  static BluetoothDeviceCallback? onBluetoothDeviceRemoved;

  Future<void> showBluetoothAccessoryPicker({
    List<String>? withNames,
  }) {
    throw UnimplementedError();
  }

  Future<void> closeEASession([String? protocolString]) {
    throw UnimplementedError();
  }

  Future<void> connect(String deviceId) {
    throw UnimplementedError();
  }

  Future<void> disconnect(String deviceId) {
    throw UnimplementedError();
  }

  Future<void> setupSdp(SdpConfig config) {
    throw UnimplementedError();
  }

  Future<void> sendReport(String deviceId, Uint8List data) {
    throw UnimplementedError();
  }

  Future<void> startScan() {
    throw UnimplementedError();
  }

  Future<void> stopScan() {
    throw UnimplementedError();
  }

  Future<bool> isScanning() {
    throw UnimplementedError();
  }

  Future<bool> pair(String address) {
    throw UnimplementedError();
  }

  Future<List<BluetoothDevice>> getPairedDevices() {
    throw UnimplementedError();
  }
}

typedef AccessoryCallback = void Function(EAAccessory accessory);

typedef BluetoothDeviceCallback = void Function(BluetoothDevice device);
