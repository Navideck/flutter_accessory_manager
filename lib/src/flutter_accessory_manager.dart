import 'package:flutter/foundation.dart';
import 'package:flutter_accessory_manager/src/flutter_accessory_manager_interface.dart';
import 'package:flutter_accessory_manager/src/generated/flutter_accessory_manager.g.dart';
import 'package:flutter_accessory_manager/src/platforms/accessory_manager.dart';
import 'package:flutter_accessory_manager/src/platforms/accessory_manager_bluez.dart';
import 'package:flutter_accessory_manager/src/platforms/external_accessory.dart';

class FlutterAccessoryManager {
  static final FlutterAccessoryManagerInterface _platform = _defaultPlatform();

  static Future<void> showBluetoothAccessoryPicker({
    List<String> withNames = const [],
  }) {
    return _platform.showBluetoothAccessoryPicker(withNames: withNames);
  }

  static Future<void> closeEaSession(String? protocolString) =>
      _platform.closeEaSession(protocolString);

  static Future<void> disconnect(String deviceId) =>
      _platform.disconnect(deviceId);

  static Future<void> startScan() => _platform.startScan();

  static Future<void> stopScan() => _platform.stopScan();

  static Future<bool> isScanning() => _platform.isScanning();

  static Future<bool> pair(String address) => _platform.pair(address);

  static Future<List<BluetoothDevice>> getPairedDevices() =>
      _platform.getPairedDevices();

  static set accessoryConnected(AccessoryCallback? accessory) {
    FlutterAccessoryManagerInterface.accessoryConnected = accessory;
  }

  static set accessoryDisconnected(AccessoryCallback? accessory) {
    FlutterAccessoryManagerInterface.accessoryDisconnected = accessory;
  }

  static set onBluetoothDeviceDiscover(OnDeviceDiscover? device) {
    FlutterAccessoryManagerInterface.onBluetoothDeviceDiscover = device;
  }

  static FlutterAccessoryManagerInterface _defaultPlatform() {
    if (kIsWeb) return _DefaultImpl();
    if (defaultTargetPlatform == TargetPlatform.linux) {
      return AccessoryManagerBluez.instance;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ExternalAccessory.instance;
    } else {
      return AccessoryManager.instance;
    }
  }
}

class _DefaultImpl extends FlutterAccessoryManagerInterface {}
