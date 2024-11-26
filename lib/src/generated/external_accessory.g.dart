// Autogenerated from Pigeon (v22.6.2), do not edit directly.
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

class EAAccessory {
  EAAccessory({
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

  static EAAccessory decode(Object result) {
    result as List<Object?>;
    return EAAccessory(
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
    }    else if (value is EAAccessory) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 129: 
        return EAAccessory.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

/// Flutter -> Native
class ExternalAccessoryChannel {
  /// Constructor for [ExternalAccessoryChannel].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  ExternalAccessoryChannel({BinaryMessenger? binaryMessenger, String messageChannelSuffix = ''})
      : pigeonVar_binaryMessenger = binaryMessenger,
        pigeonVar_messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
  final BinaryMessenger? pigeonVar_binaryMessenger;

  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  final String pigeonVar_messageChannelSuffix;

  Future<void> showBluetoothAccessoryPicker(List<String> withNames) async {
    final String pigeonVar_channelName = 'dev.flutter.pigeon.flutter_accessory_manager.ExternalAccessoryChannel.showBluetoothAccessoryPicker$pigeonVar_messageChannelSuffix';
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(<Object?>[withNames]) as List<Object?>?;
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

  Future<void> closeEaSession(String? protocolString) async {
    final String pigeonVar_channelName = 'dev.flutter.pigeon.flutter_accessory_manager.ExternalAccessoryChannel.closeEaSession$pigeonVar_messageChannelSuffix';
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(<Object?>[protocolString]) as List<Object?>?;
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
}

/// Native -> Flutter
abstract class ExternalAccessoryCallbackChannel {
  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  void accessoryConnected(EAAccessory accessory);

  void accessoryDisconnected(EAAccessory accessory);

  static void setUp(ExternalAccessoryCallbackChannel? api, {BinaryMessenger? binaryMessenger, String messageChannelSuffix = '',}) {
    messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.flutter_accessory_manager.ExternalAccessoryCallbackChannel.accessoryConnected$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.flutter_accessory_manager.ExternalAccessoryCallbackChannel.accessoryConnected was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final EAAccessory? arg_accessory = (args[0] as EAAccessory?);
          assert(arg_accessory != null,
              'Argument for dev.flutter.pigeon.flutter_accessory_manager.ExternalAccessoryCallbackChannel.accessoryConnected was null, expected non-null EAAccessory.');
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
          'dev.flutter.pigeon.flutter_accessory_manager.ExternalAccessoryCallbackChannel.accessoryDisconnected$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.flutter_accessory_manager.ExternalAccessoryCallbackChannel.accessoryDisconnected was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final EAAccessory? arg_accessory = (args[0] as EAAccessory?);
          assert(arg_accessory != null,
              'Argument for dev.flutter.pigeon.flutter_accessory_manager.ExternalAccessoryCallbackChannel.accessoryDisconnected was null, expected non-null EAAccessory.');
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
  }
}
