# Flutter Accessory Manager

[![flutter_accessory_manager version](https://img.shields.io/pub/v/flutter_accessory_manager?label=flutter_accessory_manager)](https://pub.dev/packages/flutter_accessory_manager)

A cross-platform (Android/iOS/macOS/Windows/Linux) plugin for managing Bluetooth accessories and HID devices in Flutter.

## Features

- **Unified Cross-Platform API** - Write once, works everywhere. No platform checks needed!
- [Scanning](#scanning) - Works on all platforms (iOS uses picker dialog)
- [Pairing & Unpairing](#pairing--unpairing) - Works on all platforms
- [Connecting](#connecting) - Unified connection API across all platforms
- [HID Reports](#hid-reports) - Available on Android/macOS/Windows
- [SDP Service Registration](#sdp-service-registration) - Available on Android/macOS/Windows
- [iOS External Accessory](#ios-external-accessory) - Integrated into unified API

## API Support

> **✨ Unified API Design:** Core APIs work across all platforms. Platform differences are handled transparently - you write the same code everywhere! APIs marked with ❌ are not supported on those platforms.

|                      | Android | iOS | macOS | Windows | Linux |
| :------------------- | :-----: | :-: | :---: | :-----: | :---: |
| showBluetoothAccessoryPicker |   ✔️    | ✔️  |  ✔️   |   ✔️    | ❌  |
| startScan/stopScan   |   ✔️    | ❌  |  ✔️   |   ✔️    | ✔️  |
| pair/unpair          |   ✔️    | ❌  |  ✔️   |   ✔️    | ✔️  |
| getPairedDevices     |   ✔️    | ❌  |  ✔️   |   ✔️    | ✔️  |
| connect              |   ✔️    | ❌  |  ✔️   |   ✔️    | ✔️* |
| disconnect           |   ✔️    | ✔️* |  ✔️   |   ✔️    | ✔️* |
| sendReport           |   ✔️    | ❌  |  ✔️   |   ✔️    | ❌  |
| setupSdp/closeSdp    |   ✔️    | ❌  |  ✔️   |   ✔️    | ❌  |
| onDeviceDiscovered   |   ✔️    | ❌  |  ✔️   |   ✔️    | ✔️  |
| onDeviceRemoved      |   ✔️    | ❌  |  ✔️   |   ✔️    | ✔️  |
| onConnectionStateChanged |   ✔️    | ❌  |  ✔️   |   ✔️    | ✔️  |
| onGetReport          |   ✔️    | ❌  |  ✔️   |   ✔️    | ❌  |
| onSdpServiceRegistrationUpdate |   ✔️    | ❌  |  ✔️   |   ✔️    | ❌  |

**Platform Implementation Notes:**
- *iOS: `disconnect()` calls `closeEASession()` internally
- *Linux: Basic Bluetooth connection (not HID-specific)

## Getting Started

Add flutter_accessory_manager in your pubspec.yaml:

```yaml
dependencies:
  flutter_accessory_manager:
```

and import it wherever you want to use it:

```dart
import 'package:flutter_accessory_manager/flutter_accessory_manager.dart';
```

## Scanning

### Start Scanning

Start scanning for Bluetooth devices:

```dart
await FlutterAccessoryManager.startScan();
```

> **Platform Support:** Available on Android, macOS, Windows, and Linux. Not available on iOS (throws `UnimplementedError`).

### Stop Scanning

Stop scanning for Bluetooth devices:

```dart
await FlutterAccessoryManager.stopScan();
```

### Check Scanning Status

Check if currently scanning:

```dart
bool isScanning = await FlutterAccessoryManager.isScanning();
```

> **Platform Support:** Available on Android, macOS, Windows, and Linux. Not available on iOS.

### Device Discovery

Listen to discovered devices:

```dart
FlutterAccessoryManager.onDeviceDiscovered = (BluetoothDevice device) {
  print('Device discovered: ${device.name} (${device.address})');
  print('RSSI: ${device.rssi}');
  print('Paired: ${device.paired}');
  print('Device Type: ${device.deviceType}');
  print('Device Class: ${device.deviceClass}');
};
```

> **Platform Support:** Available on Android, macOS, Windows, and Linux. Not available on iOS.

### Device Removed

Listen to device removal events:

```dart
FlutterAccessoryManager.onDeviceRemoved = (BluetoothDevice device) {
  print('Device removed: ${device.name} (${device.address})');
};
```

> **Platform Support:** Available on Android, macOS, Windows, and Linux. Not available on iOS.

### Get Paired Devices

Get a list of all paired devices:

```dart
List<BluetoothDevice> devices = await FlutterAccessoryManager.getPairedDevices();

for (var device in devices) {
  print('Device: ${device.name} - ${device.address}');
}
```

> **Platform Support:** Available on Android, macOS, Windows, and Linux. Not available on iOS (throws `UnimplementedError`).

### Show Bluetooth Accessory Picker

Show the native Bluetooth accessory picker dialog. On iOS, this displays the External Accessory picker.

```dart
await FlutterAccessoryManager.showBluetoothAccessoryPicker();
```

Optionally filter by device names:

```dart
await FlutterAccessoryManager.showBluetoothAccessoryPicker(
  withNames: ['MyDevice', 'AnotherDevice'],
);
```

> **Platform Support:** Available on Android, iOS, macOS, and Windows. Not available on Linux.

## Pairing & Unpairing

### Pair

Pair with a Bluetooth device by its address:

```dart
bool success = await FlutterAccessoryManager.pair('00:11:22:33:44:55');

if (success) {
  print('Device paired successfully');
} else {
  print('Pairing failed');
}
```

> **Platform Support:** Available on Android, macOS, Windows, and Linux. Not available on iOS (throws `UnimplementedError`).

### Unpair

Unpair a Bluetooth device:

```dart
await FlutterAccessoryManager.unpair('00:11:22:33:44:55');
```

> **Platform Support:** Available on Android, macOS, Windows, and Linux. Not available on iOS (throws `UnimplementedError`).

## Connecting

### Connect

Connect to a Bluetooth device:

```dart
await FlutterAccessoryManager.connect('00:11:22:33:44:55');
```

> **Platform Support:** Available on Android, macOS, Windows (HID connection), and Linux (basic Bluetooth connection). Not available on iOS (throws `UnimplementedError`).

### Disconnect

Disconnect from a Bluetooth device. Works on all platforms:

```dart
await FlutterAccessoryManager.disconnect('00:11:22:33:44:55');
```

> **Platform Behavior:**
> - **Android/macOS/Windows:** Disconnects HID connection
> - **iOS:** Closes External Accessory session (calls `closeEASession()` internally)
> - **Linux:** Disconnects basic Bluetooth connection

### Connection State Changes

Listen to connection state changes:

```dart
FlutterAccessoryManager.onConnectionStateChanged = (String deviceId, bool connected) {
  print('Device $deviceId: ${connected ? "connected" : "disconnected"}');
};
```

> **Platform Support:** Available on Android, macOS, Windows, and Linux. Not available on iOS.

## HID Reports

> **Platform Support:** HID operations are available on Android, macOS, and Windows. Not available on iOS or Linux.

### Send Report

Send a HID report to a connected device:

```dart
import 'dart:typed_data';

Uint8List reportData = Uint8List.fromList([0x01, 0x02, 0x03]);
await FlutterAccessoryManager.sendReport('00:11:22:33:44:55', reportData);
```

> **Platform Support:** Available on Android, macOS, and Windows. Not available on iOS or Linux.

### Get Report

Handle HID get report requests:

```dart
import 'dart:typed_data';

FlutterAccessoryManager.onGetReport = (String deviceId, ReportType type, int bufferSize) {
  print('Get report request from $deviceId, type: $type, size: $bufferSize');
  
  // Return a report reply
  return ReportReply(
    data: Uint8List.fromList([0x01, 0x02, 0x03]),
    error: null,
  );
};
```

> **Platform Support:** Available on Android, macOS, and Windows. Not available on iOS or Linux.

## SDP Service Registration

> **Platform Support:** SDP operations are available on Android, macOS, and Windows. Not available on iOS or Linux.

### Setup SDP

Set up the SDP service registration for Bluetooth HID:

```dart
import 'dart:typed_data';

SdpConfig config = SdpConfig(
  macSdpConfig: MacSdpConfig(
    data: {
      'ServiceName': 'My HID Service',
      // ... other SDP data
    },
  ),
  androidSdpConfig: AndroidSdpConfig(
    name: 'My HID Service',
    description: 'HID Service Description',
    provider: 'My Company',
    subclass: 0x2540,
    descriptors: Uint8List.fromList([/* HID descriptors */]),
  ),
);

await FlutterAccessoryManager.setupSdp(config: config);
```

> **Platform Support:** Available on Android, macOS, and Windows. Not available on iOS or Linux.

### Close SDP

Close the SDP service registration:

```dart
await FlutterAccessoryManager.closeSdp();
```

> **Platform Support:** Available on Android, macOS, and Windows. Not available on iOS or Linux.

### SDP Registration Updates

Listen to SDP service registration status changes:

```dart
FlutterAccessoryManager.onSdpServiceRegistrationUpdate = (bool registered) {
  print('SDP service ${registered ? "registered" : "unregistered"}');
};
```

> **Platform Support:** Available on Android, macOS, and Windows. Not available on iOS or Linux.

## iOS External Accessory

> **ℹ️ Unified API:** iOS External Accessory functionality is integrated into the unified API.

### Unified APIs

The following APIs work on iOS through the unified interface:

- `disconnect()` - Calls `closeEASession()` internally on iOS
- `showBluetoothAccessoryPicker()` - Shows the External Accessory picker dialog

### Deprecated APIs

The following iOS-specific callbacks are deprecated. Use the unified callbacks instead:

- `accessoryConnected` callback → Use `onConnectionStateChanged`
- `accessoryDisconnected` callback → Use `onDeviceRemoved` or `onConnectionStateChanged`

> **Note:** `closeEASession()` is still available for direct use if needed, but `disconnect()` is the recommended unified API.

### Accessing iOS-Specific Information

iOS External Accessories are automatically converted to `BluetoothDevice` objects. Access iOS-specific information through the device properties:

```dart
FlutterAccessoryManager.onDeviceDiscovered = (BluetoothDevice device) {
  if (device.isExternalAccessory == true) {
    print('iOS External Accessory: ${device.name}');
    print('Manufacturer: ${device.manufacturer}');
    print('Model: ${device.modelNumber}');
    print('Serial: ${device.serialNumber}');
    print('Protocols: ${device.protocolStrings}');
  }
};
```

## Data Types

### BluetoothDevice

Represents a Bluetooth device. Works on all platforms, including iOS External Accessories:

```dart
BluetoothDevice device = ...;

// Common properties (all platforms)
print('Address: ${device.address}');
print('Name: ${device.name}');
print('Paired: ${device.paired}');
print('Connected with HID: ${device.isConnectedWithHid}');
print('RSSI: ${device.rssi}');
print('Device Type: ${device.deviceType}'); // classic, le, dual, unknown
print('Device Class: ${device.deviceClass}'); // peripheral, audioVideo, etc.

// iOS External Accessory properties (null on other platforms)
if (device.isExternalAccessory == true) {
  print('Manufacturer: ${device.manufacturer}');
  print('Model: ${device.modelNumber}');
  print('Serial: ${device.serialNumber}');
  print('Protocols: ${device.protocolStrings}');
}
```

**Properties:**
- `address` - Device address/identifier (MAC address on most platforms, connection ID on iOS)
- `name` - Device name
- `paired` - Whether device is paired/connected
- `isConnectedWithHid` - Whether connected via HID (null on iOS/Linux)
- `rssi` - Signal strength (0 on iOS, not available for EA)
- `deviceType` - Bluetooth device type (classic, le, dual, unknown)
- `deviceClass` - Device class (peripheral, audioVideo, etc.)
- `isExternalAccessory` - `true` if iOS External Accessory (null on other platforms)
- `manufacturer` - iOS only: Manufacturer name
- `modelNumber` - iOS only: Model number
- `serialNumber` - iOS only: Serial number
- `protocolStrings` - iOS only: List of supported EA protocol strings

### EAAccessory (Deprecated)

> **⚠️ Deprecated:** `EAAccessory` is deprecated. iOS External Accessories are now represented as `BluetoothDevice` objects with `isExternalAccessory == true`. Use the unified `BluetoothDevice` API instead.

### SdpConfig

Configuration for SDP service registration:

```dart
SdpConfig config = SdpConfig(
  macSdpConfig: MacSdpConfig(
    sdpPlistFile: 'path/to/plist', // optional
    data: {
      'ServiceName': 'My Service',
      // ... other SDP data
    },
  ),
  androidSdpConfig: AndroidSdpConfig(
    name: 'My HID Service',
    description: 'Service Description',
    provider: 'My Company',
    subclass: 0x2540,
    descriptors: Uint8List.fromList([/* HID descriptors */]),
  ),
);
```

### ReportReply

Reply to a HID get report request:

```dart
ReportReply reply = ReportReply(
  data: Uint8List.fromList([0x01, 0x02, 0x03]),
  error: null, // null if successful, error code otherwise
);
```

### Enums

#### DeviceType

```dart
enum DeviceType {
  classic,  // Classic Bluetooth
  le,       // Bluetooth Low Energy
  dual,     // Dual mode (Classic + LE)
  unknown,  // Unknown type
}
```

#### DeviceClass

```dart
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
```

#### ReportType

```dart
enum ReportType {
  input,    // Input report
  output,   // Output report
  feature,  // Feature report
}
```

## Platform-Specific Setup

### Android

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" android:maxSdkVersion="28" />
```

Set minimum SDK to 23 in your `build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 23
    }
}
```

You need to programmatically request permissions on runtime. You could use a package such as [permission_handler](https://pub.dev/packages/permission_handler).

For Android 12+, request `Permission.bluetoothScan` and `Permission.bluetoothConnect`.

For Android 11 and below, request `Permission.location`.

### iOS / macOS

Add Bluetooth accessory protocols to your `Info.plist`:

```xml
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.yourcompany.yourapp.protocol</string>
</array>
```

For macOS, add the `Bluetooth` capability to your app from Xcode.

### Windows / Linux

Your Bluetooth adapter needs to support at least Bluetooth 4.0. If you have more than 1 adapter, the first one returned from the system will be picked.

When publishing on Windows, you need to declare the following [capabilities](https://learn.microsoft.com/en-us/windows/uwp/packaging/app-capability-declarations): `bluetooth, radios`.

When publishing on Linux as a snap, you need to declare the `bluez` plug in `snapcraft.yaml`:

```yaml
...
  plugs:
    - bluez
```

## Cross-Platform Usage

### Unified API Design

All APIs work across all platforms. Platform differences are handled transparently:

- **No platform checks needed** - Write the same code everywhere
- **No capability detection** - APIs gracefully handle unsupported operations
- **Unified callbacks** - Single callback for device discovery, connection state, etc.
- **Consistent behavior** - Same API surface on all platforms

### Platform Implementation Details

While the API is unified, platform implementations differ:

**Android/macOS/Windows:**
- Full HID support (connect, sendReport, SDP)
- Standard Bluetooth scanning and pairing
- HID connection state callbacks

**iOS:**
- Uses External Accessory framework (MFi required)
- Only `showBluetoothAccessoryPicker` is supported
- All other APIs throw `UnimplementedError`

**Linux:**
- Basic Bluetooth operations (scan, pair, disconnect)
- HID operations not supported
- No native picker dialog

### Example: Cross-Platform Code

```dart
// Works on Android/macOS/Windows/Linux - iOS only supports showBluetoothAccessoryPicker
FlutterAccessoryManager.onDeviceDiscovered = (BluetoothDevice device) {
  print('Found: ${device.name}');
};

FlutterAccessoryManager.onConnectionStateChanged = (String deviceId, bool connected) {
  print('$deviceId: ${connected ? "connected" : "disconnected"}');
};

// Scan - works on Android/macOS/Windows/Linux
await FlutterAccessoryManager.startScan();

// Get devices - works on Android/macOS/Windows/Linux
List<BluetoothDevice> devices = await FlutterAccessoryManager.getPairedDevices();

// Pair - works on Android/macOS/Windows/Linux
bool paired = await FlutterAccessoryManager.pair(device.address);

// Connect - works on Android/macOS/Windows/Linux
await FlutterAccessoryManager.connect(device.address);

// Send data - available on Android/macOS/Windows only
await FlutterAccessoryManager.sendReport(device.address, data);

// Disconnect - works on all platforms (iOS calls closeEASession internally)
await FlutterAccessoryManager.disconnect(device.address);
```

### Deprecated APIs

The following platform-specific APIs are deprecated and will be removed in a future version:

- `accessoryConnected` / `accessoryDisconnected` → Use `onConnectionStateChanged` or `onDeviceRemoved`
- `onBluetoothDeviceDiscover` → Use `onDeviceDiscovered`
- `onBluetoothDeviceRemoved` → Use `onDeviceRemoved`

> **Note:** `closeEASession()` is still available on iOS for direct use, but `disconnect()` is the recommended unified API that works across all platforms.

## Customizing Platform Implementation

```dart
// Create a class that extends FlutterAccessoryManagerInterface
class FlutterAccessoryManagerMock extends FlutterAccessoryManagerInterface {
  // Implement all methods
}

// Set custom platform specific implementation (e.g. for testing)
FlutterAccessoryManager.setInstance(FlutterAccessoryManagerMock());
```

## 🧩 Apps using Flutter Accessory Manager

Here are some of the apps leveraging the power of `flutter_accessory_manager` in production:

| <img src="assets/bt_cam_icon.svg" alt="BT Cam Icon" width="224" height="224"> | [**BT Cam**](https://btcam.app)<br>A Bluetooth remote app for DSLR and mirrorless cameras. Compatible with Canon, Nikon, Sony, Fujifilm, GoPro, Olympus, Panasonic, Pentax, and Blackmagic. Built using Flutter Accessory Manager to connect and control cameras across iOS, Android, macOS, Windows, Linux & Web. |
|:--:|:--|
> 💡 **Built something cool with Flutter Accessory Manager?**  
> We'd love to showcase your app here!  
> Open a pull request and add it to this section. Please include your app icon in svg!
