// Autogenerated from Pigeon (v22.4.2), do not edit directly.
// See also: https://pub.dev/packages/pigeon

import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#else
  #error("Unsupported platform.")
#endif

/// Error class for passing custom error details to Dart side.
final class PigeonError: Error {
  let code: String
  let message: String?
  let details: Any?

  init(code: String, message: String?, details: Any?) {
    self.code = code
    self.message = message
    self.details = details
  }

  var localizedDescription: String {
    return
      "PigeonError(code: \(code), message: \(message ?? "<nil>"), details: \(details ?? "<nil>")"
      }
}

private func wrapResult(_ result: Any?) -> [Any?] {
  return [result]
}

private func wrapError(_ error: Any) -> [Any?] {
  if let pigeonError = error as? PigeonError {
    return [
      pigeonError.code,
      pigeonError.message,
      pigeonError.details,
    ]
  }
  if let flutterError = error as? FlutterError {
    return [
      flutterError.code,
      flutterError.message,
      flutterError.details,
    ]
  }
  return [
    "\(error)",
    "\(type(of: error))",
    "Stacktrace: \(Thread.callStackSymbols)",
  ]
}

private func createConnectionError(withChannelName channelName: String) -> PigeonError {
  return PigeonError(code: "channel-error", message: "Unable to establish connection on channel: '\(channelName)'.", details: "")
}

private func isNullish(_ value: Any?) -> Bool {
  return value is NSNull || value == nil
}

private func nilOrValue<T>(_ value: Any?) -> T? {
  if value is NSNull { return nil }
  return value as! T?
}

/// Generated class from Pigeon that represents data sent in messages.
struct BluetoothDevice {
  var address: String
  var name: String? = nil
  var paired: Bool
  var rssi: Int64



  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> BluetoothDevice? {
    let address = pigeonVar_list[0] as! String
    let name: String? = nilOrValue(pigeonVar_list[1])
    let paired = pigeonVar_list[2] as! Bool
    let rssi = pigeonVar_list[3] as! Int64

    return BluetoothDevice(
      address: address,
      name: name,
      paired: paired,
      rssi: rssi
    )
  }
  func toList() -> [Any?] {
    return [
      address,
      name,
      paired,
      rssi,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct EAAccessoryObject {
  var isConnected: Bool
  var connectionID: Int64
  var manufacturer: String
  var name: String
  var modelNumber: String
  var serialNumber: String
  var firmwareRevision: String
  var hardwareRevision: String
  var dockType: String
  var protocolStrings: [String]



  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> EAAccessoryObject? {
    let isConnected = pigeonVar_list[0] as! Bool
    let connectionID = pigeonVar_list[1] as! Int64
    let manufacturer = pigeonVar_list[2] as! String
    let name = pigeonVar_list[3] as! String
    let modelNumber = pigeonVar_list[4] as! String
    let serialNumber = pigeonVar_list[5] as! String
    let firmwareRevision = pigeonVar_list[6] as! String
    let hardwareRevision = pigeonVar_list[7] as! String
    let dockType = pigeonVar_list[8] as! String
    let protocolStrings = pigeonVar_list[9] as! [String]

    return EAAccessoryObject(
      isConnected: isConnected,
      connectionID: connectionID,
      manufacturer: manufacturer,
      name: name,
      modelNumber: modelNumber,
      serialNumber: serialNumber,
      firmwareRevision: firmwareRevision,
      hardwareRevision: hardwareRevision,
      dockType: dockType,
      protocolStrings: protocolStrings
    )
  }
  func toList() -> [Any?] {
    return [
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
    ]
  }
}

private class FlutterAccessoryManagerPigeonCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    switch type {
    case 129:
      return BluetoothDevice.fromList(self.readValue() as! [Any?])
    case 130:
      return EAAccessoryObject.fromList(self.readValue() as! [Any?])
    default:
      return super.readValue(ofType: type)
    }
  }
}

private class FlutterAccessoryManagerPigeonCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? BluetoothDevice {
      super.writeByte(129)
      super.writeValue(value.toList())
    } else if let value = value as? EAAccessoryObject {
      super.writeByte(130)
      super.writeValue(value.toList())
    } else {
      super.writeValue(value)
    }
  }
}

private class FlutterAccessoryManagerPigeonCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return FlutterAccessoryManagerPigeonCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return FlutterAccessoryManagerPigeonCodecWriter(data: data)
  }
}

class FlutterAccessoryManagerPigeonCodec: FlutterStandardMessageCodec, @unchecked Sendable {
  static let shared = FlutterAccessoryManagerPigeonCodec(readerWriter: FlutterAccessoryManagerPigeonCodecReaderWriter())
}


/// Flutter -> Native
///
/// Generated protocol from Pigeon that represents a handler of messages from Flutter.
protocol FlutterAccessoryPlatformChannel {
  func showBluetoothAccessoryPicker(completion: @escaping (Result<Void, Error>) -> Void)
  func startScan() throws
  func stopScan() throws
  func isScanning() throws -> Bool
  func getPairedDevices() throws -> [BluetoothDevice]
  func pair(address: String, completion: @escaping (Result<Bool, Error>) -> Void)
}

/// Generated setup class from Pigeon to handle messages through the `binaryMessenger`.
class FlutterAccessoryPlatformChannelSetup {
  static var codec: FlutterStandardMessageCodec { FlutterAccessoryManagerPigeonCodec.shared }
  /// Sets up an instance of `FlutterAccessoryPlatformChannel` to handle messages through the `binaryMessenger`.
  static func setUp(binaryMessenger: FlutterBinaryMessenger, api: FlutterAccessoryPlatformChannel?, messageChannelSuffix: String = "") {
    let channelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
    let showBluetoothAccessoryPickerChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.showBluetoothAccessoryPicker\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      showBluetoothAccessoryPickerChannel.setMessageHandler { _, reply in
        api.showBluetoothAccessoryPicker { result in
          switch result {
          case .success:
            reply(wrapResult(nil))
          case .failure(let error):
            reply(wrapError(error))
          }
        }
      }
    } else {
      showBluetoothAccessoryPickerChannel.setMessageHandler(nil)
    }
    let startScanChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.startScan\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      startScanChannel.setMessageHandler { _, reply in
        do {
          try api.startScan()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      startScanChannel.setMessageHandler(nil)
    }
    let stopScanChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.stopScan\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      stopScanChannel.setMessageHandler { _, reply in
        do {
          try api.stopScan()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      stopScanChannel.setMessageHandler(nil)
    }
    let isScanningChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.isScanning\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      isScanningChannel.setMessageHandler { _, reply in
        do {
          let result = try api.isScanning()
          reply(wrapResult(result))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      isScanningChannel.setMessageHandler(nil)
    }
    let getPairedDevicesChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.getPairedDevices\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      getPairedDevicesChannel.setMessageHandler { _, reply in
        do {
          let result = try api.getPairedDevices()
          reply(wrapResult(result))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      getPairedDevicesChannel.setMessageHandler(nil)
    }
    let pairChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.pair\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      pairChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let addressArg = args[0] as! String
        api.pair(address: addressArg) { result in
          switch result {
          case .success(let res):
            reply(wrapResult(res))
          case .failure(let error):
            reply(wrapError(error))
          }
        }
      }
    } else {
      pairChannel.setMessageHandler(nil)
    }
  }
}
/// Native -> Flutter
///
/// Generated protocol from Pigeon that represents Flutter messages that can be called from Swift.
protocol FlutterAccessoryCallbackChannelProtocol {
  func accessoryConnected(accessory accessoryArg: EAAccessoryObject, completion: @escaping (Result<Void, PigeonError>) -> Void)
  func accessoryDisconnected(accessory accessoryArg: EAAccessoryObject, completion: @escaping (Result<Void, PigeonError>) -> Void)
  func onDeviceDiscover(device deviceArg: BluetoothDevice, completion: @escaping (Result<Void, PigeonError>) -> Void)
}
class FlutterAccessoryCallbackChannel: FlutterAccessoryCallbackChannelProtocol {
  private let binaryMessenger: FlutterBinaryMessenger
  private let messageChannelSuffix: String
  init(binaryMessenger: FlutterBinaryMessenger, messageChannelSuffix: String = "") {
    self.binaryMessenger = binaryMessenger
    self.messageChannelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
  }
  var codec: FlutterAccessoryManagerPigeonCodec {
    return FlutterAccessoryManagerPigeonCodec.shared
  }
  func accessoryConnected(accessory accessoryArg: EAAccessoryObject, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.accessoryConnected\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([accessoryArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
  func accessoryDisconnected(accessory accessoryArg: EAAccessoryObject, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.accessoryDisconnected\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([accessoryArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
  func onDeviceDiscover(device deviceArg: BluetoothDevice, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.onDeviceDiscover\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([deviceArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
}
