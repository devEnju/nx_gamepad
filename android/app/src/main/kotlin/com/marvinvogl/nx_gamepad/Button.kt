package com.marvinvogl.nx_gamepad

import android.view.KeyEvent

class Button(
    private val code: Int,
    private val key: Char,
) {
    companion object {
        var bitfield: Int = 0
    }
    private val bitmask = 0b00000100

    private var isPressed = false

    fun onEvent(event: KeyEvent): Int {
        if (event.keyCode == code) {
            if (event.action == KeyEvent.ACTION_DOWN) {
                bitfield += bitmask
                return getKeyDownData()
            }
            if (event.action == KeyEvent.ACTION_UP) {
                bitfield += bitmask
                return getKeyUpData()
            }
        }
        return 0
    }

    private fun getKeyDownData(): Int {
        if (!isPressed) {
            isPressed = true

            return key.code
        }
        return 0
    }

    private fun getKeyUpData(): Int {
        if (isPressed) {
            isPressed = false

            return key.uppercaseChar().code
        }
        return 0
    }
}