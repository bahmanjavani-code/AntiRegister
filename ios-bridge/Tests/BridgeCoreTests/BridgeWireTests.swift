import XCTest
import Foundation
@testable import BridgeCore
final class BridgeWireTests: XCTestCase {
    func testFragmentationAndCoalescing() throws {
        let a = BridgeFrame(kind: 1, body: Data([10, 20]))
        let b = BridgeFrame(kind: 2, body: Data([30]))
        let bytes = try BridgeWire.encode(a) + BridgeWire.encode(b)
        XCTAssertEqual(Array(bytes.prefix(5)), [0,0,0,3,1])
        var decoder = BridgeWire()
        XCTAssertEqual(try decoder.receive(Data(bytes.prefix(3))), [])
        XCTAssertEqual(try decoder.receive(Data(bytes.dropFirst(3))), [a,b])
    }
    func testInvalidLengths() throws {
        for bytes: [UInt8] in [[0,0,0,0], [0,1,0,1]] {
            var decoder = BridgeWire()
            XCTAssertThrowsError(try decoder.receive(Data(bytes)))
        }
    }
    func testControl() throws {
        let f = try BridgeWire.control(type: "PING")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: f.body) as? [String:Any])
        XCTAssertEqual(json["type"] as? String, "PING")
        XCTAssertEqual(json["v"] as? Int, 1)
    }
}
