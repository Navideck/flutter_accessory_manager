import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_accessory_manager/flutter_accessory_manager.dart';
import 'package:flutter_accessory_manager_example/global_widgets.dart';

class BluetoothDeviceItem extends StatelessWidget {
  final BluetoothDevice device;
  const BluetoothDeviceItem(this.device, {super.key});

  Future<void> pairDevice() async {
    try {
      print("Pairing");
      bool paired = await FlutterAccessoryManager.pair(device.address);
      print("Pair: $paired");
    } catch (e) {
      print(e);
    }
  }

  Future<void> disconnect() async {
    print("Disconnecting");
    await FlutterAccessoryManager.disconnect(device.address);
    print("Disconnected");
  }

  Future<void> connect() async {
    await FlutterAccessoryManager.connect(device.address);
  }

  Future<void> sendReport() async {
    await sendVolumeUpMacReport();
  }

  Future<void> sendVolumeUpMacReport() async {
    await FlutterAccessoryManager.sendReport(
      device.address,
      Uint8List.fromList(macHidReport(128, 0)), // VolumeUp button down
    );
    await Future.delayed(const Duration(milliseconds: 200));
    await FlutterAccessoryManager.sendReport(
      device.address,
      Uint8List.fromList(macHidReport(0, 0)), // VolumeUp button up
    );
  }

  List<int> macHidReport(int keyCode, int modifier) {
    return [
      0xA1, // 0 DATA | INPUT (HIDP Bluetooth)
      0x01, // 0 Report ID
      modifier, // 1 Modifier Keys
      0x00, // 2 Reserved
      keyCode, // 3 Keys ( 6 keys can be held at the same time )
      0x00, // 4
      0x00, // 5
      0x00, // 6
      0x00, // 7
      0x00, // 8
      0x00, // 9
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(device.name ?? "N/A"),
          subtitle: Text(device.address),
          trailing: Text(device.rssi.toString()),
        ),
        ResponsiveButtonsGrid(
          children: [
            PlatformButton(
              onPressed: pairDevice,
              text: "Pair",
            ),
            PlatformButton(
              onPressed: connect,
              text: "Connect",
            ),
            PlatformButton(
              onPressed: disconnect,
              text: "Disconnect",
            ),
            PlatformButton(
              onPressed: sendReport,
              text: "Send Report",
            ),
          ],
        )
      ],
    );
  }
}
