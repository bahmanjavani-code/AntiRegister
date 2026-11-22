package com.example.companion.bridge

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.*
import android.text.InputType
import java.net.InetAddress

class BridgeProbeActivity : Activity() {
    private val controller = ProbeController()
    private var identity: Uri? = null
    private var peer: Uri? = null
    private lateinit var status: TextView
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val layout = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(24,24,24,24) }
        val host = EditText(this).apply { hint = "Hotspot IPv4"; setText("192.168.43.1") }
        val password = EditText(this).apply { hint = "PKCS12 password"; inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD }
        status = TextView(this).apply { text = "Select local pairing credentials" }
        fun button(label: String, action: () -> Unit) {
            layout.addView(Button(this).apply { text = label; setOnClickListener { action() } })
        }
        layout.addView(host)
        layout.addView(password)
        button("Select server PKCS12") { pick(1) }
        button("Select client certificate") { pick(2) }
        button("Start secure probe") {
            val secret = password.text.toString().toCharArray()
            try {
                val id = requireNotNull(identity)
                val cert = requireNotNull(peer)
                val keys = ProbeCredentials.loadIdentity(requireNotNull(contentResolver.openInputStream(id)), secret)
                val client = ProbeCredentials.loadPeer(requireNotNull(contentResolver.openInputStream(cert)))
                val context = PeerIdentity.context(keys, secret, client)
                val ip = host.text.toString().trim()
                require(ip.matches(Regex("[0-9.]+")))
                val fingerprint = ProbeCredentials.serverFingerprint(keys)
                controller.start(context, InetAddress.getByName(ip)) { message ->
                    runOnUiThread { if (!isDestroyed) status.text = "$message\nServer SHA256: $fingerprint" }
                }
            } catch (e: Exception) { status.text = "Unable to start: " + e.javaClass.simpleName }
            finally { secret.fill('\u0000'); password.text.clear() }
        }
        button("Stop") { controller.close(); status.text = "Stopped" }
        layout.addView(status)
        setContentView(ScrollView(this).apply { addView(layout) })
    }
    private fun pick(code: Int) {
        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE); type = "*/*"
        }, code)
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode != RESULT_OK) return
        when (requestCode) { 1 -> identity = data?.data; 2 -> peer = data?.data }
        status.text = "Server selected: ${identity != null}; client selected: ${peer != null}"
    }
    override fun onDestroy() { controller.close(); super.onDestroy() }
}
