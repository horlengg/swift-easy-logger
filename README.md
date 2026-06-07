
# EasyLogger

A lightweight Swift logging plugin powered by Socket.IO that streams logs in real time to a remote log viewer server.

-----

## Requirements

- iOS 14+
- [SocketIO-Client-Swift](https://github.com/socketio/socket.io-client-swift)
- A running log viewer server (e.g. Node.js + Socket.IO on port `3000`)

-----

## Installation

Add `EasyLogger` to your project via Swift Package Manager or manually, then import it:

```swift
import EasyLogger
```

-----

## Setup

### 1. Initialize in `App` entry point

Initialize EasyLogger once at app startup. Use a compile-time flag to toggle logging without shipping it to production.

```swift
import SwiftUI
import EasyLogger

@main
struct ChatAppApp: App {

    init() {
        EasyLogger.shared.initialize("http://172.20.10.12:3000", enable: isEnableLog)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private var isEnableLog: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
```


-----

## API Reference

### `initialize(_:enable:)`

Connects to the log server. Must be called before any logging.

```swift
EasyLogger.shared.initialize("http://<server-ip>:<port>", enable: true)
```

|Parameter|Type  |Description                                      |
|---------|------|-------------------------------------------------|
|`url`    |String|WebSocket server URL                             |
|`enable` |Bool  |Master switch — disables all logging when `false`|


> Logs emitted before the socket connects are **queued** and automatically flushed once the connection is established.

-----

### Logging Methods

All three methods accept an optional `tag` to group related logs. Defaults to `"DEFAULT"` if omitted.

#### `debug(_:tag:)`

```swift
EasyLogger.shared.debug("User tapped login button", tag: "Auth")
```

#### `warning(_:tag:)`

```swift
EasyLogger.shared.warning("Token is about to expire", tag: "Auth")
```

#### `error(_:tag:)`

```swift
EasyLogger.shared.error("Failed to parse response", tag: "Network")
```

-----

### `toJSONString(_:)`

Serializes any `Codable` array to a pretty-printed JSON string. Useful for logging model data.

```swift
let json = EasyLogger.shared.toJSONString(conversations)
EasyLogger.shared.debug("All Conversations: <json>\(json ?? "N/A")<json>", tag: "Chat")
```

-----

### `clear()`

Clears **pending (queued)** logs and emits a `clear` event to the server.

```swift
EasyLogger.shared.clear()
```

-----

### `dispose()`

Disconnects the socket and releases all resources. Call this when logging is no longer needed (e.g. on logout or app termination).

```swift
EasyLogger.shared.dispose()
```

-----

## Full Usage Example

```swift
import EasyLogger

// Log plain messages
EasyLogger.shared.debug("View appeared", tag: "HomeScreen")
EasyLogger.shared.warning("Cache miss — fetching from network", tag: "Cache")
EasyLogger.shared.error("CoreData save failed", tag: "Persistence")

// Log a Codable array as JSON
let json = EasyLogger.shared.toJSONString(conversations)
EasyLogger.shared.debug("Conversations: <json>\(json ?? "N/A")<json>", tag: "Chat")
EasyLogger.shared.warning("Conversations: <json>\(json ?? "N/A")<json>", tag: "Chat")
EasyLogger.shared.error("Conversations: <json>\(json ?? "N/A")<json>", tag: "Chat")

// Clear pending logs
EasyLogger.shared.clear()

// Teardown
EasyLogger.shared.dispose()
```

-----

## Log Types

|Type      |Raw Value|Use case                         |
|----------|---------|---------------------------------|
|`.debug`  |`0`      |General info, state changes      |
|`.warning`|`1`      |Non-critical issues, deprecations|
|`.error`  |`2`      |Failures, exceptions             |

-----

## Socket Events

EasyLogger emits the following Socket.IO events to the server:

|Event      |Payload                 |Description                 |
|-----------|------------------------|----------------------------|
|`send-logs`|`{ message, tag, type }`|Sends a log entry           |
|`clear`    |*(none)*                |Signals server to clear logs|

-----

## Notes

- `EasyLogger` is a `@MainActor` singleton — all calls are thread-safe when made from the main thread.
- Logs are **silently dropped** when `enable` is `false` (no overhead in production).
- The socket auto-reconnects on disconnect.
