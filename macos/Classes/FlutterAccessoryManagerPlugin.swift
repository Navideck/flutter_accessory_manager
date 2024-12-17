import AppKit
import Carbon.HIToolbox // virtual keys
import Cocoa
import FlutterMacOS
import Foundation
import IOBluetooth
import IOKit.hid // hid keys

public class FlutterAccessoryManagerPlugin: NSObject, FlutterPlugin {
    var callbackChannel: FlutterAccessoryCallbackChannel

    var service: IOBluetoothSDPServiceRecord?
    var delegateMap: [String: BTDevice] = [:]
    lazy var inquiry: IOBluetoothDeviceInquiry = .init(delegate: self)
    private var isInquiryStarted = false

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

    func connect(deviceId: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        guard let device = IOBluetoothDevice(addressString: deviceId) else {
            completion(.failure(PigeonError(code: "Failed", message: "Device not found", details: nil)))
            return
        }

        // Initiate Connection, calling in DispatchQueue fails setup
        //  DispatchQueue.global(qos: .background).async {
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
        // }

        // Setup L2CAP channels
        do {
            try openChannels(device: device)
            completion(.success(()))
        } catch {
            if error is PigeonError {
                completion(.failure(error))
            } else {
                completion(.failure(PigeonError(code: "Failed", message: String(describing: error), details: nil)))
            }
        }
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

    func setupSdp(config: SdpConfig) throws {
        if let macConfig = config.macSdpConfig {
            try setupBluetoothSdpConfig(config: macConfig)
        } else{
            throw PigeonError(code: "ConfigError", message: "MacConfig not provided", details: nil )
        }
    }

    func sendReport(deviceId: String, data: FlutterStandardTypedData) throws {
        let byteArray = [UInt8](data.data)
        if let interruptChannel = delegateMap[deviceId]?.interruptChannel {
            try sendBytes(channel: interruptChannel, byteArray)
        } else {
            throw PigeonError(code: "Failed", message: "No interruptChannel", details: nil)
        }
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

extension FlutterAccessoryManagerPlugin: IOBluetoothL2CAPChannelDelegate {
    func setupBluetoothSdpConfig(config: MacSdpConfig) throws {
        let bluetoothHost = IOBluetoothHostController()
        bluetoothHost.setClassOfDevice(0x002540, forTimeInterval: 60)
        
        var sdpDict: NSDictionary? = nil;
        
        if let sdpPlist = config.sdpPlistFile {
              let dictPath = Bundle.main.path(forResource: sdpPlist, ofType: "plist")
              sdpDict = NSDictionary(contentsOfFile: dictPath!)!
        } else if let sdpPlistData = config.data {
            // TODO: Fix this
             sdpDict =  NSDictionary(dictionary: sdpPlistData)
        }
        
        if sdpDict == nil {
            throw PigeonError(code: "Failed to setup SDP", message: "SDP Dictionary is nil", details: nil)
        }

        // Bluetooth SDP Service
        service = IOBluetoothSDPServiceRecord.publishedServiceRecord(with: sdpDict! as [NSObject: AnyObject])

        // Open Channels for Incoming Connections
        let controlChannelOpen = IOBluetoothL2CAPChannel
            .register(forChannelOpenNotifications: self,
                      selector: #selector(newL2CAPChannelOpened),
                      withPSM: BTChannels.Control,
                      direction: kIOBluetoothUserNotificationChannelDirectionIncoming)

        if controlChannelOpen == nil {
            print("failed to register ControlChannel")
            return
        }

        let interruptChannelOpen = IOBluetoothL2CAPChannel
            .register(forChannelOpenNotifications: self,
                      selector: #selector(newL2CAPChannelOpened),
                      withPSM: BTChannels.Interrupt,
                      direction: kIOBluetoothUserNotificationChannelDirectionIncoming)

        if interruptChannelOpen == nil {
            print("failed to registered InterruptChannel")
            return
        }
    }

    func openChannels(device: IOBluetoothDevice) throws {
        let btDevice = BTDevice()
        btDevice.device = device

        var result = device.openL2CAPChannelSync(&btDevice.controlChannel, withPSM: BTChannels.Control, delegate: self)
        if result != kIOReturnSuccess {
            throw PigeonError(code: "Failed", message: "Failed to open ControlChannel \(result)", details: nil)
        }

        result = device.openL2CAPChannelSync(&btDevice.interruptChannel, withPSM: BTChannels.Interrupt, delegate: self)
        if result != kIOReturnSuccess {
            throw PigeonError(code: "Failed", message: "Failed to open Interuppt \(result)", details: nil)
        }

        delegateMap[device.addressString] = btDevice
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

    @objc public func l2capChannelOpenComplete(_ channel: IOBluetoothL2CAPChannel!, status _: IOReturn) {
        let deviceId: String = channel.device.addressString
        switch channel.psm {
        case BTChannels.Control:
            print("Opened ControlChannel for \(deviceId)")
            delegateMap[deviceId]?.controlChannel = channel
        case BTChannels.Interrupt:
            print("Opened InterruptChannel for \(deviceId)")
            delegateMap[deviceId]?.interruptChannel = channel
        default:
            return
        }
    }

    @objc public func l2capChannelClosed(_ channel: IOBluetoothL2CAPChannel!) {
        let deviceId: String = channel.device.addressString
        switch channel.psm {
        case BTChannels.Control:
            print("Closed ControlChannel for \(deviceId)")
            delegateMap[deviceId]?.controlChannel = nil
        case BTChannels.Interrupt:
            print("Closed InterruptChannel for \(deviceId)")
            delegateMap[deviceId]?.interruptChannel = nil
        default:
            return
        }
    }

    @objc private func l2capChannelWriteComplete(channel _: IOBluetoothL2CAPChannel!, refcon _: UnsafeMutableRawPointer, status _: IOReturn) {
        print("l2capChannelWriteComplete")
    }

    @objc func newL2CAPChannelOpened(notification _: IOBluetoothUserNotification, channel: IOBluetoothL2CAPChannel) {
        print("NewChannelOpened")
        channel.setDelegate(self)
    }
    
    @objc private func l2capChannelData(channel: IOBluetoothL2CAPChannel!, data dataPointer: UnsafePointer<UInt8>, length dataLength: Int) {
        let data = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>?(dataPointer), count: dataLength)
        if channel.psm == BTChannels.Control {
            guard data.count > 0 else { return }
            guard let messageType = BTMessageType(rawValue: data[0] >> 4)
            else { return }
            switch messageType {
            case .Handshake:
                print("Got Handsake")
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
    func toBLuetoothDevice() -> BluetoothDevice {
        return BluetoothDevice(
            address: addressString,
            name: name,
            paired: isPaired(),
            rssi: Int64(rssi())
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
