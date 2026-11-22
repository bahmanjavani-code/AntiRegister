import Foundation
#if canImport(Network)
import Network

/// Local encrypted transport. The caller must supply TLS parameters with peer authentication.
/// No plaintext fallback. All callbacks run on the private serial queue.
public final class LocalBridgeConnection {
    private let connection: NWConnection
    private let queue = DispatchQueue(label: "bridge.local.connection")
    private var decoder = BridgeWire()
    private var stopped = false
    public init(host: NWEndpoint.Host, port: NWEndpoint.Port, tls: NWProtocolTLS.Options) {
        connection = NWConnection(host: host, port: port, using: NWParameters(tls: tls, tcp: NWProtocolTCP.Options()))
    }
    public func start(onState: @escaping (NWConnection.State) -> Void, onFrame: @escaping (BridgeFrame) -> Void, onError: @escaping (Error) -> Void) {
        connection.stateUpdateHandler = { [weak self] state in
            onState(state)
            if case .ready = state { self?.read(onFrame: onFrame, onError: onError) }
        }
        connection.start(queue: queue)
    }
    public func send(_ frame: BridgeFrame, completion: @escaping (Error?) -> Void) {
        queue.async {
            do {
                guard !self.stopped else { completion(NWError.posix(.ECANCELED)); return }
                self.connection.send(content: try BridgeWire.encode(frame), completion: .contentProcessed { completion($0) })
            } catch { completion(error) }
        }
    }
    public func stop() {
        queue.async { self.stopped = true; self.connection.cancel() }
    }
    private func read(onFrame: @escaping (BridgeFrame) -> Void, onError: @escaping (Error) -> Void) {
        guard !stopped else { return }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] bytes, _, complete, error in
            guard let self = self, !self.stopped else { return }
            do {
                if let bytes = bytes { for frame in try self.decoder.receive(bytes) { onFrame(frame) } }
                if let error = error { throw error }
                if complete { self.stop(); return }
                self.read(onFrame: onFrame, onError: onError)
            } catch { self.stop(); onError(error) }
        }
    }
}
#endif
