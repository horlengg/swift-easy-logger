// The Swift Programming Language
// https://docs.swift.org/swift-book


import SocketIO
import Foundation

enum LogType: Int {
    case debug = 0
    case warning = 1
    case error = 2
}

// MARK: - LogRequest

private struct LogRequest {
    let message: String
    let tag: String
    let type: LogType

    func toJSON() -> [String: Any] {
        return [
            "message": message,
            "tag": tag,
            "type": type.rawValue
        ]
    }
}

// MARK: - EasyLogger

@MainActor
public final class EasyLogger {
    
    public static let shared = EasyLogger()
    
    private init() {}

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var isEnableLog : Bool = false
    
    // MARK: - Cache
    private var pendingLogs: [LogRequest] = []


    private var isConnected: Bool {
        socket?.status == .connected
    }

    public func initialize(_ url: String,enable : Bool) {
        isEnableLog = enable
        guard enable else { return }
        guard let socketURL = URL(string: url) else {
            print("EasyLogger: Invalid URL")
            return
        }
        manager = SocketManager(socketURL: socketURL, config: [
            .log(false),
            .compress,
            .forceWebsockets(true),
            .reconnects(true)
        ])

        socket = manager?.defaultSocket

        socket?.on(clientEvent: .connect) { _, _ in
            print("Logger socket connected \(url)")
            self.flushPendingLogs()
        }
        socket?.on(clientEvent: .disconnect) { _, _ in
            print("Logger socket disconnected")
        }
        socket?.on(clientEvent: .error) { data, _ in
            print("Logger socket error: \(data)")
        }

        socket?.connect()
    }

    // MARK: - Flush

    private func flushPendingLogs() {
        guard isConnected, !pendingLogs.isEmpty else { return }
        pendingLogs.forEach { sendToServer($0) }
        pendingLogs.removeAll()
    }

    // MARK: - Send

    private func sendToServer(_ request: LogRequest) {
        socket?.emit("send-logs", request.toJSON())
    }

    private func log(_ request: LogRequest) {
        guard isEnableLog else { return }
        if isConnected {
            sendToServer(request)
        } else {
            pendingLogs.append(request)
        }
    }

    // MARK: - Public API

    public func debug(_ message: String, tag: String? = nil) {
        log(LogRequest(message: message, tag: tag ?? "DEFAULT", type: .debug))
    }

    public func warning(_ message: String, tag: String? = nil) {
        log(LogRequest(message: message, tag: tag ?? "DEFAULT", type: .warning))
    }

    public func error(_ message: String, tag: String? = nil) {
        log(LogRequest(message: message, tag: tag ?? "DEFAULT", type: .error))
    }

    public func clear() {
        guard isEnableLog else { return }
        pendingLogs.removeAll()
        socket?.emit("clear")
    }

    public func dispose() {
        pendingLogs.removeAll()
        socket?.disconnect()
        manager?.disconnect()
        socket = nil
        manager = nil
    }
    
    public func toJSONString<T: Codable>(_ items: [T]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // optional, for readable output
        guard let data = try? encoder.encode(items) else { return nil }
        return String(data: data, encoding: .utf8)
    }


}
