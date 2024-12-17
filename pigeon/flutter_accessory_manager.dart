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
  void showBluetoothAccessoryPicker(
    List<String> withNames,
  );

  @async
  void connect(String deviceId);

  @async
  void disconnect(String deviceId);

  void setupSdp(SdpConfig config);

  void sendReport(String deviceId, Uint8List data);

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
  void onDeviceDiscover(BluetoothDevice device);

  void onDeviceRemoved(BluetoothDevice device);
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

class SdpConfig {
  MacSdpConfig? macSdpConfig;
  AndroidSdpConfig? androidSdpConfig;

  SdpConfig({
    required this.macSdpConfig,
    required this.androidSdpConfig,
  });
}

class MacSdpConfig {
  String? sdpPlistFile;
  Map<String, Object>? data;

  MacSdpConfig({
    this.data,
  });
}

class AndroidSdpConfig {
  String name;
  String description;
  String provider;
  int subclass;
  Uint8List descriptors;

  AndroidSdpConfig({
    required this.name,
    required this.description,
    required this.provider,
    required this.subclass,
    required this.descriptors,
  });
}
