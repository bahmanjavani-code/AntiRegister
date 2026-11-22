import Foundation
import XCTest
@testable import BridgeCore

final class PairingProfileTests: XCTestCase {
    private let pin = String(repeating: "ab", count: 32)
    func testPrivateAddresses() throws {
        for host in ["192.168.43.1", "10.0.0.1", "172.16.0.1", "172.31.0.1"] {
            let profile = try PairingProfile(host: host, port: 8443, fingerprint: pin)
            XCTAssertEqual(try JSONDecoder().decode(PairingProfile.self, from: JSONEncoder().encode(profile)), profile)
        }
    }
    func testRejectInvalidInput() {
        for host in ["8.8.8.8", "127.0.0.1", "172.32.0.1", "192.168.256.1", "192.168.01.1", "example.com"] {
            XCTAssertThrowsError(try PairingProfile(host: host, port: 8443, fingerprint: pin))
        }
        XCTAssertThrowsError(try PairingProfile(host: "10.0.0.1", port: 0, fingerprint: pin))
        XCTAssertNil(PairingProfile.decodeFingerprint(String(repeating: "zz", count: 32)))
        XCTAssertEqual(PairingProfile.decodeFingerprint(pin), Data(repeating: 0xab, count: 32))
    }
}
