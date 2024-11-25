import ExternalAccessory
import Flutter
import UIKit

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin, ExternalAccessoryChannel {
  var callbackChannel: ExternalAccessoryCallbackChannel
  private var manager = EAAccessoryManager.shared()
  private var eaSessionDisconnectionCompleterMap = [String: (Result<Void, any Error>) -> Void]()

  init(callbackChannel: ExternalAccessoryCallbackChannel) {
    self.callbackChannel = callbackChannel
    manager.registerForLocalNotifications()
    super.init()

    NotificationCenter.default.addObserver(self, selector: #selector(accessoryConnected(_:)), name: NSNotification.Name.EAAccessoryDidConnect, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(accessoryDisconnected(_:)), name: NSNotification.Name.EAAccessoryDidDisconnect, object: nil)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger: FlutterBinaryMessenger = registrar.messenger()
    let callbackChannel = ExternalAccessoryCallbackChannel(binaryMessenger: messenger)
    let instance = FlutterAccessoryManagerPlugin(callbackChannel: callbackChannel)
    ExternalAccessoryChannelSetup.setUp(binaryMessenger: messenger, api: instance)
  }

  func showBluetoothAccessoryPicker(withNames: [String], completion: @escaping (Result<Void, any Error>) -> Void) {
    var compoundPredicate: NSCompoundPredicate? = nil
    if !withNames.isEmpty {
      // Matches strings that start with the specified value. [c] makes the comparison case-insensitive.
      let predicates = withNames.map { NSPredicate(format: "SELF BEGINSWITH[c] %@", $0) }  
      compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
    manager.showBluetoothAccessoryPicker(withNameFilter: compoundPredicate) { error in
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
      session = nil
    }
    eaSessionDisconnectionCompleterMap[protocolString] = completion
  }

  @objc private func accessoryConnected(_ notification: NSNotification) {
    let connectedAccessory = notification.userInfo![EAAccessoryKey] as? EAAccessory
    guard let connectedAccessory else { return }
    callbackChannel.accessoryConnected(accessory: connectedAccessory.toEAAccessoryObject()) { _ in }
  }

  @objc private func accessoryDisconnected(_ notification: NSNotification) {
    let connectedAccessory = notification.userInfo![EAAccessoryKey] as? EAAccessory
    guard let connectedAccessory else { return }
    for protocolString in connectedAccessory.protocolStrings {
      eaSessionDisconnectionCompleterMap.removeValue(forKey: protocolString)?(.success(()))
    }
    callbackChannel.accessoryDisconnected(accessory: connectedAccessory.toEAAccessoryObject()) { _ in }
  }
}

extension EAAccessory {
  func toEAAccessoryObject() -> EAAccessory {
    return EAAccessory(
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
