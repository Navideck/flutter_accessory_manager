package com.navideck.flutter_accessory_manager

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Context.RECEIVER_EXPORTED
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin

private const val TAG = "FlutterAccessoryManagerPlugin"

@SuppressLint("MissingPermission")
class FlutterAccessoryManagerPlugin : FlutterAccessoryPlatformChannel, FlutterPlugin {
    private var callbackChannel: FlutterAccessoryCallbackChannel? = null
    private var mainThreadHandler: Handler? = null
    private var bluetoothAdapter: BluetoothAdapter? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FlutterAccessoryPlatformChannel.setUp(flutterPluginBinding.binaryMessenger, this)
        callbackChannel = FlutterAccessoryCallbackChannel(flutterPluginBinding.binaryMessenger)
        mainThreadHandler = Handler(Looper.getMainLooper())
        val context = flutterPluginBinding.applicationContext
        val bluetoothManager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
        bluetoothAdapter = bluetoothManager?.adapter
        val intentFilter = IntentFilter(BluetoothDevice.ACTION_FOUND)
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

    override fun showBluetoothAccessoryPicker(callback: (Result<Unit>) -> Unit) {
        callback(Result.failure(FlutterError("NotImplemented", "Not implemented on this platform")))
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

    private val broadcastReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val device: BluetoothDevice? =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(
                        BluetoothDevice.EXTRA_DEVICE,
                        BluetoothDevice::class.java
                    )
                } else {
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                }
            if (device == null || device.type == BluetoothDevice.DEVICE_TYPE_LE) return
            val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE)

            mainThreadHandler?.post {
                callbackChannel?.onDeviceDiscover(deviceArg = device.toFlutter(rssi.toLong())) {}
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
}
