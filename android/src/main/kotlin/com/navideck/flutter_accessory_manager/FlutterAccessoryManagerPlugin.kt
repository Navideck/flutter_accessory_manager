package com.navideck.flutter_accessory_manager

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothDevice.BOND_BONDED
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothProfile.ServiceListener
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Context.RECEIVER_EXPORTED
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.util.UUID

private const val TAG = "FlutterAccessoryManagerPlugin"

@SuppressLint("MissingPermission")
class FlutterAccessoryManagerPlugin : FlutterAccessoryPlatformChannel, FlutterPlugin,
    ActivityAware {
    private var callbackChannel: FlutterAccessoryCallbackChannel? = null
    private var mainThreadHandler: Handler? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var devices = mutableMapOf<String, BluetoothDevice>()
    private val pairResultFutures = mutableMapOf<String, (Result<Boolean>) -> Unit>()
    private var activity: Activity? = null
    private var mBtHidDevice: BluetoothHidDevice? = null
    private val actionBluetoothSelected =
        "android.bluetooth.devicepicker.action.DEVICE_SELECTED"

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FlutterAccessoryPlatformChannel.setUp(flutterPluginBinding.binaryMessenger, this)
        callbackChannel = FlutterAccessoryCallbackChannel(flutterPluginBinding.binaryMessenger)
        mainThreadHandler = Handler(Looper.getMainLooper())
        val context = flutterPluginBinding.applicationContext

        val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
        bluetoothAdapter = bluetoothManager?.adapter

        val intentFilter = IntentFilter(BluetoothDevice.ACTION_FOUND)
        intentFilter.addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(broadcastReceiver, intentFilter, RECEIVER_EXPORTED)
        } else {
            context.registerReceiver(broadcastReceiver, intentFilter)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        mainThreadHandler = null
        callbackChannel = null
        bluetoothAdapter = null
        binding.applicationContext.unregisterReceiver(broadcastReceiver)
    }


    override fun showBluetoothAccessoryPicker(
        withNames: List<String>,
        callback: (Result<Unit>) -> Unit,
    ) {
        try {
            activity?.registerReceiver(broadcastReceiver, IntentFilter(actionBluetoothSelected))
            val bluetoothPicker = Intent("android.bluetooth.devicepicker.action.LAUNCH")
            activity?.startActivity(bluetoothPicker)
            callback(Result.success(Unit))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError("Failed", e.toString())))
        }
    }

    override fun connect(deviceId: String, callback: (Result<Unit>) -> Unit) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val bluetoothDevice = getBluetoothDevice(deviceId)
                mBtHidDevice?.connect(bluetoothDevice)
                callback(Result.success(Unit))
            } else {
                throw FlutterError("Not Supported")
            }
        } catch (e: FlutterError) {
            callback(Result.failure(e))
        } catch (e: Exception) {
            callback(Result.failure(FlutterError(code = "Error", message = e.toString())))
        }
    }

    override fun disconnect(deviceId: String, callback: (Result<Unit>) -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val device = mBtHidDevice?.connectedDevices?.first { it.name == deviceId }
            if (device == null) {
                callback(Result.failure(FlutterError("NotFound", "Device not connected")))
                return
            }
            mBtHidDevice?.disconnect(device)
            callback(Result.success(Unit))
        } else {
            callback(Result.failure(FlutterError("Not Supported")))
        }
    }

    override fun sendReport(deviceId: String, data: ByteArray) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val device = mBtHidDevice?.connectedDevices?.firstOrNull { it.address == deviceId }
            if (device == null) {
                throw FlutterError("NotFound", "Device not connected")
            }
            mBtHidDevice?.sendReport(device, 0, data)
        } else {
            throw FlutterError("Not Supported")
        }
    }

    override fun setupSdp(config: SdpConfig) {
        val adapter = bluetoothAdapter ?: throw FlutterError("NoAdapter")
        val context = activity?.applicationContext ?: throw FlutterError("NoContext")
        val androidConfig = config.androidSdpConfig ?: throw FlutterError("InvalidAndroidConfig")

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            throw FlutterError("NotSupported", message = "Not supported on < P")
        }

        adapter.getProfileProxy(
            context,
            object : ServiceListener {
                @SuppressLint("NewApi")
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
                    if (profile != BluetoothProfile.HID_DEVICE) return
                    Log.d(TAG, "Got HID device")
                    mBtHidDevice = proxy as BluetoothHidDevice
                    mBtHidDevice?.registerApp(
                        BluetoothHidDeviceAppSdpSettings(
                            androidConfig.name,
                            androidConfig.description,
                            androidConfig.provider,
                            androidConfig.subclass.toByte(),
                            androidConfig.descriptors,
                        ),
                        null,
                        null,
                        ContextCompat.getMainExecutor(context),
                        bluetoothHidCallback
                    )
                }

                override fun onServiceDisconnected(profile: Int) {
                    if (profile != BluetoothProfile.HID_DEVICE) return
                    Log.d(TAG, "Lost HID device")
                    mBtHidDevice = null
                }
            },
            BluetoothProfile.HID_DEVICE
        )
    }

    @RequiresApi(Build.VERSION_CODES.P)
    val bluetoothHidCallback = object : BluetoothHidDevice.Callback() {
        override fun onGetReport(
            device: BluetoothDevice,
            type: Byte,
            id: Byte,
            bufferSize: Int,
        ) {
            Log.e(TAG, "onGetReport: device=$device type=$type id=$id bufferSize=$bufferSize")
        }

        override fun onConnectionStateChanged(
            device: BluetoothDevice,
            state: Int,
        ) {
            Log.e(TAG, "onConnectionStateChanged: device=$device state=$state")
        }
    }


    override fun startScan() {
        val adapter = bluetoothAdapter ?: return

        if (!adapter.isEnabled) {
            throw FlutterError("AdapterDisabled", "Bluetooth Adapter is disabled")
        }

        if (adapter.isDiscovering) {
            Log.d(TAG, "Already Discovering")
            return
        }

        if (!adapter.startDiscovery()) {
            throw FlutterError("failed", "Failed to start discovery")
        }

    }

    override fun stopScan() {
        val adapter = bluetoothAdapter ?: return

        if (!adapter.isEnabled) {
            throw FlutterError("AdapterDisabled", "Bluetooth Adapter is disabled")
        }

        if (!adapter.isDiscovering) {
            Log.d(TAG, "Already not discovering")
            return
        }

        if (!adapter.cancelDiscovery()) {
            throw FlutterError("failed", "Failed to cancel discovery")
        }
    }

    override fun isScanning(): Boolean {
        return bluetoothAdapter?.isDiscovering ?: false
    }

    override fun getPairedDevices(): List<com.navideck.flutter_accessory_manager.BluetoothDevice> {
        return bluetoothAdapter?.bondedDevices?.filter { it.type != BluetoothDevice.DEVICE_TYPE_LE }
            ?.map { it.toFlutter(null) } ?: listOf()
    }

    override fun pair(address: String, callback: (Result<Boolean>) -> Unit) {
        try {
            val remoteDevice =
                devices[address] ?: throw FlutterError("NotFound", "Device not found, please scan")
            val pendingFuture = pairResultFutures.remove(address)

            // If already paired, return and complete pending futures
            if (remoteDevice.bondState == BOND_BONDED) {
                pendingFuture?.let { it(Result.success(true)) }
                callback(Result.success(true))
                return
            }

            // throw error if we already have a pending future
            if (pendingFuture != null) {
                callback(
                    Result.failure(
                        FlutterError(
                            "InProgress",
                            "Pairing already in progress",
                            null
                        )
                    )
                )
                return
            }

            // Make a Pair request and complete future from Pair Update intent
            if (remoteDevice.createBond()) {
                pairResultFutures[address] = callback
            } else {
                callback(Result.failure(FlutterError("Failed", "Failed to pair", null)))
            }
        } catch (e: Exception) {
            callback(
                Result.failure(
                    FlutterError("Failed", e.toString(), null)
                )
            )
        }

    }

    private fun onBondStateUpdate(deviceId: String, bonded: Boolean, error: String? = null) {
        val future = pairResultFutures.remove(deviceId)
        future?.let { it(Result.success(bonded)) }
    }

    private fun onBluetoothDeviceSelectFromPicker(device: BluetoothDevice) {
        Log.d(TAG, "Selected device: ${device.name} ${device.address}")
        if (device.bondState == BOND_BONDED) {
            Log.d(TAG, "${device.name} already paired")
            return
        }
        // Create bond to selected device
        device.createBond()
    }

    // Try to get bluetooth device from, scanResultCache or hidConnected Devices or bondedDevices
    private fun getBluetoothDevice(deviceId: String): BluetoothDevice {
        val remoteDevice = devices[deviceId];
        if (remoteDevice != null) {
            return remoteDevice
        }


        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            for (device in mBtHidDevice?.getDevicesMatchingConnectionStates(
                intArrayOf(BluetoothProfile.STATE_CONNECTING, BluetoothProfile.STATE_CONNECTED)
            ) ?: mutableListOf()) {
                if (device.address == deviceId) {
                    return device
                }
            }
        }

        for (device in bluetoothAdapter?.bondedDevices?.toMutableList() ?: mutableListOf()) {
            if (device.address == deviceId) {
                return device
            }
        }

        throw FlutterError("NotFound", "Device not found, please scan")
    }

    private val broadcastReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val device: BluetoothDevice? =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(
                        BluetoothDevice.EXTRA_DEVICE,
                        BluetoothDevice::class.java
                    )
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                }

            if (device == null) return

            when (intent.action) {
                actionBluetoothSelected -> {
                    onBluetoothDeviceSelectFromPicker(device)
                }

                BluetoothDevice.ACTION_FOUND -> {
                    if (device.type == BluetoothDevice.DEVICE_TYPE_LE) return
                    val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE)
                    // Cache the result
                    devices[device.address] = device
                    mainThreadHandler?.post {
                        callbackChannel?.onDeviceDiscover(deviceArg = device.toFlutter(rssi.toLong())) {}
                    }
                }

                BluetoothDevice.ACTION_BOND_STATE_CHANGED -> {
                    when (intent.getIntExtra(
                        BluetoothDevice.EXTRA_BOND_STATE,
                        BluetoothDevice.ERROR
                    )) {
                        BluetoothDevice.BOND_BONDING -> {
                            Log.v(TAG, "${device.address} BOND_BONDING")
                        }

                        BluetoothDevice.BOND_BONDED -> {
                            onBondStateUpdate(device.address, true)
                        }

                        BluetoothDevice.ERROR -> {
                            onBondStateUpdate(device.address, false, "Failed to Pair")
                        }

                        BluetoothDevice.BOND_NONE -> {
                            Log.e(TAG, "${device.address} BOND_NONE")
                            onBondStateUpdate(device.address, false)
                        }
                    }
                }
            }
        }
    }

    private fun BluetoothDevice.toFlutter(rssi: Long?): com.navideck.flutter_accessory_manager.BluetoothDevice {
        return BluetoothDevice(
            address = this.address,
            name = this.name,
            rssi = rssi ?: 0,
            paired = this.bondState == BluetoothDevice.BOND_BONDED
        );
    }


    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

}
