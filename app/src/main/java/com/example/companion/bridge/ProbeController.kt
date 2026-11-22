package com.example.companion.bridge

import java.io.Closeable
import java.net.InetAddress
import javax.net.ssl.SSLContext
import kotlin.concurrent.thread

/** Foreground diagnostic only. No SMS or call dispatch. */
class ProbeController : Closeable {
    private var session: LocalTlsSession? = null
    @Synchronized fun start(context: SSLContext, address: InetAddress, status: (String) -> Unit) {
        check(session == null)
        val server = LocalTlsSession(context, address, 8443)
        session = server
        thread(name = "local-bridge-probe", isDaemon = true) {
            try {
                status("Listening on port 8443")
                BridgeProbe.serve(server)
            } catch (_: Exception) {
                status("Probe session ended")
            } finally {
                synchronized(this) {
                    server.close()
                    if (session === server) session = null
                }
            }
        }
    }
    @Synchronized override fun close() {
        session?.close()
        session = null
    }
}
