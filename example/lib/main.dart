// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_accessory_manager/flutter_accessory_manager.dart';
import 'package:flutter_accessory_manager_example/bluetooth_device.dart';
import 'package:flutter_accessory_manager_example/global_widgets.dart';
import 'package:flutter_accessory_manager_example/permission_handler.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<BluetoothDevice> devices = [];
  bool isScanning = false;

  @override
  void initState() {
    FlutterAccessoryManager.accessoryConnected = (EAAccessory accessory) {
      print("Accessory Connected ${accessory.name}");
    };

    FlutterAccessoryManager.accessoryDisconnected = (EAAccessory accessory) {
      print("Accessory Disconnected ${accessory.name}");
    };

    FlutterAccessoryManager.onBluetoothDeviceDiscover = (device) {
      print("Device Discover ${device.name} ${device.address}");
      int index = devices.indexWhere((e) => e.address == device.address);
      if (index == -1) {
        devices.add(device);
      } else {
        devices[index] = device;
      }
      setState(() {});
    };

    FlutterAccessoryManager.onBluetoothDeviceRemoved = (device) {
      print("Device Removed ${device.name} ${device.address}");
      devices.removeWhere((e) => e.address == device.address);
      setState(() {});
    };

    super.initState();
  }

  void showSnackbar(message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.toString())),
    );
  }

  Future<void> startScan() async {
    setState(() {
      devices.clear();
      isScanning = true;
    });
    try {
      await FlutterAccessoryManager.startScan();
    } catch (e) {
      print(e);

      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> stopScan() async {
    setState(() {
      isScanning = false;
    });
    try {
      await FlutterAccessoryManager.stopScan();
    } catch (e) {
      print(e);
      setState(() {
        isScanning = true;
      });
    }
  }

  Future<void> getPairedDevices() async {
    try {
      var devices = await FlutterAccessoryManager.getPairedDevices();
      print(devices.map((e) => "${e.address} ${e.name}"));
    } catch (e) {
      print(e);
    }
  }

  Future<void> setupSdp() async {
    try {
      await FlutterAccessoryManager.setupSdp(
        config: SdpConfig(
          macSdpConfig: MacSdpConfig(
            sdpPlistFile: "SerialPortDictionary",
          ),
          androidSdpConfig: AndroidSdpConfig(
            name: "BlueHID",
            description: "Android HID",
            provider: "Android",
            subclass: 0x00,
            descriptors: Uint8List.fromList(androidDescriptor),
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  final List<int> androidDescriptor = [
    0x05, 0x0C, // Usage Page (Consumer)
    0x09, 0x01, // Usage (Consumer Control)
    0xA1, 0x01, // Collection (Application)
    0x85, 0x01, //   Report ID (1)
    0x19, 0x00, //   Usage Minimum (Unassigned)
    0x2A, 0x3C, 0x02, //   Usage Maximum (AC Format)
    0x15, 0x00, //   Logical Minimum (0)
    0x26, 0x3C, 0x02, //   Logical Maximum (572)
    0x95, 0x01, //   Report Count (1)
    0x75, 0x10, //   Report Size (16)
    0x81, 0x00, //   Input (Data,Array)
    0xC0, // End Collection
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterAccessoryManager'),
        actions: [
          if (isScanning)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator.adaptive(),
            ),
        ],
      ),
      body: Column(
        children: [
          ResponsiveButtonsGrid(
            children: [
              PlatformButton(
                onPressed: setupSdp,
                text: "SetupSdp",
              ),
              PlatformButton(
                onPressed: () async {
                  try {
                    print("Opening Picker");
                    await FlutterAccessoryManager
                        .showBluetoothAccessoryPicker();
                    print("showed BluetoothAccessoryPicker");
                  } catch (e) {
                    print(e);
                  }
                },
                text: "ShowBluetoothAccessoryPicker",
              ),
              PlatformButton(
                onPressed: () async {
                  print("Closing EASession");
                  await FlutterAccessoryManager.closeEASession();
                  print("Closed EASession");
                },
                text: "Close EASession",
              ),
              PlatformButton(
                text: "Check Permissions",
                onPressed: () async {
                  bool hasPermissions =
                      await PermissionHandler.arePermissionsGranted();
                  if (hasPermissions) {
                    showSnackbar("Permissions granted");
                  }
                },
              ),
              PlatformButton(
                onPressed: startScan,
                text: "Start Scan",
              ),
              PlatformButton(
                onPressed: stopScan,
                text: "Stop Scan",
              ),
              PlatformButton(
                onPressed: () async {
                  try {
                    bool scanning = await FlutterAccessoryManager.isScanning();
                    print("Scanning: $scanning");
                  } catch (e) {
                    print(e);
                  }
                },
                text: "IsScanning",
              ),
              PlatformButton(
                onPressed: () async {
                  try {
                    devices.clear();
                    devices.addAll(
                      await FlutterAccessoryManager.getPairedDevices(),
                    );
                    print(devices.map((e) => "${e.address} ${e.name}"));
                    setState(() {});
                  } catch (e) {
                    print(e);
                  }
                },
                text: "Get Paired",
              ),
              PlatformButton(
                onPressed: () {
                  setState(() {
                    devices.clear();
                  });
                },
                text: "Clear List",
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              itemCount: devices.length,
              itemBuilder: (BuildContext context, int index) {
                BluetoothDevice device = devices[index];
                return BluetoothDeviceItem(device);
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider();
              },
            ),
          )
        ],
      ),
    );
  }
}
