@file:Suppress("PLATFORM_CLASS_MAPPED_TO_KOTLIN")

package com.marvinvogl.nx_gamepad

import android.view.MotionEvent
import java.lang.Float

class Trigger(
    private val axis: Int,
    private val bitmask: Int,
) {
    private var z = 0

    fun onEvent(event: MotionEvent): ByteArray {
        if (event.action == MotionEvent.ACTION_MOVE) {
            val z = Float.floatToIntBits(event.getAxisValue(axis))

            if (this.z != z) {
                Button.bitfield += bitmask
                return getMotionData(z)
            }
        }
        return byteArrayOf()
    }

    private fun getMotionData(z: Int): ByteArray {
        this.z = z

        return byteArrayOf(
            (z shr 24).toByte(),
            (z shr 16).toByte(),
            (z shr 8).toByte(),
            z.toByte(),
        )
    }
}