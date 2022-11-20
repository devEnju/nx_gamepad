@file:Suppress("PLATFORM_CLASS_MAPPED_TO_KOTLIN")

package com.marvinvogl.nx_gamepad

import android.view.MotionEvent
import java.lang.Float

class Joystick(
    private val axisX: Int,
    private val axisY: Int,
    private val bitmask: Int,
) {
    private var x = 0
    private var y = 0

    fun onEvent(event: MotionEvent): ByteArray {
        if (event.action == MotionEvent.ACTION_MOVE) {
            val x = Float.floatToIntBits(event.getAxisValue(axisX))
            val y = Float.floatToIntBits(event.getAxisValue(axisY))

            if (this.x != x || this.y != y) {
                Button.bitfield += bitmask
                return getMotionData(x, y)
            }
        }
        return byteArrayOf()
    }

    private fun getMotionData(x: Int, y: Int): ByteArray {
        this.x = x
        this.y = y

        return byteArrayOf(
            (x shr 24).toByte(),
            (x shr 16).toByte(),
            (x shr 8).toByte(),
            x.toByte(),
            (y shr 24).toByte(),
            (y shr 16).toByte(),
            (y shr 8).toByte(),
            y.toByte(),
        )
    }
}