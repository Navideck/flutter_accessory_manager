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
          const Text("Android"),
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
                    await FlutterAccessoryManager
                        .showBluetoothAccessoryPicker();
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Text("Start Scan"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FlutterAccessoryManager
                        .showBluetoothAccessoryPicker();
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Text("Stop Scan"),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(devices[index].name ?? "N/A"),
                  subtitle: Text(devices[index].address),
                  trailing: Text(devices[index].rssi.toString()),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
