#if canImport(Security)
import Foundation
import Security
import CryptoKit
import Network

public enum PeerPin {
    public static func options(certificateSHA256: Data, identity: sec_identity_t) -> NWProtocolTLS.Options {
        let options = NWProtocolTLS.Options()
        let security = options.securityProtocolOptions
        sec_protocol_options_set_local_identity(security, identity)
        sec_protocol_options_set_min_tls_protocol_version(security, .TLSv12)
        sec_protocol_options_set_verify_block(security, { _, trust, complete in
            let reference = sec_trust_copy_ref(trust).takeRetainedValue()
            guard certificateSHA256.count == 32,
                  let chain = SecTrustCopyCertificateChain(reference) as? [SecCertificate],
                  let leaf = chain.first else { complete(false); return }
            let digest = Data(SHA256.hash(data: SecCertificateCopyData(leaf) as Data))
            complete(digest == certificateSHA256)
        }, DispatchQueue(label: "bridge.peer.pin"))
        return options
    }
}
#endif
