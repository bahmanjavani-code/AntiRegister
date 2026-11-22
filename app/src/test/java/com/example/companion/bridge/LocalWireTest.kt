package com.example.companion.bridge

import org.junit.Assert.*
import org.junit.Test
import java.io.*
class LocalWireTest {
    @Test fun roundTrip() {
        val bytes = ByteArrayOutputStream()
        LocalWire.write(DataOutputStream(bytes), LocalFrame(2, byteArrayOf(10,20)))
        assertArrayEquals(byteArrayOf(0,0,0,3,2,10,20),bytes.toByteArray())
        val frame = LocalWire.read(DataInputStream(ByteArrayInputStream(bytes.toByteArray())))
        assertEquals(2,frame.kind)
        assertArrayEquals(byteArrayOf(10,20),frame.body)
    }
    @Test(expected = IOException::class) fun invalidLength() {
        LocalWire.read(DataInputStream(ByteArrayInputStream(byteArrayOf(0,1,0,1))))
    }
}
