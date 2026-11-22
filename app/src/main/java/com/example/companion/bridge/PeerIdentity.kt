package com.example.companion.bridge

import java.security.KeyStore
import java.security.cert.X509Certificate
import java.security.MessageDigest
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.SSLContext

object PeerIdentity {
    fun fingerprint(certificate: X509Certificate): ByteArray =
        MessageDigest.getInstance("SHA-256").digest(certificate.encoded)

    /** Explicitly provisioned peer certificate; never use the system-wide trust store. */
    fun context(identity: KeyStore, password: CharArray, peer: X509Certificate): SSLContext {
        val trust = KeyStore.getInstance(KeyStore.getDefaultType()).apply {
            load(null, null)
            setCertificateEntry("paired-peer", peer)
        }
        val km = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm())
        km.init(identity, password)
        val tm = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
        tm.init(trust)
        return SSLContext.getInstance("TLS").apply { init(km.keyManagers, tm.trustManagers, null) }
    }
}
