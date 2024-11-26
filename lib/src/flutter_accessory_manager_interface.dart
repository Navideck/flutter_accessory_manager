import 'package:flutter_accessory_manager/src/generated/external_accessory.g.dart';
import 'package:flutter_accessory_manager/src/generated/flutter_accessory_manager.g.dart';

abstract class FlutterAccessoryManagerInterface {
  static AccessoryCallback? accessoryConnected;
  static AccessoryCallback? accessoryDisconnected;
  static OnDeviceDiscover? onBluetoothDeviceDiscover;

  Future<void> showBluetoothAccessoryPicker({
    List<String>? withNames,
  }) {
    throw UnimplementedError();
  }

  Future<void> closeEaSession(String? protocolString) {
    throw UnimplementedError();
  }

  Future<void> disconnect(String deviceId) {
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

typedef OnDeviceDiscover = void Function(BluetoothDevice device);
