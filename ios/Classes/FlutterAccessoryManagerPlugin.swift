import ExternalAccessory
import Flutter
import UIKit

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin, FlutterAccessoryPlatformChannel {
  var callbackChannel: FlutterAccessoryCallbackChannel
  var _manager = EAAccessoryManager.shared()

  init(callbackChannel: FlutterAccessoryCallbackChannel) {
    self.callbackChannel = callbackChannel
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    var messenger: FlutterBinaryMessenger = registrar.messenger()
    let callbackChannel = FlutterAccessoryCallbackChannel(binaryMessenger: messenger)
    let instance = FlutterAccessoryManagerPlugin(callbackChannel: callbackChannel)
    FlutterAccessoryPlatformChannelSetup.setUp(binaryMessenger: messenger, api: instance)
  }

  func showBluetoothAccessoryPicker(completion: @escaping (Result<Void, any Error>) -> Void) {
    NotificationCenter.default.addObserver(self, selector: #selector(accessoryConnected), name: NSNotification.Name.EAAccessoryDidConnect, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(accessoryDisconnected), name: NSNotification.Name.EAAccessoryDidDisconnect, object: nil)
    _manager.registerForLocalNotifications()
    _manager.showBluetoothAccessoryPicker(withNameFilter: nil, completion: { error in
      if error != nil {
        completion(.failure(PigeonError(code: "failed", message: error?.localizedDescription ?? "Unknown Error", details: nil)))
      } else {
        completion(.success({}()))
      }
    })
  }

  func startScan() throws {
    throw PigeonError(code: "NotSupported", message: nil, details: nil)
  }

  func stopScan() throws {
    throw PigeonError(code: "NotSupported", message: nil, details: nil)
  }

  func isScanning() throws -> Bool {
    throw PigeonError(code: "NotSupported", message: nil, details: nil)
  }

  func getPairedDevices() throws -> [BluetoothDevice] {
    throw PigeonError(code: "NotSupported", message: nil, details: nil)
  }

  @objc private func accessoryConnected(notification: NSNotification) {
    let connectedAccessory = notification.userInfo![EAAccessoryKey] as? EAAccessory
    print("Accessory Connected")
    guard let connectedAccessory else { return }
    callbackChannel.accessoryConnected(accessory: connectedAccessory.toEAAccessoryObject()) { _ in }
  }

  @objc private func accessoryDisconnected(notification: NSNotification) {
    let connectedAccessory = notification.userInfo![EAAccessoryKey] as? EAAccessory
    guard let connectedAccessory else { return }
    print("Accessory Disconnected")
    callbackChannel.accessoryDisconnected(accessory: connectedAccessory.toEAAccessoryObject()) { _ in }
  }
}

extension EAAccessory {
  func toEAAccessoryObject() -> EAAccessoryObject {
    return EAAccessoryObject(
      isConnected: isConnected,
      connectionID: Int64(connectionID),
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
}
