import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_accessory_manager/src/flutter_accessory_manager_interface.dart';
import 'package:flutter_accessory_manager/src/generated/external_accessory.g.dart';

class ExternalAccessory extends FlutterAccessoryManagerInterface {
  static ExternalAccessory? _instance;
  static ExternalAccessory get instance => _instance ??= ExternalAccessory._();

  ExternalAccessory._() {
    ExternalAccessoryCallbackChannel.setUp(_CallbackHandler());
  }

  static final _channel = ExternalAccessoryChannel();

  @override
  Future<void> showBluetoothAccessoryPicker({
    List<String>? withNames,
  }) {
    // return compute(showPickerInBackground, []);
    RootIsolateToken? rootIsolateToken = RootIsolateToken.instance;
    if (rootIsolateToken != null) {
      return Isolate.spawn(_showPickerInBackground, rootIsolateToken);
    } else {
      return _channel.showBluetoothAccessoryPicker(withNames ?? []);
    }
  }

  Future<void> _showPickerInBackground(
    RootIsolateToken rootIsolateToken,
  ) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    try {
      await ExternalAccessoryChannel().showBluetoothAccessoryPicker([]);
    } catch (e) {
      print("AccessoryPickerError: $e");
    }
  }

  @override
  Future<void> closeEASession([String? protocolString]) =>
      _channel.closeEASession(protocolString);
}

// Handle callbacks from Native to Flutter
class _CallbackHandler extends ExternalAccessoryCallbackChannel {
  @override
  void accessoryConnected(EAAccessory accessory) {
    FlutterAccessoryManagerInterface.accessoryConnected?.call(accessory);
  }

  @override
  void accessoryDisconnected(EAAccessory accessory) {
    FlutterAccessoryManagerInterface.accessoryDisconnected?.call(accessory);
  }
}
