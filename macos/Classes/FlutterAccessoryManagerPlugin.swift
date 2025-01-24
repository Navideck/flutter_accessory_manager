import AppKit
import Carbon.HIToolbox
import Cocoa
import FlutterMacOS
import Foundation
import IOBluetooth
import IOKit.hid

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin {
    var accessoryManagerCallbackChannel: FlutterAccessoryCallbackChannel
    var hidCallbackChannel: BluetoothHidManagerCallbackChannel

    var service: IOBluetoothSDPServiceRecord?
    var delegateMap: [String: BTDevice] = [:]
    lazy var inquiry: IOBluetoothDeviceInquiry = .init(delegate: self)
    private var isInquiryStarted = false

    // We initialize IOBluetoothPairingController in ObjC because in Swift no modal is shown
    // This also does not work on native apps
    private lazy var pairingController = IOBluetoothPairingControllerObjC()

    init(callbackChannel: FlutterAccessoryCallbackChannel, hidCallback: BluetoothHidManagerCallbackChannel) {
        accessoryManagerCallbackChannel = callbackChannel
        hidCallbackChannel = hidCallback
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger: FlutterBinaryMessenger = registrar.messenger
        let callbackChannel = FlutterAccessoryCallbackChannel(binaryMessenger: messenger)
        let hidCallback = BluetoothHidManagerCallbackChannel(binaryMessenger: messenger)
        let instance = FlutterAccessoryManagerPlugin(callbackChannel: callbackChannel, hidCallback: hidCallback)
        FlutterAccessoryPlatformChannelSetup.setUp(binaryMessenger: messenger, api: instance)
        BluetoothHidManagerPlatformChannelSetup.setUp(binaryMessenger: messenger, api: instance)
    }
}

extension FlutterAccessoryManagerPlugin: BluetoothHidManagerPlatformChannel {
    func setupSdp(config: SdpConfig) throws {
        if let macConfig = config.macSdpConfig {
            try setupBluetoothSdpConfig(config: macConfig)
        } else {
            throw PigeonError(code: "ConfigError", message: "MacConfig not provided", details: nil)
        }
    }

    func connect(deviceId: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        guard let device = IOBluetoothDevice(addressString: deviceId) else {
            completion(.failure(PigeonError(code: "Failed", message: "Device not found", details: nil)))
            return
        }

        // Initiate Connection, calling in DispatchQueue fails setup
        if !device.isConnected() {
            let ioReturn: IOReturn = device.openConnection(
                nil,
                withPageTimeout: UInt16(round(2.0 * 1600)),
                authenticationRequired: true
            )

            if ioReturn != kIOReturnSuccess {
                let errorString = String(cString: mach_error_string(Int32(ioReturn)))
                completion(.failure(PigeonError(code: "Failed", message: errorString, details: nil)))
                return
            }
        }

        // Setup L2CAP channels
        let btDevice = delegateMap[deviceId] ?? BTDevice()

        if btDevice.interruptChannel != nil && btDevice.controlChannel != nil {
            print("Channel already opened")
            onConnectionUpdate(deviceId: deviceId, connected: true)
            completion(.success(()))
            return
        }

        device.performSDPQuery(self)

        btDevice.device = device

        // TODO: maybe use openL2CAPChannelAync
        var result = device.openL2CAPChannelSync(&btDevice.controlChannel, withPSM: BTChannels.Control, delegate: self)
        if result != kIOReturnSuccess {
            let errorString = String(cString: mach_error_string(Int32(result)))
            completion(.failure(PigeonError(code: "Failed", message: "Failed to open ControlChannel \(result) \(errorString)", details: nil)))
            return
        }

        result = device.openL2CAPChannelSync(&btDevice.interruptChannel, withPSM: BTChannels.Interrupt, delegate: self)
        if result != kIOReturnSuccess {
            let errorString = String(cString: mach_error_string(Int32(result)))
            completion(.failure(PigeonError(code: "Failed", message: "Failed to open Interrupt \(result) \(errorString)", details: nil)))
            return
        }

        delegateMap[device.addressString] = btDevice
        completion(.success(()))
    }

    func disconnect(deviceId: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        guard let device = IOBluetoothDevice(addressString: deviceId) else {
            completion(.failure(PigeonError(code: "Failed", message: "Device not found", details: nil)))
            return
        }
        // Close connection
        let ioReturn: IOReturn = device.closeConnection()
        if ioReturn != kIOReturnSuccess {
            let errorString = String(cString: mach_error_string(Int32(ioReturn)))
            completion(.failure(PigeonError(code: "Failed", message: errorString, details: nil)))
            return
        }
        // Close channels
        if let btDevice = delegateMap[deviceId] {
            btDevice.interruptChannel?.close()
            btDevice.controlChannel?.close()
        }
        completion(.success(()))
    }

    func sendReport(deviceId: String, data: FlutterStandardTypedData) throws {
        let byteArray = [UInt8](data.data)
        if let interruptChannel = delegateMap[deviceId]?.interruptChannel {
            try sendBytes(channel: interruptChannel, byteArray)
        } else {
            throw PigeonError(code: "Failed", message: "No interruptChannel", details: nil)
        }
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
            return [d.toBLuetoothDevice(delegateMap)]
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

            let ioReturn: IOReturn = device.openConnection(
                nil,
                withPageTimeout: UInt16(round(2.0 * 1600)),
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

extension FlutterAccessoryManagerPlugin: IOBluetoothDeviceAsyncCallbacks {
    public func remoteNameRequestComplete(_ device: IOBluetoothDevice, status: IOReturn) {
        print("RemoteNameRequestComplete \(String(describing: device.addressString)) \(status)")
    }

    public func connectionComplete(_ device: IOBluetoothDevice, status: IOReturn) {
        print("ConnectionComplete \(String(describing: device.addressString)) \(status)")
    }

    public func sdpQueryComplete(_ device: IOBluetoothDevice, status: IOReturn) {
        if status == kIOReturnSuccess {
            print("SDP query completed successfully for device: \(device)")
        } else {
            print("SDP query failed with status: \(status)")
        }
    }
}

extension FlutterAccessoryManagerPlugin: IOBluetoothDeviceInquiryDelegate {
    @objc public func deviceInquiryStarted(_: IOBluetoothDeviceInquiry) {
        isInquiryStarted = true
    }

    @objc public func deviceInquiryComplete(_: IOBluetoothDeviceInquiry, error: IOReturn, aborted _: Bool) {
        isInquiryStarted = false
        if error != kIOReturnSuccess {
            print("Inquiry failed with error: \(error)")
        }
    }

    @objc public func deviceInquiryDeviceFound(_: IOBluetoothDeviceInquiry, device: IOBluetoothDevice) {
        accessoryManagerCallbackChannel.onDeviceDiscover(device: device.toBLuetoothDevice(delegateMap)) { _ in }
    }

    @objc public func deviceInquiryUpdatingDeviceNamesStarted(_: IOBluetoothDeviceInquiry, devicesRemaining: UInt32) {
        print("Updating device names started: devicesRemaining = \(devicesRemaining)")
    }

    @objc public func deviceInquiryDeviceNameUpdated(_: IOBluetoothDeviceInquiry, device: IOBluetoothDevice, devicesRemaining: UInt32) {
        print("Device name updated: devicesRemaining = \(devicesRemaining), name = \(String(describing: device.nameOrAddress))")
    }
}

extension FlutterAccessoryManagerPlugin: IOBluetoothL2CAPChannelDelegate {
    func setupBluetoothSdpConfig(config: MacSdpConfig) throws {
        if service != nil {
            throw PigeonError(code: "AlreadyInitialized", message: "SDP service already initialized", details: nil)
        }

        let bluetoothHost = IOBluetoothHostController()
        bluetoothHost.setClassOfDevice(0x002540, forTimeInterval: 60)

        var sdpDict: NSDictionary? = nil

        if let sdpPlist = config.sdpPlistFile {
            let dictPath = Bundle.main.path(forResource: sdpPlist, ofType: "plist")
            sdpDict = NSDictionary(contentsOfFile: dictPath!)!
        } else if let sdpPlistData = config.data {
            // TODO: Fix this
            sdpDict = NSDictionary(dictionary: sdpPlistData)
        }

        if sdpDict == nil {
            throw PigeonError(code: "Failed to setup SDP", message: "SDP Dictionary is nil", details: nil)
        }

        // Bluetooth SDP Service
        service = IOBluetoothSDPServiceRecord.publishedServiceRecord(with: sdpDict! as [NSObject: AnyObject])

        // Open Channels for Incoming Connections
        guard IOBluetoothL2CAPChannel
            .register(forChannelOpenNotifications: self,
                      selector: #selector(newL2CAPChannelOpened),
                      withPSM: BTChannels.Control,
                      direction: kIOBluetoothUserNotificationChannelDirectionIncoming) != nil
        else {
            service = nil
            throw PigeonError(code: "Failed", message: "Failed to register ControlChannel", details: nil)
        }

        guard IOBluetoothL2CAPChannel
            .register(forChannelOpenNotifications: self,
                      selector: #selector(newL2CAPChannelOpened),
                      withPSM: BTChannels.Interrupt,
                      direction: kIOBluetoothUserNotificationChannelDirectionIncoming) != nil
        else {
            service = nil
            throw PigeonError(code: "Failed", message: "Failed to register InterruptChannel", details: nil)
        }

        // Send Sdp registered
        hidCallbackChannel.onSdpServiceRegistrationUpdate(registered: true, completion: { _ in })
        // TODO: Check if we have Callback when Sdp Unregister
    }

    private func sendBytes(channel: IOBluetoothL2CAPChannel, _ bytes: [UInt8]) throws {
        try bytes.withUnsafeBytes { bufferPointer in
            guard let baseAddress = bufferPointer.baseAddress else {
                throw PigeonError(code: "Failed", message: "Buffer pointer is nil", details: nil)
            }
            let ioError = channel.writeAsync(UnsafeMutableRawPointer(mutating: baseAddress),
                                             length: UInt16(bufferPointer.count),
                                             refcon: nil)
            if ioError != kIOReturnSuccess {
                throw PigeonError(code: "Failed", message: "Failed to send data \(channel.psm)", details: nil)
            }
        }
    }

    // Triggers when Interrupt Channel will be connected/disconnected from device
    private func onConnectionUpdate(deviceId: String, connected: Bool) {
        hidCallbackChannel.onConnectionStateChanged(deviceId: deviceId, connected: connected, completion: ({ _ in }))
    }

    @objc public func l2capChannelOpenComplete(_ channel: IOBluetoothL2CAPChannel, status: IOReturn) {
        if status != kIOReturnSuccess {
            print("L2capChannelOpenCompleteStatus \(status)")
        }
        guard let deviceId: String = channel.device?.addressString else {
            print("ChannelOpened but no device address")
            return
        }
        switch channel.psm {
        case BTChannels.Control:
            print("Opened ControlChannel for \(deviceId)")
            delegateMap[deviceId]?.controlChannel = channel
        case BTChannels.Interrupt:
            print("Opened InterruptChannel for \(deviceId)")
            delegateMap[deviceId]?.interruptChannel = channel
            onConnectionUpdate(deviceId: deviceId, connected: true)
        default:
            return
        }
    }

    @objc public func l2capChannelClosed(_ channel: IOBluetoothL2CAPChannel) {
        guard let deviceId: String = channel.device?.addressString else {
            print("ChannelClosed but no device address")
            return
        }
        switch channel.psm {
        case BTChannels.Control:
            print("Closed ControlChannel for \(deviceId)")
            delegateMap[deviceId]?.controlChannel = nil
        case BTChannels.Interrupt:
            print("Closed InterruptChannel for \(deviceId)")
            delegateMap[deviceId]?.interruptChannel = nil
            onConnectionUpdate(deviceId: deviceId, connected: false)
        default:
            return
        }
    }

    @objc private func l2capChannelWriteComplete(channel _: IOBluetoothL2CAPChannel, refcon _: UnsafeMutableRawPointer, status _: IOReturn) {
        print("l2capChannelWriteComplete")
    }

    @objc func newL2CAPChannelOpened(notification _: IOBluetoothUserNotification, channel: IOBluetoothL2CAPChannel) {
        print("NewChannelOpened")
        channel.setDelegate(self)
    }

    @objc private func l2capChannelData(channel: IOBluetoothL2CAPChannel, data dataPointer: UnsafePointer<UInt8>, length dataLength: Int) {
        let data = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>?(dataPointer), count: dataLength)
        if channel.psm == BTChannels.Control {
            guard data.count > 0 else { return }
            guard let messageType = BTMessageType(rawValue: data[0] >> 4)
            else { return }
            switch messageType {
            case .Handshake:
                print("Got Handshake")
                return
            case .HIDControl:
                print("Got HidControl")
                channel.device.closeConnection()
            case .SetReport, .SetProtocol:
                print("Sending HandShake")
                do {
                    guard channel.psm == BTChannels.Control else {
                        print("Passing wrong channel to handshake")
                        return
                    }
                    try sendBytes(channel: channel, [0x0 | UInt8(0)])
                } catch {
                    print(error)
                }
            default:
                print("Unhandled \(messageType)")
                return
            }
        }
    }
}

extension IOBluetoothDevice {
    func toBLuetoothDevice(_ delegateMap: [String: BTDevice]) -> BluetoothDevice {
        return BluetoothDevice(
            address: addressString,
            name: name,
            paired: isPaired(),
            isConnectedWithHid: delegateMap[addressString]?.interruptChannel != nil,
            rssi: Int64(rssi()),
            deviceClass: deviceClassMajor.toDeviceClass(),
            deviceType: nil
        )
    }
}

enum BTMessageType: UInt8 {
    case Handshake = 0,
         HIDControl
    case GetReport = 4,
         SetReport,
         GetProtocol,
         SetProtocol
    case Data = 0xA
}

enum BTChannels {
    static let Control = BluetoothL2CAPPSM(kBluetoothL2CAPPSMHIDControl)
    static let Interrupt = BluetoothL2CAPPSM(kBluetoothL2CAPPSMHIDInterrupt)
}

class BTDevice {
    var device: IOBluetoothDevice?
    var interruptChannel: IOBluetoothL2CAPChannel?
    var controlChannel: IOBluetoothL2CAPChannel?
}

extension BluetoothDeviceClassMajor {
    func toDeviceClass() -> DeviceClass? {
        switch Int(self) {
        case kBluetoothDeviceClassMajorComputer:
            return DeviceClass.computer
        case kBluetoothDeviceClassMajorPhone:
            return DeviceClass.phone
        case kBluetoothDeviceClassMajorLANAccessPoint:
            return DeviceClass.networking
        case kBluetoothDeviceClassMajorAudio:
            return DeviceClass.audioVideo
        case kBluetoothDeviceClassMajorPeripheral:
            return DeviceClass.peripheral
        case kBluetoothDeviceClassMajorWearable:
            return DeviceClass.wearable
        case kBluetoothDeviceClassMajorToy:
            return DeviceClass.toy
        case kBluetoothDeviceClassMajorHealth:
            return DeviceClass.health
        case kBluetoothDeviceClassMajorUnclassified:
            return DeviceClass.uncategorized
        case kBluetoothDeviceClassMajorMiscellaneous:
            return DeviceClass.misc
        case kBluetoothDeviceClassMajorImaging:
            return DeviceClass.imaging
        default:
            return nil
        }
    }
}
