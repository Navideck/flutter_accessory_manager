import Cocoa
import FlutterMacOS
import IOBluetooth

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin {
    var callbackChannel: FlutterAccessoryCallbackChannel

    lazy var inquiry: IOBluetoothDeviceInquiry = .init(delegate: self)
    var devicePair: IOBluetoothDevicePair?
    private var isInquiryStarted = false
    var devices = [String: IOBluetoothDevice]()
    var pairingFuture = [String: (Result<Bool, any Error>) -> Void]()

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
}

extension FlutterAccessoryManagerPlugin: FlutterAccessoryPlatformChannel {
    func startScan() throws {
        inquiry.updateNewDeviceNames = true
        inquiry.inquiryLength = 3
        inquiry.start()
    }

    func stopScan() throws {
        inquiry.stop()
    }

    func isScanning() throws -> Bool {
        return isInquiryStarted
    }

    func getPairedDevices() throws -> [BluetoothDevice] {
        return inquiry.foundDevices().filter { ($0 as! IOBluetoothDevice).isPaired() }.map { ($0 as! IOBluetoothDevice).toBLuetoothDevice() }
    }

    func showBluetoothAccessoryPicker(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(PigeonError(code: "Not Implemented", message: nil, details: nil)))
    }

    func pair(address: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        if let device = devices[address] {
//            if pairingFuture[address] != nil {
//                completion(.failure(PigeonError(code: "InProgress", message: "Pairing request already in progress", details: nil)))
//                return
//            }

            // TODO: Why to store as global variable ?
            devicePair = IOBluetoothDevicePair(device: device)
            devicePair?.delegate = self
            let result = devicePair?.start()
            if result != kIOReturnSuccess {
                completion(.failure(PigeonError(code: "Failed", message: "Pairing failed", details: nil)))
                return
            }

            // Store the Future to complete later from callback
            print("Waiting for pair result")
            // pairingFuture[device.addressString] = completion
            completion(.success(true))
        } else {
            completion(.failure(PigeonError(code: "NotFound", message: "Please start scan first", details: nil)))
        }
    }
}

extension FlutterAccessoryManagerPlugin: IOBluetoothDeviceInquiryDelegate {
    @objc public func deviceInquiryStarted(_: IOBluetoothDeviceInquiry!) {
        isInquiryStarted = true
    }

    @objc public func deviceInquiryComplete(_: IOBluetoothDeviceInquiry!, error: IOReturn, aborted _: Bool) {
        isInquiryStarted = false
        print("Device inquiry completed")
        if error != kIOReturnSuccess {
            print("Inquiry failed with error: \(error)")
        }
    }

    @objc public func deviceInquiryDeviceFound(_: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
        callbackChannel.onDeviceDiscover(device: device.toBLuetoothDevice()) { _ in }
        devices[device.addressString] = device
    }

    @objc public func deviceInquiryUpdatingDeviceNamesStarted(_: IOBluetoothDeviceInquiry!, devicesRemaining: UInt32) {
        print("Updating device names started: devicesRemaining = \(devicesRemaining)")
    }

    @objc public func deviceInquiryDeviceNameUpdated(_: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!, devicesRemaining: UInt32) {
        print("Device name updated: devicesRemaining = \(devicesRemaining), name = \(String(describing: device.nameOrAddress))")
    }

    private func btDeviceAddressToString(address: BluetoothDeviceAddress) -> String {
        let a = [
            String(format: "%02X", address.data.0),
            String(format: "%02X", address.data.1),
            String(format: "%02X", address.data.2),
            String(format: "%02X", address.data.3),
            String(format: "%02X", address.data.4),
            String(format: "%02X", address.data.5),
        ]
        return a.joined(separator: "-")
    }
}

extension FlutterAccessoryManagerPlugin: IOBluetoothDevicePairDelegate {
    @objc public func devicePairingStarted(_: Any!) {
        print("PairingStarted")
    }

    @objc public func devicePairingConnecting(_: Any!) {
        print("PairingConnecting")
    }

    @objc public func devicePairingConnected(_: Any!) {
        print("PairingConnected")
    }

    @objc public func devicePairingUserConfirmationRequest(_: Any!, numericValue: BluetoothNumericValue) {
        print("PairingUserConfirmationRequest (numericValue: \(numericValue))")
        devicePair?.replyUserConfirmation(true)
    }

    @objc public func devicePairingUserPasskeyNotification(_: Any!, passkey _: BluetoothPasskey) {
        print("PairingUserPasskeyNotification")
    }

    @objc public func devicePairingPINCodeRequest(_: Any!) {
        print("PairingPINCodeRequest")
    }

    @objc public func deviceSimplePairingComplete(_: Any!, status _: BluetoothHCIEventStatus) {
        print("Simple Pairing Complete")
    }

    @objc public func devicePairingFinished(_: Any!, error: IOReturn) {
        print("Pairing Result: \(error)")

//        Complete Flutter result
//        if let device = sender as? IOBluetoothDevice {
//            completePairFuture(address: device.addressString, error: error)
//        }
    }

    func completePairFuture(address: String, error: IOReturn) {
        if let future = pairingFuture.removeValue(forKey: address) {
            print("Sending result to flutter")
            if error == kIOReturnSuccess {
                future(.success(true))
            } else {
                future(.failure(PigeonError(code: "Failed", message: "Pairing failed with error \(error)", details: nil)))
            }
        }
    }
}

extension IOBluetoothDevice {
    func toBLuetoothDevice() -> BluetoothDevice {
        return BluetoothDevice(
            address: addressString,
            name: name,
            paired: isPaired(),
            rssi: Int64(rssi())
        )
    }
}
