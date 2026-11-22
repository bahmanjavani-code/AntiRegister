import Foundation
public struct PairingProfile: Codable, Equatable {
    public let host: String
    public let port: UInt16
    public let fingerprint: String
    public init(host: String, port: UInt16, fingerprint: String) throws {
        guard Self.isPrivateIPv4(host), port > 0, Self.decodeFingerprint(fingerprint) != nil else {
            throw BridgeWireError.invalidEnvelope
        }
        self.host = host
        self.port = port
        self.fingerprint = fingerprint.lowercased()
    }
    public static func isPrivateIPv4(_ host: String) -> Bool {
        let pieces = host.split(separator: ".", omittingEmptySubsequences: false)
        let octets = pieces.compactMap { UInt8($0) }
        guard pieces.count == 4, octets.count == 4, zip(pieces, octets).allSatisfy({ String($0.1) == String($0.0) }) else { return false }
        return octets[0] == 10 || (octets[0] == 172 && (16...31).contains(octets[1])) || (octets[0] == 192 && octets[1] == 168)
    }
    public static func decodeFingerprint(_ value: String) -> Data? {
        let chars = Array(value.utf8)
        guard chars.count == 64, chars.allSatisfy({ (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0) }) else { return nil }
        var result = Data()
        for i in stride(from: 0, to: 64, by: 2) {
            guard let byte = UInt8(String(decoding: chars[i..<i+2], as: UTF8.self), radix: 16) else { return nil }
            result.append(byte)
        }
        return result
    }
    private enum CodingKeys: String, CodingKey { case host, port, fingerprint }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(host: c.decode(String.self, forKey: .host), port: c.decode(UInt16.self, forKey: .port), fingerprint: c.decode(String.self, forKey: .fingerprint))
    }
}
