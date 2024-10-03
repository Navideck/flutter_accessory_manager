// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_accessory_manager/flutter_accessory_manager.dart';

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
  @override
  void initState() {
    FlutterAccessoryManager.setupCallback(
      accessoryConnected: (EAAccessoryObject accessory) {
        print("Accessory Connected ${accessory.name}");
      },
      accessoryDisconnected: (EAAccessoryObject accessory) {
        print("Accessory Disconnected ${accessory.name}");
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterAccessoryManager'),
      ),
      body: Center(
        child: ElevatedButton(
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
      ),
    );
  }
}
