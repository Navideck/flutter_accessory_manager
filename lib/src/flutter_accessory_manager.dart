import 'package:flutter_accessory_manager/src/flutter_accessory_manager.g.dart';

class FlutterAccessoryManager {
  static final _channel = FlutterAccessoryPlatformChannel();

  static Function(EAAccessoryObject accessory)? accessoryConnected;
  static Function(EAAccessoryObject accessory)? accessoryDisconnected;
  static Function(BluetoothDevice device)? onDeviceDiscover;

  /// Make sure to call setup once
  static void setup() {
    FlutterAccessoryCallbackChannel.setUp(_CallbackHandler(
      accessoryConnectedCall: (EAAccessoryObject accessory) {
        accessoryConnected?.call(accessory);
      },
      accessoryDisconnectedCall: (EAAccessoryObject accessory) {
        accessoryDisconnected?.call(accessory);
      },
      deviceDiscover: (BluetoothDevice device) {
        onDeviceDiscover?.call(device);
      },
    ));
  }

  static Future<void> showBluetoothAccessoryPicker() =>
      _channel.showBluetoothAccessoryPicker();

  static Future<void> startScan() => _channel.startScan();

  static Future<void> stopScan() => _channel.stopScan();

  static Future<bool> pair(String address) => _channel.pair(address);

  static Future<List<BluetoothDevice>> getPairedDevices() =>
      _channel.getPairedDevices();
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
