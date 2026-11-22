package com.example.companion.bridge

import java.io.Closeable
import java.io.DataInputStream
import java.io.DataOutputStream
import java.net.InetAddress
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLServerSocket
import javax.net.ssl.SSLSocket

/** Experimental transport only; not started by the application.
 * The supplied SSLContext must contain a server identity and trust only paired client identities.
 * Never bind to a wildcard address or dispatch commands before mutual TLS succeeds.
 */
class LocalTlsSession(context: SSLContext, address: InetAddress, port: Int) : Closeable {
    private val listener: SSLServerSocket
    init {
        require(address.isSiteLocalAddress && !address.isAnyLocalAddress && !address.isLoopbackAddress)
        listener = context.serverSocketFactory.createServerSocket(port, 1, address) as SSLServerSocket
        listener.needClientAuth = true
        listener.enabledProtocols = listener.supportedProtocols.filter { it == "TLSv1.3" || it == "TLSv1.2" }.toTypedArray()
    }
    val localPort: Int get() = listener.localPort
    fun accept(onFrame: (LocalFrame, (LocalFrame) -> Unit) -> Unit) {
        (listener.accept() as SSLSocket).use { peer ->
            peer.soTimeout = 10000
            peer.startHandshake()
            val input = DataInputStream(peer.inputStream)
            val output = DataOutputStream(peer.outputStream)
            val lock = Any()
            while (!peer.isClosed) {
                val frame = LocalWire.read(input)
                onFrame(frame) { reply -> synchronized(lock) { LocalWire.write(output, reply) } }
            }
        }
    }
    override fun close() = listener.close()
}
