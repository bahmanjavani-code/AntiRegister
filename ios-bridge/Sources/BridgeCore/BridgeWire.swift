import Foundation

/// AntiRegister Stage 5 framing, independent of the eventual BLE or Wi-Fi transport.
public struct BridgeFrame: Equatable {
    public let kind: UInt8
    public let body: Data
    public init(kind: UInt8, body: Data) { self.kind = kind; self.body = body }
}
public enum BridgeWireError: Error { case invalidLength, invalidEnvelope }
public struct BridgeWire {
    public static let maxFrame = 65536
    private var pending = Data()
    public init() {}
    public static func encode(_ frame: BridgeFrame) throws -> Data {
        guard frame.body.count < maxFrame else { throw BridgeWireError.invalidLength }
        let n = UInt32(frame.body.count + 1)
        var output = Data([UInt8(n >> 24), UInt8((n >> 16) & 255), UInt8((n >> 8) & 255), UInt8(n & 255), frame.kind])
        output.append(frame.body)
        return output
    }
    public static func control(type: String, payload: [String: Any] = [:]) throws -> BridgeFrame {
        let body = try JSONSerialization.data(withJSONObject: ["v": 1, "type": type, "payload": payload], options: [.sortedKeys])
        return BridgeFrame(kind: 1, body: body)
    }
    public mutating func receive(_ data: Data) throws -> [BridgeFrame] {
        pending.append(data)
        var frames: [BridgeFrame] = []
        while pending.count >= 4 {
            let n = pending.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            guard n >= 1 && n <= UInt32(Self.maxFrame) else {
                pending.removeAll()
                throw BridgeWireError.invalidLength
            }
            let size = Int(n) + 4
            guard pending.count >= size else { break }
            let frame = pending.prefix(size)
            frames.append(BridgeFrame(kind: frame[frame.index(frame.startIndex, offsetBy: 4)], body: Data(frame.dropFirst(5))))
            pending = Data(pending.dropFirst(size))
        }
        return frames
    }
}
