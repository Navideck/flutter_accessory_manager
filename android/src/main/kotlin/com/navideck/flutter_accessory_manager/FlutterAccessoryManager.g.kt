// Autogenerated from Pigeon (v22.7.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon
@file:Suppress("UNCHECKED_CAST", "ArrayInDataClass")

package com.navideck.flutter_accessory_manager

import android.util.Log
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MessageCodec
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

private fun wrapResult(result: Any?): List<Any?> {
  return listOf(result)
}

private fun wrapError(exception: Throwable): List<Any?> {
  return if (exception is FlutterError) {
    listOf(
      exception.code,
      exception.message,
      exception.details
    )
  } else {
    listOf(
      exception.javaClass.simpleName,
      exception.toString(),
      "Cause: " + exception.cause + ", Stacktrace: " + Log.getStackTraceString(exception)
    )
  }
}

private fun createConnectionError(channelName: String): FlutterError {
  return FlutterError("channel-error",  "Unable to establish connection on channel: '$channelName'.", "")}

/**
 * Error class for passing custom error details to Flutter via a thrown PlatformException.
 * @property code The error code.
 * @property message The error message.
 * @property details The error details. Must be a datatype supported by the api codec.
 */
class FlutterError (
  val code: String,
  override val message: String? = null,
  val details: Any? = null
) : Throwable()

/** Generated class from Pigeon that represents data sent in messages. */
data class BluetoothDevice (
  val address: String,
  val name: String? = null,
  val paired: Boolean,
  val rssi: Long
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): BluetoothDevice {
      val address = pigeonVar_list[0] as String
      val name = pigeonVar_list[1] as String?
      val paired = pigeonVar_list[2] as Boolean
      val rssi = pigeonVar_list[3] as Long
      return BluetoothDevice(address, name, paired, rssi)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      address,
      name,
      paired,
      rssi,
    )
  }
}

/** Generated class from Pigeon that represents data sent in messages. */
data class SdpConfig (
  val macSdpConfig: MacSdpConfig? = null,
  val androidSdpConfig: AndroidSdpConfig? = null
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): SdpConfig {
      val macSdpConfig = pigeonVar_list[0] as MacSdpConfig?
      val androidSdpConfig = pigeonVar_list[1] as AndroidSdpConfig?
      return SdpConfig(macSdpConfig, androidSdpConfig)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      macSdpConfig,
      androidSdpConfig,
    )
  }
}

/** Generated class from Pigeon that represents data sent in messages. */
data class MacSdpConfig (
  val sdpPlistFile: String? = null,
  val data: Map<String, Any>? = null
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): MacSdpConfig {
      val sdpPlistFile = pigeonVar_list[0] as String?
      val data = pigeonVar_list[1] as Map<String, Any>?
      return MacSdpConfig(sdpPlistFile, data)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      sdpPlistFile,
      data,
    )
  }
}

/** Generated class from Pigeon that represents data sent in messages. */
data class AndroidSdpConfig (
  val name: String,
  val description: String,
  val provider: String,
  val subclass: Long,
  val descriptors: ByteArray
)
 {
  companion object {
    fun fromList(pigeonVar_list: List<Any?>): AndroidSdpConfig {
      val name = pigeonVar_list[0] as String
      val description = pigeonVar_list[1] as String
      val provider = pigeonVar_list[2] as String
      val subclass = pigeonVar_list[3] as Long
      val descriptors = pigeonVar_list[4] as ByteArray
      return AndroidSdpConfig(name, description, provider, subclass, descriptors)
    }
  }
  fun toList(): List<Any?> {
    return listOf(
      name,
      description,
      provider,
      subclass,
      descriptors,
    )
  }
}
private open class FlutterAccessoryManagerPigeonCodec : StandardMessageCodec() {
  override fun readValueOfType(type: Byte, buffer: ByteBuffer): Any? {
    return when (type) {
      129.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          BluetoothDevice.fromList(it)
        }
      }
      130.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          SdpConfig.fromList(it)
        }
      }
      131.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          MacSdpConfig.fromList(it)
        }
      }
      132.toByte() -> {
        return (readValue(buffer) as? List<Any?>)?.let {
          AndroidSdpConfig.fromList(it)
        }
      }
      else -> super.readValueOfType(type, buffer)
    }
  }
  override fun writeValue(stream: ByteArrayOutputStream, value: Any?)   {
    when (value) {
      is BluetoothDevice -> {
        stream.write(129)
        writeValue(stream, value.toList())
      }
      is SdpConfig -> {
        stream.write(130)
        writeValue(stream, value.toList())
      }
      is MacSdpConfig -> {
        stream.write(131)
        writeValue(stream, value.toList())
      }
      is AndroidSdpConfig -> {
        stream.write(132)
        writeValue(stream, value.toList())
      }
      else -> super.writeValue(stream, value)
    }
  }
}


/**
 * Flutter -> Native
 *
 * Generated interface from Pigeon that represents a handler of messages from Flutter.
 */
interface FlutterAccessoryPlatformChannel {
  fun showBluetoothAccessoryPicker(withNames: List<String>, callback: (Result<Unit>) -> Unit)
  fun connect(deviceId: String, callback: (Result<Unit>) -> Unit)
  fun disconnect(deviceId: String, callback: (Result<Unit>) -> Unit)
  fun setupSdp(config: SdpConfig)
  fun sendReport(deviceId: String, data: ByteArray)
  fun startScan()
  fun stopScan()
  fun isScanning(): Boolean
  fun getPairedDevices(): List<BluetoothDevice>
  fun pair(address: String, callback: (Result<Boolean>) -> Unit)

  companion object {
    /** The codec used by FlutterAccessoryPlatformChannel. */
    val codec: MessageCodec<Any?> by lazy {
      FlutterAccessoryManagerPigeonCodec()
    }
    /** Sets up an instance of `FlutterAccessoryPlatformChannel` to handle messages through the `binaryMessenger`. */
    @JvmOverloads
    fun setUp(binaryMessenger: BinaryMessenger, api: FlutterAccessoryPlatformChannel?, messageChannelSuffix: String = "") {
      val separatedMessageChannelSuffix = if (messageChannelSuffix.isNotEmpty()) ".$messageChannelSuffix" else ""
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.showBluetoothAccessoryPicker$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val withNamesArg = args[0] as List<String>
            api.showBluetoothAccessoryPicker(withNamesArg) { result: Result<Unit> ->
              val error = result.exceptionOrNull()
              if (error != null) {
                reply.reply(wrapError(error))
              } else {
                reply.reply(wrapResult(null))
              }
            }
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.connect$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val deviceIdArg = args[0] as String
            api.connect(deviceIdArg) { result: Result<Unit> ->
              val error = result.exceptionOrNull()
              if (error != null) {
                reply.reply(wrapError(error))
              } else {
                reply.reply(wrapResult(null))
              }
            }
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.disconnect$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val deviceIdArg = args[0] as String
            api.disconnect(deviceIdArg) { result: Result<Unit> ->
              val error = result.exceptionOrNull()
              if (error != null) {
                reply.reply(wrapError(error))
              } else {
                reply.reply(wrapResult(null))
              }
            }
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.setupSdp$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val configArg = args[0] as SdpConfig
            val wrapped: List<Any?> = try {
              api.setupSdp(configArg)
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.sendReport$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val deviceIdArg = args[0] as String
            val dataArg = args[1] as ByteArray
            val wrapped: List<Any?> = try {
              api.sendReport(deviceIdArg, dataArg)
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.startScan$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            val wrapped: List<Any?> = try {
              api.startScan()
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.stopScan$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            val wrapped: List<Any?> = try {
              api.stopScan()
              listOf(null)
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.isScanning$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            val wrapped: List<Any?> = try {
              listOf(api.isScanning())
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.getPairedDevices$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { _, reply ->
            val wrapped: List<Any?> = try {
              listOf(api.getPairedDevices())
            } catch (exception: Throwable) {
              wrapError(exception)
            }
            reply.reply(wrapped)
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
      run {
        val channel = BasicMessageChannel<Any?>(binaryMessenger, "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryPlatformChannel.pair$separatedMessageChannelSuffix", codec)
        if (api != null) {
          channel.setMessageHandler { message, reply ->
            val args = message as List<Any?>
            val addressArg = args[0] as String
            api.pair(addressArg) { result: Result<Boolean> ->
              val error = result.exceptionOrNull()
              if (error != null) {
                reply.reply(wrapError(error))
              } else {
                val data = result.getOrNull()
                reply.reply(wrapResult(data))
              }
            }
          }
        } else {
          channel.setMessageHandler(null)
        }
      }
    }
  }
}
/**
 * Native -> Flutter
 *
 * Generated class from Pigeon that represents Flutter messages that can be called from Kotlin.
 */
class FlutterAccessoryCallbackChannel(private val binaryMessenger: BinaryMessenger, private val messageChannelSuffix: String = "") {
  companion object {
    /** The codec used by FlutterAccessoryCallbackChannel. */
    val codec: MessageCodec<Any?> by lazy {
      FlutterAccessoryManagerPigeonCodec()
    }
  }
  fun onDeviceDiscover(deviceArg: BluetoothDevice, callback: (Result<Unit>) -> Unit)
{
    val separatedMessageChannelSuffix = if (messageChannelSuffix.isNotEmpty()) ".$messageChannelSuffix" else ""
    val channelName = "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.onDeviceDiscover$separatedMessageChannelSuffix"
    val channel = BasicMessageChannel<Any?>(binaryMessenger, channelName, codec)
    channel.send(listOf(deviceArg)) {
      if (it is List<*>) {
        if (it.size > 1) {
          callback(Result.failure(FlutterError(it[0] as String, it[1] as String, it[2] as String?)))
        } else {
          callback(Result.success(Unit))
        }
      } else {
        callback(Result.failure(createConnectionError(channelName)))
      } 
    }
  }
  fun onDeviceRemoved(deviceArg: BluetoothDevice, callback: (Result<Unit>) -> Unit)
{
    val separatedMessageChannelSuffix = if (messageChannelSuffix.isNotEmpty()) ".$messageChannelSuffix" else ""
    val channelName = "dev.flutter.pigeon.flutter_accessory_manager.FlutterAccessoryCallbackChannel.onDeviceRemoved$separatedMessageChannelSuffix"
    val channel = BasicMessageChannel<Any?>(binaryMessenger, channelName, codec)
    channel.send(listOf(deviceArg)) {
      if (it is List<*>) {
        if (it.size > 1) {
          callback(Result.failure(FlutterError(it[0] as String, it[1] as String, it[2] as String?)))
        } else {
          callback(Result.success(Unit))
        }
      } else {
        callback(Result.failure(createConnectionError(channelName)))
      } 
    }
  }
}
