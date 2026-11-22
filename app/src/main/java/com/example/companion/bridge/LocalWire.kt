package com.example.companion.bridge

import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.EOFException
import java.io.IOException

data class LocalFrame(val kind: Int, val body: ByteArray)

/** Wire-compatible with Stage 5 RFCOMM framing and the Swift BridgeWire. */
object LocalWire {
    const val MAX_FRAME = 65536
    fun read(input: DataInputStream): LocalFrame {
        val length = input.readInt()
        if (length !in 1..MAX_FRAME) throw IOException("Invalid frame length")
        val kind = input.readUnsignedByte()
        return LocalFrame(kind, ByteArray(length - 1).also { input.readFully(it) })
    }
    fun write(output: DataOutputStream, frame: LocalFrame) {
        require(frame.kind in 0..255 && frame.body.size < MAX_FRAME)
        output.writeInt(frame.body.size + 1)
        output.writeByte(frame.kind)
        output.write(frame.body)
        output.flush()
    }
}
