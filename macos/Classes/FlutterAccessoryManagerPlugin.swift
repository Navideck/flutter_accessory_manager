import Cocoa
import FlutterMacOS

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin, FlutterAccessoryPlatformChannel {
  var callbackChannel: FlutterAccessoryCallbackChannel

  init(callbackChannel: FlutterAccessoryCallbackChannel) {
    self.callbackChannel = callbackChannel
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger: FlutterBinaryMessenger = registrar.messenger
    let callbackChannel = FlutterAccessoryCallbackChannel(binaryMessenger: messenger)
    let instance = FlutterAccessoryManagerPlugin(callbackChannel: callbackChannel)
    FlutterAccessoryPlatformChannelSetup.setUp(binaryMessenger: messenger, api: instance)
  }

  func showBluetoothAccessoryPicker(completion: @escaping (Result<Void, any Error>) -> Void) {
    completion(.failure(PigeonError(code: "NotSupported", message: nil, details: nil)))
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
}
