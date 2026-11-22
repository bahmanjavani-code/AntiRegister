#if canImport(Security)
import Foundation
import Security

public enum ClientIdentityError: Error { case importFailed(OSStatus), missingIdentity }
public enum ClientIdentity {
    public static func load(pkcs12: Data, password: String) throws -> sec_identity_t {
        var items: CFArray?
        let status = SecPKCS12Import(pkcs12 as CFData, [kSecImportExportPassphrase as String: password] as CFDictionary, &items)
        guard status == errSecSuccess else { throw ClientIdentityError.importFailed(status) }
        guard let entries = items as? [[String: Any]],
              let raw = entries.first?[kSecImportItemIdentity as String],
              CFGetTypeID(raw as CFTypeRef) == SecIdentityGetTypeID()
        else { throw ClientIdentityError.missingIdentity }
        let identity = raw as! SecIdentity
        guard let result = sec_identity_create(identity) else { throw ClientIdentityError.missingIdentity }
        return result
    }
}
#endif
