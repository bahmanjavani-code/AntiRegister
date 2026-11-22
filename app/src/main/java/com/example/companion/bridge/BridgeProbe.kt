package com.example.companion.bridge

import com.example.companion.protocol.Message
import com.example.companion.protocol.MessageType

/** Read-only connectivity probe. Never dispatches SMS or telephony commands. */
object BridgeProbe {
    fun reply(frame: LocalFrame): LocalFrame? {
        if (frame.kind != 1) return null
        val request = Message.decode(frame.body) ?: return null
        if (request.type != MessageType.PING) return null
        return LocalFrame(1, Message(MessageType.PONG, request.payload).encode())
    }
    fun serve(session: LocalTlsSession) {
        session.accept { frame, send -> reply(frame)?.let(send) }
    }
}
