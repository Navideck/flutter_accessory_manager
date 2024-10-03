import 'package:flutter_accessory_manager/src/flutter_accessory_manager.g.dart';

class FlutterAccessoryManager {
  static final _channel = FlutterAccessoryPlatformChannel();

  static void setupCallback({
    required Function(EAAccessoryObject accessory) accessoryConnected,
    required Function(EAAccessoryObject accessory) accessoryDisconnected,
  }) {
    FlutterAccessoryCallbackChannel.setUp(_CallbackHandler(
      accessoryConnectedCall: accessoryConnected,
      accessoryDisconnectedCall: accessoryDisconnected,
    ));
  }

  static Future<void> showBluetoothAccessoryPicker() =>
      _channel.showBluetoothAccessoryPicker();
}

class _CallbackHandler extends FlutterAccessoryCallbackChannel {
  final Function(EAAccessoryObject accessory) accessoryConnectedCall;
  final Function(EAAccessoryObject accessory) accessoryDisconnectedCall;
  _CallbackHandler({
    required this.accessoryConnectedCall,
    required this.accessoryDisconnectedCall,
  });

  @override
  void accessoryConnected(EAAccessoryObject accessory) {
    accessoryConnectedCall(accessory);
  }

  @override
  void accessoryDisconnected(EAAccessoryObject accessory) {
    accessoryDisconnectedCall(accessory);
  }
}
