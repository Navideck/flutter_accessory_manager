// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_accessory_manager/flutter_accessory_manager.dart';
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

  @override
  void initState() {
    FlutterAccessoryManager.setupCallback(
      accessoryConnected: (EAAccessoryObject accessory) {
        print("Accessory Connected ${accessory.name}");
      },
      accessoryDisconnected: (EAAccessoryObject accessory) {
        print("Accessory Disconnected ${accessory.name}");
      },
      onDeviceDiscover: (device) {
        print("Device Discover ${device.name} ${device.address}");
        int index = devices.indexWhere((e) => e.address == device.address);
        if (index == -1) {
          devices.add(device);
        } else {
          devices[index] = device;
        }
        setState(() {});
      },
    );
    super.initState();
  }

  void showSnackbar(message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterAccessoryManager'),
      ),
      body: Column(
        children: [
          const Text("IOS"),
          ElevatedButton(
            onPressed: () async {
              try {
                await FlutterAccessoryManager.showBluetoothAccessoryPicker();
                print("showBluetoothAccessoryPicker");
              } catch (e) {
                print(e);
              }
            },
            child: const Text("ShowBluetoothAccessoryPicker"),
          ),
          const Divider(),
          const Text("Android/MacOs"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                child: const Text("Check Permissions"),
                onPressed: () async {
                  bool hasPermissions =
                      await PermissionHandler.arePermissionsGranted();
                  if (hasPermissions) {
                    showSnackbar("Permissions granted");
                  }
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FlutterAccessoryManager.startScan();
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Text("Start Scan"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FlutterAccessoryManager.stopScan();
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Text("Stop Scan"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    var devices =
                        await FlutterAccessoryManager.getPairedDevices();
                    print(devices.map((e) => "${e.address} ${e.name}"));
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Text("Get Paired"),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (BuildContext context, int index) {
                BluetoothDevice device = devices[index];
                return ListTile(
                  title: Text(device.name ?? "N/A"),
                  subtitle: Text(device.address),
                  trailing: Text(device.rssi.toString()),
                  onTap: () async {
                    try {
                      print("Pairing");
                      await FlutterAccessoryManager.pair(device.address);
                      print("Pairing called");
                    } catch (e) {
                      print(e);
                    }
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
