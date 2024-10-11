import Cocoa
import FlutterMacOS
import IOBluetooth

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin, FlutterAccessoryPlatformChannel {
    var callbackChannel: FlutterAccessoryCallbackChannel
    
    var target = "Z_30_6012062" // target must be "MAC Address" or "Device Name"
    var inquiry: IOBluetoothDeviceInquiry?
    var devicePair: IOBluetoothDevicePair?
    
    var completion: ((Result<Void, Error>) -> Void)?

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

    func showBluetoothAccessoryPicker(completion: @escaping (Result<Void, Error>) -> Void) {
        self.completion = completion
        
        startInquiry()
    }
    
    private func startInquiry() {
        self.inquiry = IOBluetoothDeviceInquiry(delegate: self)
        self.inquiry?.updateNewDeviceNames = true
        self.inquiry?.inquiryLength = 3
        self.inquiry?.start()
    }
}


extension FlutterAccessoryManagerPlugin: IOBluetoothDeviceInquiryDelegate {
    @objc public func deviceInquiryDeviceFound(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
        let address = device.getAddress()
        let addressStr = self.btDeviceAddressToString(address: address!.pointee)
        let name = device.name ?? "Unknown"
        print("Device found: address = \(addressStr), name = \(name)")

        if self.target.uppercased() == addressStr || self.target == name {
            print("Target device found")
            self.inquiry?.stop()

            if device.isPaired() {
                print("Device is already paired")
                self.connectToDevice(device)
            } else {
                print("Initiating pairing process")
                self.pairWithDevice(device)
            }
        }
    }

    @objc public func deviceInquiryUpdatingDeviceNamesStarted(_ sender: IOBluetoothDeviceInquiry!, devicesRemaining: UInt32) {
        print("Updating device names started: devicesRemaining = \(devicesRemaining)")
    }

    @objc public func deviceInquiryDeviceNameUpdated(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!, devicesRemaining: UInt32) {
        print("Device name updated: devicesRemaining = \(devicesRemaining), name = \(String(describing: device.nameOrAddress))")
    }

    @objc public func deviceInquiryComplete(_ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
        print("Device inquiry completed")
        if error != kIOReturnSuccess {
            print("Inquiry failed with error: \(error)")
            exit(1)
        }
    }
    
    private func connectToDevice(_ device: IOBluetoothDevice) {
        if device.isConnected() {
            print("Device is already connected")
            exit(0)
        }

        let ret = device.openConnection()
        if ret != kIOReturnSuccess {
            print("Failed to connect to device")
            exit(1)
        } else {
            print("Successfully connected to device")
            exit(0)
        }
    }
    
    private func pairWithDevice(_ device: IOBluetoothDevice) {
        self.devicePair = IOBluetoothDevicePair(device: device)
        self.devicePair?.delegate = self
        let result = self.devicePair?.start()
        if result != kIOReturnSuccess {
            print("Failed to start pairing process")
            exit(1)
        }
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
            self.connectToDevice((sender as AnyObject).device())
        } else {
            print("Pairing failed with error: \(error)")
            exit(1)
        }
    }
}
