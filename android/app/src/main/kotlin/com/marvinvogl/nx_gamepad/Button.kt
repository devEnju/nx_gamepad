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
                if (!isPressed) {
                    bitfield += bitmask
                    return getKeyDownData()
                }
            }
            if (event.action == KeyEvent.ACTION_UP) {
                if (isPressed) {
                    bitfield += bitmask
                    return getKeyUpData()
                }
            }
        }
        return 0
    }

    private fun getKeyDownData(): Int {
        isPressed = true

        return key.code
    }

    private fun getKeyUpData(): Int {
        isPressed = false

        return key.uppercaseChar().code
    }
}