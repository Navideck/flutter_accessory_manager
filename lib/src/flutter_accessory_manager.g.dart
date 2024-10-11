// Autogenerated from Pigeon (v22.4.2), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

PlatformException _createConnectionError(String channelName) {
  return PlatformException(
    code: 'channel-error',
    message: 'Unable to establish connection on channel: "$channelName".',
  );
}

List<Object?> wrapResponse({Object? result, PlatformException? error, bool empty = false}) {
  if (empty) {
    return <Object?>[];
  }
  if (error == null) {
    return <Object?>[result];
  }
  return <Object?>[error.code, error.message, error.details];
}

class BluetoothDevice {
  BluetoothDevice({
    required this.address,
    this.name,
    required this.paired,
    required this.rssi,
  });

  String address;

  String? name;

  bool paired;

  int rssi;

  Object encode() {
    return <Object?>[
      address,
      name,
      paired,
      rssi,
    ];
  }

  static BluetoothDevice decode(Object result) {
    result as List<Object?>;
    return BluetoothDevice(
      address: result[0]! as String,
      name: result[1] as String?,
      paired: result[2]! as bool,
      rssi: result[3]! as int,
    );
  }
}

class EAAccessoryObject {
  EAAccessoryObject({
    required this.isConnected,
    required this.connectionID,
    required this.manufacturer,
    required this.name,
    required this.modelNumber,
    required this.serialNumber,
    required this.firmwareRevision,
    required this.hardwareRevision,
    required this.dockType,
    required this.protocolStrings,
  });

  bool isConnected;

  int connectionID;

  String manufacturer;

  String name;

  String modelNumber;

  String serialNumber;

  String firmwareRevision;

  String hardwareRevision;

  String dockType;

  List<String> protocolStrings;

  Object encode() {
    return <Object?>[
      isConnected,
      connectionID,
      manufacturer,
      name,
      modelNumber,
      serialNumber,
      firmwareRevision,
      hardwareRevision,
      dockType,
      protocolStrings,
    ];
  }

  static EAAccessoryObject decode(Object result) {
    result as List<Object?>;
    return EAAccessoryObject(
      isConnected: result[0]! as bool,
      connectionID: result[1]! as int,
      manufacturer: result[2]! as String,
      name: result[3]! as String,
      modelNumber: result[4]! as String,
      serialNumber: result[5]! as String,
      firmwareRevision: result[6]! as String,
      hardwareRevision: result[7]! as String,
      dockType: result[8]! as String,
      protocolStrings: (result[9] as List<Object?>?)!.cast<String>(),
    );
  }
}


class _PigeonCodec extends StandardMessageCodec {
  const _PigeonCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is int) {
      buffer.putUint8(4);
      buffer.putInt64(value);
    }    else if (value is BluetoothDevice) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    }    else if (value is EAAccessoryObject) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 129: 
        return BluetoothDevice.decode(readValue(buffer)!);
      case 130: 
        return EAAccessoryObject.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

/// Flutter -> Native
class FlutterAccessoryPlatformChannel {
  /// Constructor for [FlutterAccessoryPlatformChannel].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  FlutterAccessoryPlatformChannel({BinaryMessenger? binaryMessenger, String messageChannelSuffix = ''})
      : pigeonVar_binaryMessenger = binaryMessenger,
        pigeonVar_messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
  final BinaryMessenger? pigeonVar_binaryMessenger;

  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  final String pigeonVar_messageChannelSuffix;

  Future<void> showBluetoothAccessoryPicker() async {
    final String pigeonVar_channelName = 'dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.showBluetoothAccessoryPicker$pigeonVar_messageChannelSuffix';
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(null) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> startScan() async {
    final String pigeonVar_channelName = 'dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.startScan$pigeonVar_messageChannelSuffix';
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(null) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> stopScan() async {
    final String pigeonVar_channelName = 'dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.stopScan$pigeonVar_messageChannelSuffix';
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(null) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else {
      return;
    }
  }

  Future<bool> isScanning() async {
    final String pigeonVar_channelName = 'dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.isScanning$pigeonVar_messageChannelSuffix';
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(null) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else if (pigeonVar_replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (pigeonVar_replyList[0] as bool?)!;
    }
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    final String pigeonVar_channelName = 'dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.getPairedDevices$pigeonVar_messageChannelSuffix';
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(null) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else if (pigeonVar_replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (pigeonVar_replyList[0] as List<Object?>?)!.cast<BluetoothDevice>();
    }
  }

  Future<bool> pair(String address) async {
    final String pigeonVar_channelName = 'dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.pair$pigeonVar_messageChannelSuffix';
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(<Object?>[address]) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else if (pigeonVar_replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (pigeonVar_replyList[0] as bool?)!;
    }
  }
}

/// Native -> Flutter
abstract class FlutterAccessoryCallbackChannel {
  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  void accessoryConnected(EAAccessoryObject accessory);

  void accessoryDisconnected(EAAccessoryObject accessory);

  void onDeviceDiscover(BluetoothDevice device);

  static void setUp(FlutterAccessoryCallbackChannel? api, {BinaryMessenger? binaryMessenger, String messageChannelSuffix = '',}) {
    messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.accessoryConnected$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.accessoryConnected was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final EAAccessoryObject? arg_accessory = (args[0] as EAAccessoryObject?);
          assert(arg_accessory != null,
              'Argument for dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.accessoryConnected was null, expected non-null EAAccessoryObject.');
          try {
            api.accessoryConnected(arg_accessory!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.accessoryDisconnected$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.accessoryDisconnected was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final EAAccessoryObject? arg_accessory = (args[0] as EAAccessoryObject?);
          assert(arg_accessory != null,
              'Argument for dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.accessoryDisconnected was null, expected non-null EAAccessoryObject.');
          try {
            api.accessoryDisconnected(arg_accessory!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.onDeviceDiscover$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.onDeviceDiscover was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final BluetoothDevice? arg_device = (args[0] as BluetoothDevice?);
          assert(arg_device != null,
              'Argument for dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.onDeviceDiscover was null, expected non-null BluetoothDevice.');
          try {
            api.onDeviceDiscover(arg_device!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
  }
}
