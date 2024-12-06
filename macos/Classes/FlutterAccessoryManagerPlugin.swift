import Cocoa
import FlutterMacOS
import IOBluetooth

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin {
    var callbackChannel: FlutterAccessoryCallbackChannel

    lazy var inquiry: IOBluetoothDeviceInquiry = .init(delegate: self)
    private var isInquiryStarted = false
    var devices = [String: IOBluetoothDevice]()

    // We initialize IOBluetoothPairingController in ObjC because in Swift no modal is shown
    // This also does not work on native apps
    private lazy var pairingController = IOBluetoothPairingControllerObjC()

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
        guard let paired = IOBluetoothDevice.pairedDevices() else { return [] }
        return paired.map { device -> [BluetoothDevice] in
            guard let d = device as? IOBluetoothDevice else { return [] }
            return [d.toBLuetoothDevice()]
        }.flatMap { $0 }
    }

    func showBluetoothAccessoryPicker(withNames _: [String], completion: @escaping (Result<Void, any Error>) -> Void) {
        pairingController.performSelector(
            onMainThread: #selector(IOBluetoothPairingController.runModal),
            with: nil,
            waitUntilDone: false
        )
        completion(.success(()))
    }

    func disconnect(deviceId: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        guard let device = IOBluetoothDevice(addressString: deviceId) else {
            completion(.failure(PigeonError(code: "Failed", message: "Device not found", details: nil)))
            return
        }
        let ioReturn: IOReturn = device.closeConnection()
        if ioReturn == kIOReturnSuccess {
            completion(.success(()))
            return
        }
        let errorString = String(cString: mach_error_string(Int32(ioReturn)))
        completion(.failure(PigeonError(code: "Failed", message: errorString, details: nil)))
    }

    func pair(address: String, completion: @escaping (Result<Bool, any Error>) -> Void) {
        guard let device = IOBluetoothDevice(addressString: address) else {
            completion(.failure(PigeonError(code: "Failed", message: "Device not found", details: nil)))
            return
        }

        // Initiate Connection
        DispatchQueue.global(qos: .background).async {
            if device.isConnected() {
                print("Already connected \(address)")
                completion(.success(true))
                return
            }

            let timeout = 2.0
            let ioReturn: IOReturn = device.openConnection(
                nil,
                withPageTimeout: UInt16(round(timeout * 1600)),
                authenticationRequired: true
            )

            if ioReturn == kIOReturnSuccess {
                completion(.success(true))
                return
            }

            let errorString = String(cString: mach_error_string(Int32(ioReturn)))
            completion(.failure(PigeonError(code: "Failed", message: errorString, details: nil)))
        }
    }

    func unpair(address: String) -> Bool? {
        guard let device = IOBluetoothDevice(addressString: address) else { return nil }
        // There is no public API for unPairing, so we need this ugly hack with a custom selector
        let selector = Selector(("remove"))
        if device.responds(to: selector) { device.perform(selector) }
        return !device.isPaired()
    }
}

extension FlutterAccessoryManagerPlugin: IOBluetoothDeviceInquiryDelegate {
    @objc public func deviceInquiryStarted(_: IOBluetoothDeviceInquiry!) {
        isInquiryStarted = true
    }

    @objc public func deviceInquiryComplete(_: IOBluetoothDeviceInquiry!, error: IOReturn, aborted _: Bool) {
        isInquiryStarted = false
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
