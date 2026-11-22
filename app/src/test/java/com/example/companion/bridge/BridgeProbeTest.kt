package com.example.companion.bridge

import com.example.companion.protocol.Message
import com.example.companion.protocol.MessageType
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class BridgeProbeTest {
    @Test fun echoPing() {
        val ping = Message(MessageType.PING, JSONObject().put("t",42))
        val result = BridgeProbe.reply(LocalFrame(1,ping.encode()))!!
        val decoded = Message.decode(result.body)!!
        assertEquals(MessageType.PONG,decoded.type)
        assertEquals(42,decoded.payload.getInt("t"))
    }
    @Test fun rejectCommands() {
        for (type in MessageType.values().filter { it != MessageType.PING }) {
            assertNull(BridgeProbe.reply(LocalFrame(1,Message(type).encode())))
        }
        assertNull(BridgeProbe.reply(LocalFrame(2,byteArrayOf(1))))
        assertNull(BridgeProbe.reply(LocalFrame(1,byteArrayOf(1))))
    }
}
