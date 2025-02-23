import 'package:pigeon/pigeon.dart';

// dart run pigeon --input pigeon/flutter_accessory_manager.dart
// Generates File for Android, Mac, Windows
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'flutter_accessory_manager',
    dartOut: 'lib/src/generated/flutter_accessory_manager.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/navideck/flutter_accessory_manager/FlutterAccessoryManager.g.kt',
    swiftOut: 'macos/Classes/FlutterAccessoryManager.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOptions:
        KotlinOptions(package: 'com.navideck.flutter_accessory_manager'),
    cppOptions: CppOptions(namespace: 'flutter_accessory_manager'),
    cppHeaderOut: 'windows/FlutterAccessoryManager.g.h',
    cppSourceOut: 'windows/FlutterAccessoryManager.g.cpp',
    debugGenerators: true,
  ),
)

/// Flutter -> Native
@HostApi()
abstract class FlutterAccessoryPlatformChannel {
  @async
  void showBluetoothAccessoryPicker(List<String> withNames);

  void startScan();

  void stopScan();

  bool isScanning();

  List<BluetoothDevice> getPairedDevices();

  @async
  bool pair(String address);

  @async
  void unpair(String address);
}

/// Native -> Flutter
@FlutterApi()
abstract class FlutterAccessoryCallbackChannel {
  void onDeviceDiscover(BluetoothDevice device);

  void onDeviceRemoved(BluetoothDevice device);
}

class BluetoothDevice {
  String address;
  String? name;
  bool paired;
  bool? isConnectedWithHid;
  int rssi;
  DeviceClass? deviceClass;
  DeviceType? deviceType;

  BluetoothDevice({
    required this.address,
    required this.name,
    required this.paired,
    required this.rssi,
  });
}

enum DeviceClass {
  audioVideo,
  computer,
  health,
  imaging,
  misc,
  networking,
  peripheral,
  phone,
  toy,
  uncategorized,
  wearable,
}

enum DeviceType {
  classic,
  le,
  dual,
  unknown,
}
