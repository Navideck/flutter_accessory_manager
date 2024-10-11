import Cocoa
import FlutterMacOS

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger: FlutterBinaryMessenger = registrar.messenger
    let callbackChannel = FlutterAccessoryCallbackChannel(binaryMessenger: messenger)
    let api = FlutterAccessoryManagerHandler(callbackChannel: callbackChannel)
    FlutterAccessoryPlatformChannelSetup.setUp(binaryMessenger: messenger, api: api)
  }
}

private class FlutterAccessoryManagerHandler: NSObject, FlutterAccessoryPlatformChannel {
  var callbackChannel: FlutterAccessoryCallbackChannel

  init(callbackChannel: FlutterAccessoryCallbackChannel) {
    self.callbackChannel = callbackChannel
    super.init()
  }

  func showBluetoothAccessoryPicker(completion _: @escaping (Result<Void, any Error>) -> Void) {
    // Show accessory picker
  }
}
