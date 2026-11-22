import Foundation

public enum BridgeProbe {
    public static func request() throws -> (id: String, frame: BridgeFrame) {
        let id = UUID().uuidString
        return (id, try BridgeWire.control(type: "PING", payload: ["probe": id]))
    }
    public static func matches(_ frame: BridgeFrame, id: String) -> Bool {
        guard frame.kind == 1,
              let json = (try? JSONSerialization.jsonObject(with: frame.body)) as? [String: Any],
              json["v"] as? Int == 1,
              json["type"] as? String == "PONG",
              let payload = json["payload"] as? [String: Any]
        else { return false }
        return payload["probe"] as? String == id
    }
}
