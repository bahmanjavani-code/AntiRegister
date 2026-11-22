import XCTest
@testable import BridgeCore
final class BridgeProbeTests: XCTestCase {
    func testMatchingReply() throws {
        let request = try BridgeProbe.request()
        let reply = try BridgeWire.control(type: "PONG", payload: ["probe": request.id])
        XCTAssertTrue(BridgeProbe.matches(reply, id: request.id))
        XCTAssertFalse(BridgeProbe.matches(reply, id: "other"))
        XCTAssertFalse(BridgeProbe.matches(request.frame, id: request.id))
    }
}
