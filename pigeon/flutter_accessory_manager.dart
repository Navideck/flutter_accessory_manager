import 'package:pigeon/pigeon.dart';

// dart run pigeon --input pigeon/flutter_accessory_manager.dart
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'flutter_accessory_manager',
    dartOut: 'lib/src/flutter_accessory_manager.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Classes/FlutterAccessoryManager.g.swift',
    swiftOptions: SwiftOptions(),
    debugGenerators: true,
  ),
)

/// Flutter -> Native
@HostApi()
abstract class FlutterAccessoryPlatformChannel {
  @async
  void showBluetoothAccessoryPicker();
}

/// Native -> Flutter
@FlutterApi()
abstract class FlutterAccessoryCallbackChannel {
  void accessoryConnected(EAAccessoryObject accessory);

  void accessoryDisconnected(EAAccessoryObject accessory);
}

class EAAccessoryObject {
  final bool isConnected;
  final int connectionID;
  final String manufacturer;
  final String name;
  final String modelNumber;
  final String serialNumber;
  final String firmwareRevision;
  final String hardwareRevision;
  final String dockType;
  final List<String> protocolStrings;

  EAAccessoryObject({
    required this.isConnected,
    required this.connectionID,
    required this.manufacturer,
    required this.name,
    required this.modelNumber,
    required this.serialNumber,
    required this.firmwareRevision,
    required this.hardwareRevision,
    required this.dockType,
    required this.protocolStrings,
  });
}
