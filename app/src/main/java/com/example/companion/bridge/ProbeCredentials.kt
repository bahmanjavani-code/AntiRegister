package com.example.companion.bridge

import java.io.InputStream
import java.security.KeyStore
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate

object ProbeCredentials {
    fun loadIdentity(input: InputStream, password: CharArray): KeyStore =
        KeyStore.getInstance("PKCS12").apply { input.use { load(it, password) } }

    fun loadPeer(input: InputStream): X509Certificate =
        input.use { CertificateFactory.getInstance("X.509").generateCertificate(it) as X509Certificate }

    fun serverFingerprint(identity: KeyStore): String {
        val aliases = identity.aliases()
        while (aliases.hasMoreElements()) {
            val alias = aliases.nextElement()
            if (!identity.isKeyEntry(alias)) continue
            val certificate = identity.getCertificate(alias) as? X509Certificate ?: continue
            return PeerIdentity.fingerprint(certificate).joinToString("") { "%02x".format(it.toInt() and 255) }
        }
        throw IllegalArgumentException("No server identity")
    }
}
