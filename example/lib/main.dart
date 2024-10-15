// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_accessory_manager/flutter_accessory_manager.dart';
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
    FlutterAccessoryManager.setup();

    FlutterAccessoryManager.accessoryConnected = (EAAccessoryObject accessory) {
      print("Accessory Connected ${accessory.name}");
    };

    FlutterAccessoryManager.accessoryDisconnected =
        (EAAccessoryObject accessory) {
      print("Accessory Disconnected ${accessory.name}");
    };

    FlutterAccessoryManager.onDeviceDiscover = (device) {
      print("Device Discover ${device.name} ${device.address}");
      int index = devices.indexWhere((e) => e.address == device.address);
      if (index == -1) {
        devices.add(device);
      } else {
        devices[index] = device;
      }
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

  Future<void> onDeviceSelect(BluetoothDevice device) async {
    try {
      await stopScan();
      print("Pairing");
      bool paired = await FlutterAccessoryManager.pair(device.address);
      print("Pair: $paired");
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
                  print("Closing EaSession");
                  await FlutterAccessoryManager.closeEaSession(
                      "com.nikon.psg-0100");
                  print("Closed EaSession");
                },
                text: "Close EaSession",
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
                return ListTile(
                  title: Text(device.name ?? "N/A"),
                  subtitle: Text(device.address),
                  trailing: Text(device.rssi.toString()),
                  onTap: () => onDeviceSelect(device),
                );
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
