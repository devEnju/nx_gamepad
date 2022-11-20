@file:Suppress("PLATFORM_CLASS_MAPPED_TO_KOTLIN")

package com.marvinvogl.nx_gamepad

import android.hardware.Sensor
import android.hardware.SensorEvent
import java.lang.Float

class Gyroscope {
    companion object {
        var bitfield: Int = 0
    }
    private val bitmask = 0b00000010

    private var x = 0
    private var y = 0
    private var z = 0

    fun onEvent(event: SensorEvent): ByteArray {
        if (event.sensor.type == Sensor.TYPE_GYROSCOPE) {
            val x = Float.floatToIntBits(event.values[0])
            val y = Float.floatToIntBits(event.values[1])
            val z = Float.floatToIntBits(event.values[2])

            if (this.x != x || this.y != y || this.z != z) {
                bitfield = bitmask
                return getSensorData(x, y, z)
            }
        }
        return byteArrayOf()
    }

    private fun getSensorData(x: Int, y: Int, z: Int): ByteArray {
        this.x = x
        this.y = y
        this.z = z

        return byteArrayOf(
            (x shr 24).toByte(),
            (x shr 16).toByte(),
            (x shr 8).toByte(),
            x.toByte(),
            (y shr 24).toByte(),
            (y shr 16).toByte(),
            (y shr 8).toByte(),
            y.toByte(),
            (z shr 24).toByte(),
            (z shr 16).toByte(),
            (z shr 8).toByte(),
            z.toByte(),
        )
    }
}