import ExternalAccessory
import Flutter
import UIKit

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin, FlutterAccessoryPlatformChannel {
  var callbackChannel: FlutterAccessoryCallbackChannel
  private var manager = EAAccessoryManager.shared()

  init(callbackChannel: FlutterAccessoryCallbackChannel) {
    self.callbackChannel = callbackChannel
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger: FlutterBinaryMessenger = registrar.messenger()
    let callbackChannel = FlutterAccessoryCallbackChannel(binaryMessenger: messenger)
    let instance = FlutterAccessoryManagerPlugin(callbackChannel: callbackChannel)
    FlutterAccessoryPlatformChannelSetup.setUp(binaryMessenger: messenger, api: instance)
  }

  func showBluetoothAccessoryPicker(completion: @escaping (Result<Void, any Error>) -> Void) {
    // Get this from flutter, if user picked a device, and this protocol string appeared in connectedDevices, then disconnected
    let protocolStringToDisconnect = "com.nikon.psg-0100"   // TODO: Unhardcode it
      NotificationCenter.default.addObserver(self, selector: #selector(accessoryConnected(_:)), name: NSNotification.Name.EAAccessoryDidConnect, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(accessoryDisconnected(_:)), name: NSNotification.Name.EAAccessoryDidDisconnect, object: nil)
      
    manager.registerForLocalNotifications()
    manager.showBluetoothAccessoryPicker(withNameFilter: nil) { error in
      if let error = error {
        completion(.failure(PigeonError(code: "failed", message: error.localizedDescription, details: nil)))
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.EAAccessoryDidDisconnect, object: completion)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.EAAccessoryDidConnect, object: completion)
      } else {
        self.openAndCloseEaSession(protocolStringToDisconnect: protocolStringToDisconnect)
      }
    }
  }
    
  private func openAndCloseEaSession(protocolStringToDisconnect: String) {
    let accessory = manager.connectedAccessories.first { acc in
      acc.protocolStrings.contains(protocolStringToDisconnect)
    }
    guard let accessory else { return }
    var session: EASession? = EASession(accessory: accessory, forProtocol: protocolStringToDisconnect)
    print("EASession opened \(String(describing: session?.description))")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      print("Closing EASession")
      session = nil
    }
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
    
  func pair(address: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
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
      completion(.success(()))  // TODO: Get it from an instance dictionary property
      
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.EAAccessoryDidDisconnect, object: notification.object)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.EAAccessoryDidConnect, object: notification.object)
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
