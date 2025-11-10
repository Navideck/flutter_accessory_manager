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
| startScan/stopScan   |   ✔️    | ✔️* |  ✔️   |   ✔️    | ✔️  |
| pair/unpair          |   ✔️    | ✔️* |  ✔️   |   ✔️    | ✔️  |
| getPairedDevices     |   ✔️    | ✔️* |  ✔️   |   ✔️    | ✔️  |
| connect              |   ✔️    | ✔️* |  ✔️   |   ✔️    | ✔️* |
| disconnect           |   ✔️    | ✔️* |  ✔️   |   ✔️    | ✔️* |
| sendReport           |   ✔️    | ❌  |  ✔️   |   ✔️    | ❌  |
| setupSdp/closeSdp    |   ✔️    | ❌  |  ✔️   |   ✔️    | ❌  |
| showBluetoothAccessoryPicker |   ✔️    | ✔️  |  ✔️   |   ✔️    | ❌  |
| onDeviceDiscovered   |   ✔️    | ✔️  |  ✔️   |   ✔️    | ✔️  |
| onDeviceRemoved      |   ✔️    | ✔️  |  ✔️   |   ✔️    | ✔️  |
| onConnectionStateChanged |   ✔️    | ✔️  |  ✔️   |   ✔️    | ✔️  |
| onGetReport          |   ✔️    | ❌  |  ✔️   |   ✔️    | ❌  |
| onSdpServiceRegistrationUpdate |   ✔️    | ❌  |  ✔️   |   ✔️    | ❌  |

**Platform Implementation Notes:**
- *iOS: Uses External Accessory framework (picker-based discovery/pairing, EA sessions for connection)
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

Start scanning for Bluetooth devices. Works on all platforms:

```dart
await FlutterAccessoryManager.startScan();
```

> **Platform Behavior:**
> - **Android/macOS/Windows/Linux:** Starts Bluetooth device discovery
> - **iOS:** Automatically shows the External Accessory picker dialog

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

> **iOS:** Returns `true` while the picker dialog is open

### Device Discovery

Listen to discovered devices. This unified callback works on all platforms:

```dart
FlutterAccessoryManager.onDeviceDiscovered = (BluetoothDevice device) {
  print('Device discovered: ${device.name} (${device.address})');
  print('RSSI: ${device.rssi}');
  print('Paired: ${device.paired}');
  print('Device Type: ${device.deviceType}');
  print('Device Class: ${device.deviceClass}');
  
  // Check if iOS External Accessory
  if (device.isExternalAccessory == true) {
    print('iOS External Accessory');
    print('Manufacturer: ${device.manufacturer}');
    print('Protocols: ${device.protocolStrings}');
  }
};
```

> **Platform Behavior:**
> - **Android/macOS/Windows/Linux:** Triggered when devices are discovered during scan
> - **iOS:** Triggered when user selects a device from the picker (automatically shown by `startScan()`)

### Device Removed

Listen to device removal events. Works on all platforms:

```dart
FlutterAccessoryManager.onDeviceRemoved = (BluetoothDevice device) {
  print('Device removed: ${device.name} (${device.address})');
};
```

> **Platform Behavior:**
> - **Android/macOS/Windows/Linux:** Triggered when device is removed from range
> - **iOS:** Triggered when External Accessory disconnects

### Get Paired Devices

Get a list of all paired/connected devices. Works on all platforms:

```dart
List<BluetoothDevice> devices = await FlutterAccessoryManager.getPairedDevices();

for (var device in devices) {
  print('Device: ${device.name} - ${device.address}');
  if (device.isExternalAccessory == true) {
    print('  iOS External Accessory');
  }
}
```

> **Platform Behavior:**
> - **Android/macOS/Windows/Linux:** Returns list of paired Bluetooth devices
> - **iOS:** Returns list of connected External Accessories (converted to `BluetoothDevice`)

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

> **Note:** Not available on Linux. On iOS, `startScan()` automatically shows the picker, so you typically don't need to call this directly.

## Pairing & Unpairing

### Pair

Pair with a Bluetooth device by its address. Works on all platforms:

```dart
bool success = await FlutterAccessoryManager.pair('00:11:22:33:44:55');

if (success) {
  print('Device paired successfully');
} else {
  print('Pairing failed');
}
```

> **Platform Behavior:**
> - **Android/macOS/Windows/Linux:** Standard Bluetooth pairing
> - **iOS:** If device is already connected via External Accessory, returns `true`. Otherwise, shows picker dialog and waits for user selection

### Unpair

Unpair a Bluetooth device. Works on all platforms:

```dart
await FlutterAccessoryManager.unpair('00:11:22:33:44:55');
```

> **iOS:** Disconnects the External Accessory if connected

## Connecting

### Connect

Connect to a Bluetooth device. Works on all platforms:

```dart
await FlutterAccessoryManager.connect('00:11:22:33:44:55');
```

> **Platform Behavior:**
> - **Android/macOS/Windows:** Establishes HID connection
> - **iOS:** Opens External Accessory session (if device not found, shows picker first)
> - **Linux:** Establishes basic Bluetooth connection (if supported)

### Disconnect

Disconnect from a Bluetooth device. Works on all platforms:

```dart
await FlutterAccessoryManager.disconnect('00:11:22:33:44:55');
```

> **Platform Behavior:**
> - **Android/macOS/Windows:** Disconnects HID connection
> - **iOS:** Closes External Accessory session
> - **Linux:** Disconnects basic Bluetooth connection

### Connection State Changes

Listen to connection state changes. This unified callback works on all platforms:

```dart
FlutterAccessoryManager.onConnectionStateChanged = (String deviceId, bool connected) {
  print('Device $deviceId: ${connected ? "connected" : "disconnected"}');
};
```

> **Platform Behavior:**
> - **Android/macOS/Windows:** Triggered on HID connection state changes
> - **iOS:** Triggered when External Accessory connects/disconnects
> - **Linux:** Triggered on basic Bluetooth connection state changes

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

> **ℹ️ Unified API:** iOS External Accessory functionality is now integrated into the unified API. The following deprecated APIs are still available for backward compatibility but will be removed in a future version.

### Deprecated APIs

The following iOS-specific APIs are deprecated. Use the unified APIs instead:

- `closeEASession()` → Use `disconnect()`
- `accessoryConnected` callback → Use `onConnectionStateChanged`
- `accessoryDisconnected` callback → Use `onDeviceRemoved` or `onConnectionStateChanged`

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
- `startScan()` automatically shows picker dialog
- `pair()` and `connect()` show picker if device not found
- External Accessories converted to `BluetoothDevice` automatically
- HID operations not supported

**Linux:**
- Basic Bluetooth operations (scan, pair, disconnect)
- HID operations not supported
- No native picker dialog

### Example: Cross-Platform Code

```dart
// Works on all platforms - no platform checks needed!
FlutterAccessoryManager.onDeviceDiscovered = (BluetoothDevice device) {
  print('Found: ${device.name}');
};

FlutterAccessoryManager.onConnectionStateChanged = (String deviceId, bool connected) {
  print('$deviceId: ${connected ? "connected" : "disconnected"}');
};

// Scan - works everywhere
await FlutterAccessoryManager.startScan();

// Get devices - works everywhere
List<BluetoothDevice> devices = await FlutterAccessoryManager.getPairedDevices();

// Pair - works everywhere
bool paired = await FlutterAccessoryManager.pair(device.address);

// Connect - works everywhere
await FlutterAccessoryManager.connect(device.address);

// Send data - available on Android/macOS/Windows only
await FlutterAccessoryManager.sendReport(device.address, data);

// Disconnect - works everywhere
await FlutterAccessoryManager.disconnect(device.address);
```

### Deprecated APIs

The following platform-specific APIs are deprecated and will be removed in a future version:

- `closeEASession()` → Use `disconnect()`
- `accessoryConnected` / `accessoryDisconnected` → Use `onConnectionStateChanged` or `onDeviceRemoved`
- `onBluetoothDeviceDiscover` → Use `onDeviceDiscovered`
- `onBluetoothDeviceRemoved` → Use `onDeviceRemoved`

## Customizing Platform Implementation

```dart
// Create a class that extends FlutterAccessoryManagerInterface
class FlutterAccessoryManagerMock extends FlutterAccessoryManagerInterface {
  // Implement all methods
}

// Set custom platform specific implementation (e.g. for testing)
FlutterAccessoryManager.setInstance(FlutterAccessoryManagerMock());
```
<<<<<<< HEAD

## 🧩 Apps using Flutter Accessory Manager

Here are some of the apps leveraging the power of `flutter_accessory_manager` in production:

| <img src="assets/bt_cam_icon.svg" alt="BT Cam Icon" width="224" height="224"> | [**BT Cam**](https://btcam.app)<br>A Bluetooth remote app for DSLR and mirrorless cameras. Compatible with Canon, Nikon, Sony, Fujifilm, GoPro, Olympus, Panasonic, Pentax, and Blackmagic. Built using Flutter Accessory Manager to connect and control cameras across iOS, Android, macOS, Windows, Linux & Web. |
|:--:|:--|
> 💡 **Built something cool with Flutter Accessory Manager?**  
> We'd love to showcase your app here!  
> Open a pull request and add it to this section. Please include your app icon in svg!
=======
>>>>>>> 274eb2b (Update readme)
