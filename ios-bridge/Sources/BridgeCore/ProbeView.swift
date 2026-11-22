#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers
import Network

public struct ProbeView: View {
    @State private var host = "192.168.43.1"
    @State private var fingerprint = ""
    @State private var password = ""
    @State private var identityData: Data?
    @State private var importing = false
    @State private var status = "Not connected"
    @State private var connection: LocalBridgeConnection?
    public init() {}
    public var body: some View {
        Form {
            Section("Pairing") {
                TextField("Poco IP", text: $host).keyboardType(.decimalPad)
                TextField("Server SHA-256", text: $fingerprint).autocorrectionDisabled().textInputAutocapitalization(.never)
                SecureField("Identity password", text: $password)
                Button("Import client identity") { importing = true }
                Text(identityData == nil ? "No identity" : "Identity loaded")
            }
            Section("Connection") {
                Button("Test connection") { connect() }.disabled(identityData == nil || connection != nil)
                Button("Disconnect") { connection?.stop(); connection = nil; status = "Disconnected" }
                Text(status)
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pkcs12]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                identityData = try Data(contentsOf: url)
            } catch { status = "Identity import failed" }
        }
        .onDisappear { connection?.stop(); connection = nil }
    }
    private func connect() {
        do {
            let profile = try PairingProfile(host: host, port: 8443, fingerprint: fingerprint)
            guard let data = identityData, let pin = PairingProfile.decodeFingerprint(profile.fingerprint),
                  let port = NWEndpoint.Port(rawValue: profile.port) else { return }
            let identity = try ClientIdentity.load(pkcs12: data, password: password)
            password = ""
            let request = try BridgeProbe.request()
            let link = LocalBridgeConnection(host: NWEndpoint.Host(profile.host), port: port, tls: PeerPin.options(certificateSHA256: pin, identity: identity))
            connection = link
            status = "Connecting"
            link.start(onState: { state in
                switch state {
                case .ready:
                    link.send(request.frame) { error in
                        if error != nil { DispatchQueue.main.async { status = "Send failed" } }
                    }
                case .failed:
                    DispatchQueue.main.async { status = "Connection failed"; connection = nil }
                default: break
                }
            }, onFrame: { frame in
                if BridgeProbe.matches(frame, id: request.id) {
                    DispatchQueue.main.async { status = "Authenticated probe passed" }
                }
            }, onError: { _ in
                DispatchQueue.main.async { status = "Connection ended"; connection = nil }
            })
        } catch { status = "Invalid pairing or identity" }
    }
}
#endif
