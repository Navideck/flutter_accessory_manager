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

  func showBluetoothAccessoryPicker(completion _: @escaping (Result<Void, any Error>) -> Void) {
    // Show accessory picker
  }
}
