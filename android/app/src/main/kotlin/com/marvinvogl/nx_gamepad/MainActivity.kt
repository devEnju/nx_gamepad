package com.marvinvogl.nx_gamepad

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.WindowManager.LayoutParams
import androidx.lifecycle.coroutineScope
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import kotlin.Boolean
import kotlin.Int
import kotlin.byteArrayOf


class MainActivity : FlutterActivity(), SensorEventListener {
    private val gyroscope = Gyroscope()

    private val buttonA = Button(KeyEvent.KEYCODE_BUTTON_A, 'a')
    private val buttonB = Button(KeyEvent.KEYCODE_BUTTON_B, 'b')
    private val buttonX = Button(KeyEvent.KEYCODE_BUTTON_X, 'x')
    private val buttonY = Button(KeyEvent.KEYCODE_BUTTON_Y, 'y')
    private val buttonL = Button(KeyEvent.KEYCODE_BUTTON_L1, 'l')
    private val buttonR = Button(KeyEvent.KEYCODE_BUTTON_R1, 'r')
    private val buttonJL = Button(KeyEvent.KEYCODE_BUTTON_THUMBL, 't')
    private val buttonJR = Button(KeyEvent.KEYCODE_BUTTON_THUMBR, 'z')
    private val buttonSelect = Button(KeyEvent.KEYCODE_BUTTON_SELECT, 'c')
    private val buttonStart = Button(KeyEvent.KEYCODE_BUTTON_START, 's')

    private val dpad = Dpad(MotionEvent.AXIS_HAT_X, MotionEvent.AXIS_HAT_Y)
    private val joystickL = Joystick(MotionEvent.AXIS_X, MotionEvent.AXIS_Y, 0b00010000)
    private val joystickR = Joystick(MotionEvent.AXIS_Z, MotionEvent.AXIS_RZ, 0b00100000)
    private val triggerL = Trigger(MotionEvent.AXIS_BRAKE, 0b01000000)
    private val triggerR = Trigger(MotionEvent.AXIS_GAS, 0b10000000)

    private lateinit var layoutParams: LayoutParams
    private lateinit var datagramSocket: DatagramSocket
    private lateinit var sensorManager: SensorManager

    private var gyroscopeSensor: Sensor? = null
    private var socketAddress: InetSocketAddress? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.marvinvogl.nx_gamepad/method",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAddress" -> {
                    val address = call.argument<String>("address")
                    val port = call.argument<String>("port")?.toInt()

                    if (address != null && port != null) {
                        socketAddress = InetSocketAddress(InetAddress.getByName(address), port)
                        result.success(true)
                    } else {
                        result.notImplemented()
                    }
                }
                "resetAddress" -> {
                    socketAddress = null
                    result.success(true)
                }
                "turnScreenOn" -> {
                    toggleScreenBrightness(LayoutParams.BRIGHTNESS_OVERRIDE_NONE)
                    result.success(true)
                }
                "turnScreenOff" -> {
                    toggleScreenBrightness(LayoutParams.BRIGHTNESS_OVERRIDE_OFF)
                    result.success(false)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        layoutParams = this.window.attributes
        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        gyroscopeSensor = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
    }

    override fun onResume() {
        super.onResume()

        datagramSocket = DatagramSocket()
        if (gyroscopeSensor != null) {
            sensorManager.registerListener(this, gyroscopeSensor, 10000)
        }
    }

    override fun onPause() {
        super.onPause()

        if (gyroscopeSensor != null) {
            sensorManager.unregisterListener(this)
        }
        datagramSocket.close()
    }

    override fun onSensorChanged(event: SensorEvent) {
        Gyroscope.bitfield = 0

        val a = gyroscope.onEvent(event)

        if (Gyroscope.bitfield != 0) {
            val buffer = byteArrayOf(Gyroscope.bitfield.toByte(), *a)
            lifecycle.coroutineScope.launch {
                send(buffer)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        Button.bitfield = 0

        val a1 = dpad.onEvent(event)
        val a2 = joystickL.onEvent(event)
        val a3 = joystickR.onEvent(event)
        val a4 = triggerL.onEvent(event)
        val a5 = triggerR.onEvent(event)

        if (Button.bitfield != 0) {
            val buffer = byteArrayOf(Button.bitfield.toByte(), *a1, *a2, *a3, *a4, *a5)
            lifecycle.coroutineScope.launch {
                send(buffer)
            }
            return true
        }
        return super.onGenericMotionEvent(event)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        Button.bitfield = 0

        var value = 0

        value += buttonA.onEvent(event)
        value += buttonB.onEvent(event)
        value += buttonX.onEvent(event)
        value += buttonY.onEvent(event)
        value += buttonL.onEvent(event)
        value += buttonR.onEvent(event)
        value += buttonJL.onEvent(event)
        value += buttonJR.onEvent(event)
        value += buttonSelect.onEvent(event)
        value += buttonStart.onEvent(event)

        if (Button.bitfield != 0) {
            val buffer = byteArrayOf(Button.bitfield.toByte(), value.toByte())
            lifecycle.coroutineScope.launch {
                send(buffer)
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    private suspend fun send(buf: ByteArray) = withContext(Dispatchers.IO) {
        if (socketAddress != null) {
            val packet = DatagramPacket(buf, buf.size, socketAddress)

            if (!datagramSocket.isClosed) {
                datagramSocket.send(packet)
            }
        }
    }

    private fun toggleScreenBrightness(brightness: Float) {
        layoutParams.screenBrightness = brightness
        this.window.attributes = layoutParams
    }
}
