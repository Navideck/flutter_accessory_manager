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
    return _channel.showBluetoothAccessoryPicker(withNames ?? []);
  }

  @override
  Future<void> closeEaSession(String protocolString) =>
      _channel.closeEaSession(protocolString);
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
