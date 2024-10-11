import Cocoa
import FlutterMacOS
import IOBluetooth

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin {   
    var callbackChannel: FlutterAccessoryCallbackChannel
    
    lazy var inquiry: IOBluetoothDeviceInquiry = IOBluetoothDeviceInquiry(delegate: self)
    var devicePair: IOBluetoothDevicePair?
    private var isInquiryStarted = false
    var devices = [String: IOBluetoothDevice]()

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
    func pair(address: String) throws {
        if let device = devices[address] {
            print("Initiating pairing process")
              if !self.pairWithDevice(device) {
                  throw PigeonError(code: "Failed", message: "Pairing failed", details: nil)
              }
        } else {
            throw PigeonError(code: "Not found", message: "Please start scan first", details: nil)
        }
    }
    
    func startScan() throws {
        self.inquiry.updateNewDeviceNames = true
        self.inquiry.inquiryLength = 3
        self.inquiry.start()
    }
    
    func stopScan() throws {
        self.inquiry.stop()
    }
    
    func isScanning() throws -> Bool {
        return isInquiryStarted
    }
    
    func getPairedDevices() throws -> [BluetoothDevice] {
        return inquiry.foundDevices().filter{($0 as! IOBluetoothDevice).isPaired()}.map{($0 as! IOBluetoothDevice).toBLuetoothDevice()}
    }
    
    func showBluetoothAccessoryPicker(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(PigeonError(code: "Not Implemented", message: nil, details: nil)))
    }
}

extension IOBluetoothDevice {
    func toBLuetoothDevice() -> BluetoothDevice {
        return BluetoothDevice(
            address: self.addressString,
            name: self.name,
            paired: self.isPaired(),
            rssi: Int64(self.rssi())
        )
    }
}


extension FlutterAccessoryManagerPlugin: IOBluetoothDeviceInquiryDelegate {
    
    @objc public func deviceInquiryStarted(_ sender: IOBluetoothDeviceInquiry!) {
        isInquiryStarted = true
    }
    
    @objc public func deviceInquiryDeviceFound(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
        callbackChannel.onDeviceDiscover(device: device.toBLuetoothDevice()) { _ in }
        devices[device.addressString] = device
    }

    @objc public func deviceInquiryUpdatingDeviceNamesStarted(_ sender: IOBluetoothDeviceInquiry!, devicesRemaining: UInt32) {
        print("Updating device names started: devicesRemaining = \(devicesRemaining)")
    }

    @objc public func deviceInquiryDeviceNameUpdated(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!, devicesRemaining: UInt32) {
        print("Device name updated: devicesRemaining = \(devicesRemaining), name = \(String(describing: device.nameOrAddress))")
    }

    @objc public func deviceInquiryComplete(_ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
        isInquiryStarted = false
        print("Device inquiry completed")
        if error != kIOReturnSuccess {
            print("Inquiry failed with error: \(error)")
        }
    }
    
//    private func connectToDevice(_ device: IOBluetoothDevice) {
//        if device.isConnected() {
//            print("Device is already connected")
//            exit(0)
//        }
//
//        let ret = device.openConnection()
//        if ret != kIOReturnSuccess {
//            print("Failed to connect to device")
//            exit(1)
//        } else {
//            print("Successfully connected to device")
//            exit(0)
//        }
//    }
    
    private func pairWithDevice(_ device: IOBluetoothDevice) -> Bool {
        self.devicePair = IOBluetoothDevicePair(device: device)
        self.devicePair?.delegate = self
        let result = self.devicePair?.start()
        return result == kIOReturnSuccess
    }

    private func btDeviceAddressToString(address: BluetoothDeviceAddress) -> String {
        let a = [
            String(format: "%02X", address.data.0),
            String(format: "%02X", address.data.1),
            String(format: "%02X", address.data.2),
            String(format: "%02X", address.data.3),
            String(format: "%02X", address.data.4),
            String(format: "%02X", address.data.5)
        ]
        return a.joined(separator: "-")
    }
}

extension FlutterAccessoryManagerPlugin: IOBluetoothDevicePairDelegate {
    @objc public func devicePairingFinished(_ sender: Any!, error: IOReturn) {
        if error == kIOReturnSuccess {
            print("Pairing successful")
        } else {
            print("Pairing failed with error: \(error)")
        }
    }
}