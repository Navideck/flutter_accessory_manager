import 'package:flutter/foundation.dart';
import 'package:flutter_accessory_manager/flutter_accessory_manager.dart';
import 'package:flutter_accessory_manager/src/flutter_accessory_manager_interface.dart';
import 'package:flutter_accessory_manager/src/platforms/accessory_manager.dart';
import 'package:flutter_accessory_manager/src/platforms/accessory_manager_bluez.dart';
import 'package:flutter_accessory_manager/src/platforms/external_accessory.dart';

class FlutterAccessoryManager {
  /// Get platform specific implementation.
  static FlutterAccessoryManagerInterface _platform = _defaultPlatform();

  /// Set custom platform specific implementation (e.g. for testing).
  static void setInstance(FlutterAccessoryManagerInterface instance) =>
      _platform = instance;

  static Future<void> showBluetoothAccessoryPicker({
    List<String> withNames = const [],
  }) {
    return _platform.showBluetoothAccessoryPicker(withNames: withNames);
  }

  /// Closes the EASession.
  /// If no protocol string is passed then it will use the first one available
  static Future<void> closeEASession([String? protocolString]) =>
      _platform.closeEASession(protocolString);

  static Future<void> disconnect(String deviceId) =>
      _platform.disconnect(deviceId);

  static Future<void> connect(String deviceId) => _platform.connect(deviceId);

  static Future<void> sendReport(String deviceId, Uint8List data) =>
      _platform.sendReport(deviceId, data);

  static Future<void> setupSdp({
    required SdpConfig config,
  }) =>
      _platform.setupSdp(config);

  static Future<void> closeSdp() => _platform.closeSdp();

  static Future<void> startScan() => _platform.startScan();

  static Future<void> stopScan() => _platform.stopScan();

  static Future<bool> isScanning() => _platform.isScanning();

  static Future<bool> pair(String address) => _platform.pair(address);

  static Future<List<BluetoothDevice>> getPairedDevices() =>
      _platform.getPairedDevices();

  static set accessoryConnected(AccessoryCallback? callback) {
    FlutterAccessoryManagerInterface.accessoryConnected = callback;
  }

  static set accessoryDisconnected(AccessoryCallback? callback) {
    FlutterAccessoryManagerInterface.accessoryDisconnected = callback;
  }

  static set onBluetoothDeviceDiscover(BluetoothDeviceCallback? callback) {
    FlutterAccessoryManagerInterface.onBluetoothDeviceDiscover = callback;
  }

  static set onBluetoothDeviceRemoved(BluetoothDeviceCallback? callback) {
    FlutterAccessoryManagerInterface.onBluetoothDeviceRemoved = callback;
  }

  static set onConnectionStateChanged(ConnectionChangeCallback? callback) {
    FlutterAccessoryManagerInterface.onConnectionStateChanged = callback;
  }

  static set onGetReport(GetReportCallback? callback) {
    FlutterAccessoryManagerInterface.onGetReport = callback;
  }

  static set onSdpServiceRegistrationUpdate(
      SdpServiceRegistrationUpdateCallback? callback) {
    FlutterAccessoryManagerInterface.onSdpServiceRegistrationUpdate = callback;
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
