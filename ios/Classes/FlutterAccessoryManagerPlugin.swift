import ExternalAccessory
import Flutter
import UIKit

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin, FlutterAccessoryPlatformChannel {
  var callbackChannel: FlutterAccessoryCallbackChannel
  private var manager = EAAccessoryManager.shared()
  private var eaSessionDisconnectionCompleterMap = [String: (Result<Void, any Error>) -> Void]()

  init(callbackChannel: FlutterAccessoryCallbackChannel) {
    self.callbackChannel = callbackChannel
    manager.registerForLocalNotifications()
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    NotificationCenter.default.addObserver(self, selector: #selector(accessoryConnected(_:)), name: NSNotification.Name.EAAccessoryDidConnect, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(accessoryDisconnected(_:)), name: NSNotification.Name.EAAccessoryDidDisconnect, object: nil)
    let messenger: FlutterBinaryMessenger = registrar.messenger()
    let callbackChannel = FlutterAccessoryCallbackChannel(binaryMessenger: messenger)
    let instance = FlutterAccessoryManagerPlugin(callbackChannel: callbackChannel)
    FlutterAccessoryPlatformChannelSetup.setUp(binaryMessenger: messenger, api: instance)
  }

  func showBluetoothAccessoryPicker(completion: @escaping (Result<Void, any Error>) -> Void) {
    manager.showBluetoothAccessoryPicker(withNameFilter: nil) { error in
      if let error = error {
        completion(.failure(PigeonError(code: "failed", message: error.localizedDescription, details: nil)))
      } else {
        completion(.success(()))
      }
    }
  }

  func closeEaSession(protocolString: String, completion: @escaping (Result<Void, any Error>) -> Void) {
    if eaSessionDisconnectionCompleterMap[protocolString] != nil {
      completion(.failure(PigeonError(code: "AlreadyInProgress", message: "Operation already in progress", details: nil)))
      return
    }
    let accessory = manager.connectedAccessories.first { acc in
      acc.protocolStrings.contains(protocolString)
    }
    guard let accessory else {
      completion(.failure(PigeonError(code: "NotFound", message: "Accessory not found", details: nil)))
      return
    }
    var session: EASession? = EASession(accessory: accessory, forProtocol: protocolString)
    print("EASession opened \(String(describing: session?.description))")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      print("Closing EASession")
      session = nil
    }
    eaSessionDisconnectionCompleterMap[protocolString] = completion
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

  func pair(address _: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
    completion(.failure(PigeonError(code: "NotSupported", message: nil, details: nil)))
  }

  @objc private func accessoryConnected(_ notification: NSNotification) {
    let connectedAccessory = notification.userInfo![EAAccessoryKey] as? EAAccessory
    print("Accessory Connected")
    guard let connectedAccessory else { return }
    callbackChannel.accessoryConnected(accessory: connectedAccessory.toEAAccessoryObject()) { _ in }
  }

  @objc private func accessoryDisconnected(_ notification: NSNotification) {
    let connectedAccessory = notification.userInfo![EAAccessoryKey] as? EAAccessory
    guard let connectedAccessory else { return }
    print("Accessory Disconnected")
    callbackChannel.accessoryDisconnected(accessory: connectedAccessory.toEAAccessoryObject()) { _ in }
    for protocolString in connectedAccessory.protocolStrings {
      eaSessionDisconnectionCompleterMap.removeValue(forKey: protocolString)?(.success(()))
    }
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
