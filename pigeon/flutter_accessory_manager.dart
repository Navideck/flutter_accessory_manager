import 'package:pigeon/pigeon.dart';

// dart run pigeon --input pigeon/flutter_accessory_manager.dart
// To create Macos/Ios symlinks,
// Navigate to directories, eg: cd macos/Classes, and run
// ln -s ../../darwin/FlutterAccessoryManager.g.swift FlutterAccessoryManager.g.swift
// ln -s ../../darwin/FlutterAccessoryManager.g.swift FlutterAccessoryManager.g.swift
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'flutter_accessory_manager',
    dartOut: 'lib/src/flutter_accessory_manager.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/navideck/flutter_accessory_manager/FlutterAccessoryManager.g.kt',
    swiftOut: 'darwin/FlutterAccessoryManager.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOptions:
        KotlinOptions(package: 'com.navideck.flutter_accessory_manager'),
    cppOptions: CppOptions(namespace: 'flutter_accessory_manager'),
    cppHeaderOut: 'windows/FlutterAccessoryManager.g.h',
    cppSourceOut: 'windows/FlutterAccessoryManager.g.cpp',
    gobjectHeaderOut: 'linux/FlutterAccessoryManager.g.h',
    gobjectSourceOut: 'linux/FlutterAccessoryManager.g.cc',
    gobjectOptions: GObjectOptions(),
    debugGenerators: true,
  ),
)

/// Flutter -> Native
@HostApi()
abstract class FlutterAccessoryPlatformChannel {
  @async
  void showBluetoothAccessoryPicker();

  @async
  void closeEaSession(String protocolString);

  void startScan();

  void stopScan();

  bool isScanning();

  List<BluetoothDevice> getPairedDevices();

  @async
  bool pair(String address);
}

/// Native -> Flutter
@FlutterApi()
abstract class FlutterAccessoryCallbackChannel {
  void accessoryConnected(EAAccessoryObject accessory);

  void accessoryDisconnected(EAAccessoryObject accessory);

  void onDeviceDiscover(BluetoothDevice device);
}

class BluetoothDevice {
  String address;
  String? name;
  bool paired;
  int rssi;

  BluetoothDevice({
    required this.address,
    required this.name,
    required this.paired,
    required this.rssi,
  });
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
