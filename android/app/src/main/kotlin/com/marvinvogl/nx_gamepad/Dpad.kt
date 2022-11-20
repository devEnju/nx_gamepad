package com.marvinvogl.nx_gamepad

import android.view.MotionEvent

class Dpad(
    private val axisX: Int,
    private val axisY: Int,
) {
    private val bitmask = 0b00001000

    private var x = 0.0f
    private var y = 0.0f

    fun onEvent(event: MotionEvent): ByteArray {
        if (event.action == MotionEvent.ACTION_MOVE) {
            val x = event.getAxisValue(axisX)
            val y = event.getAxisValue(axisY)

            if (this.x != x || this.y != y) {
                Button.bitfield += bitmask
                return getMotionData(x, y)
            }
        }
        return byteArrayOf()
    }

    private fun getMotionData(x: Float, y: Float): ByteArray {
        this.x = x
        this.y = y

        var value = 0

        if (y < 0) {
            value += 0b1
        } else if (y > 0) {
            value += 0b10
        }
        if (x < 0) {
            value += 0b100
        } else if (x > 0) {
            value += 0b1000
        }

        return byteArrayOf(value.toByte())
    }
}