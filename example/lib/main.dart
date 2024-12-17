// ignore_for_file: avoid_print

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
                onPressed: () async {
                  try {
                    await FlutterAccessoryManager.setupSdp(
                      config: SdpConfig(
                        macSdpConfig: MacSdpConfig(
                          sdpPlistFile: "SerialPortDictionary",
                        ),
                        androidSdpConfig: null,
                      ),
                    );
                  } catch (e) {
                    print(e);
                  }
                },
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
