package com.navideck.flutter_accessory_manager

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothProfile.ServiceListener
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat

private const val TAG = "FlutterAccessoryManagerPlugin"

@RequiresApi(Build.VERSION_CODES.P)
@SuppressLint("MissingPermission")
class BluetoothHidManager(
    private val context: Context,
    private val bluetoothAdapter: BluetoothAdapter,
    private val callbackChannel: BluetoothHidManagerCallbackChannel,
) : BluetoothHidManagerPlatformChannel, BluetoothHidDevice.Callback() {
    private var btHidProxy: BluetoothHidDevice? = null
    private var initialized = false;


    override fun setupSdp(config: SdpConfig) {
        val androidConfig = config.androidSdpConfig ?: throw FlutterError("InvalidAndroidConfig")
        if (initialized) {
            throw FlutterError("AlreadyInitialized", "BluetoothProxyProfile already initialized")
        }
        // Initialize profile and setup listener
        val result = bluetoothAdapter.getProfileProxy(
            context, object : ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
                    if (profile != BluetoothProfile.HID_DEVICE) return
                    Log.d(TAG, "Got HID device")
                    btHidProxy = proxy as BluetoothHidDevice
                    btHidProxy?.registerApp(
                        androidConfig.toSdp(),
                        null,
                        null,
                        ContextCompat.getMainExecutor(context),
                        this@BluetoothHidManager
                    )
                }

                override fun onServiceDisconnected(profile: Int) {
                    if (profile != BluetoothProfile.HID_DEVICE) return
                    Log.e(TAG, "Lost HID device")
                    btHidProxy?.unregisterApp()
                    btHidProxy = null
                }
            },
            BluetoothProfile.HID_DEVICE
        )

        if (!result) {
            throw FlutterError("Failed", "Failed to register hid profile")
        }
        initialized = true
    }


    override fun connect(deviceId: String, callback: (Result<Unit>) -> Unit) {
        try {
            val bluetoothDevice = getBluetoothDeviceFromId(deviceId)
            val result = btHidProxy?.connect(bluetoothDevice) ?: false
            if (!result) {
                callback(Result.failure(FlutterError("Failed", "Failed to connect")))
            } else {
                callback(Result.success(Unit))
            }
        } catch (e: Exception) {
            callback(Result.failure(FlutterError(code = "Error", message = e.toString())))
        }
    }

    override fun disconnect(deviceId: String, callback: (Result<Unit>) -> Unit) {
        val device = btHidProxy?.connectedDevices?.first { it.name == deviceId }
        if (device == null) {
            callback(Result.failure(FlutterError("NotFound", "Device not connected")))
            return
        }
        val result = btHidProxy?.disconnect(device) ?: false
        if (!result) {
            callback(Result.failure(FlutterError("Failed", "Failed to disconnect")))
        } else {
            callback(Result.success(Unit))
        }
    }

    override fun sendReport(deviceId: String, data: ByteArray) {
        val device = btHidProxy?.connectedDevices?.firstOrNull { it.address == deviceId }
            ?: throw FlutterError("NotFound", "Device not connected")
        val result = btHidProxy?.sendReport(device, 0, data) ?: false
        if (!result) {
            throw FlutterError("Failed", "Failed to disconnect")
        }
    }

    /// ---- BluetoothHidDeviceCallback ----
    override fun onGetReport(device: BluetoothDevice, type: Byte, id: Byte, bufferSize: Int) {
        Log.d(TAG, "onGetReport: device=$device type=$type id=$id bufferSize=$bufferSize")
        accessoryManagerThreadHandler?.post {
            callbackChannel.onGetReport(device.address, type.toReportType(), bufferSize.toLong()) {
                val reply: ReportReply? = it.getOrNull()
                if (reply == null) {
                    btHidProxy?.reportError(device, BluetoothHidDevice.ERROR_RSP_UNSUPPORTED_REQ)
                } else if (reply.error != null) {
                    btHidProxy?.reportError(device, reply.error.toByte())
                } else if (reply.data != null) {
                    btHidProxy?.replyReport(device, type, id, reply.data);
                } else {
                    btHidProxy?.reportError(device, BluetoothHidDevice.ERROR_RSP_UNKNOWN)
                }

            }
        }
    }

    override fun onConnectionStateChanged(device: BluetoothDevice, state: Int) {
        when (state) {
            BluetoothProfile.STATE_CONNECTING -> Log.d(TAG, "Connecting to $device")
            BluetoothProfile.STATE_CONNECTED -> Log.d(TAG, "Connected to $device")
            BluetoothProfile.STATE_DISCONNECTING -> Log.d(TAG, "Disconnecting from $device")
            BluetoothProfile.STATE_DISCONNECTED -> Log.d(TAG, "Disconnected from $device")
        }
        if (state == BluetoothProfile.STATE_CONNECTED) {
            accessoryManagerThreadHandler?.post {
                callbackChannel.onConnectionStateChanged(device.address, true) {}
            }
        } else if (state == BluetoothProfile.STATE_DISCONNECTED) {
            accessoryManagerThreadHandler?.post {
                callbackChannel.onConnectionStateChanged(device.address, false) {}
            }
        }
    }

    override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
        Log.d(TAG, "onAppStatusChanged $pluggedDevice $registered")
        accessoryManagerThreadHandler?.post {
            callbackChannel.onSdpServiceRegistrationUpdate(registered) {}
        }
    }

    override fun onSetReport(device: BluetoothDevice?, type: Byte, id: Byte, data: ByteArray?) {
        Log.d(TAG, "onSetReport $device $type $id $data")
        btHidProxy?.reportError(device, BluetoothHidDevice.ERROR_RSP_SUCCESS);
    }

    override fun onSetProtocol(device: BluetoothDevice?, protocol: Byte) {
        Log.d(TAG, "onSetProtocol $device $protocol")
    }

    override fun onInterruptData(device: BluetoothDevice?, reportId: Byte, data: ByteArray?) {
        Log.d(TAG, "onInterruptData $device $reportId $data")
    }

    override fun onVirtualCableUnplug(device: BluetoothDevice?) {
        Log.d(TAG, "onVirtualCableUnplug $device")
    }
    /// ---- BluetoothHidDeviceCallback ----

    private fun getBluetoothDeviceFromId(deviceId: String): BluetoothDevice {
        bluetoothDevicesCache[deviceId]?.let { return it }
        btHidProxy?.getDevicesMatchingConnectionStates(
            intArrayOf(BluetoothProfile.STATE_CONNECTING, BluetoothProfile.STATE_CONNECTED)
        )?.firstOrNull { it.address == deviceId }?.let { return it }
        bluetoothAdapter.bondedDevices?.firstOrNull { it.address == deviceId }?.let { return it }
        throw Exception("Device not found, please scan")
    }

    private fun AndroidSdpConfig.toSdp(): BluetoothHidDeviceAppSdpSettings {
        return BluetoothHidDeviceAppSdpSettings(
            name,
            description,
            provider,
            subclass.toByte(),
            descriptors
        )
    }

    private fun Byte.toReportType(): ReportType {
        return when (this) {
            BluetoothHidDevice.REPORT_TYPE_FEATURE -> ReportType.FEATURE
            BluetoothHidDevice.REPORT_TYPE_INPUT -> ReportType.INPUT
            BluetoothHidDevice.REPORT_TYPE_OUTPUT -> ReportType.OUTPUT
            else -> ReportType.FEATURE
        }
    }
}