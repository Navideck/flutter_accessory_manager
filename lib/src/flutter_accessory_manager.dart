import 'package:flutter_accessory_manager/src/flutter_accessory_manager.g.dart';

class FlutterAccessoryManager {
  static final _channel = FlutterAccessoryPlatformChannel();

  static void setupCallback({
    required Function(EAAccessoryObject accessory) accessoryConnected,
    required Function(EAAccessoryObject accessory) accessoryDisconnected,
    required Function(BluetoothDevice device) onDeviceDiscover,
  }) {
    FlutterAccessoryCallbackChannel.setUp(_CallbackHandler(
      accessoryConnectedCall: accessoryConnected,
      accessoryDisconnectedCall: accessoryDisconnected,
      deviceDiscover: onDeviceDiscover,
    ));
  }

  static Future<void> showBluetoothAccessoryPicker() =>
      _channel.showBluetoothAccessoryPicker();

  static Future<void> startScan() => _channel.startScan();

  static Future<void> stopScan() => _channel.stopScan();
}

class _CallbackHandler extends FlutterAccessoryCallbackChannel {
  final Function(EAAccessoryObject accessory) accessoryConnectedCall;
  final Function(EAAccessoryObject accessory) accessoryDisconnectedCall;
  final Function(BluetoothDevice device) deviceDiscover;

  _CallbackHandler({
    required this.accessoryConnectedCall,
    required this.accessoryDisconnectedCall,
    required this.deviceDiscover,
  });

  @override
  void accessoryConnected(EAAccessoryObject accessory) {
    accessoryConnectedCall(accessory);
  }

  @override
  void accessoryDisconnected(EAAccessoryObject accessory) {
    accessoryDisconnectedCall(accessory);
  }

  @override
  void onDeviceDiscover(BluetoothDevice device) {
    deviceDiscover(device);
  }
}
