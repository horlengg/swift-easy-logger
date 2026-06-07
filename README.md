# EasyLogger

A lightweight Swift logging plugin powered by Socket.IO that streams logs in real time to a remote log viewer server.

-----


<br>
<br>

![log-dashboard.png](https://github.com/horlengg/easy-logger-server/raw/main/log-dashboard.png)

![json-viewer.png](https://github.com/horlengg/easy-logger-server/raw/main/json-viewer.png)

<br>
<br>

## Requirements

- iOS 14+
- [SocketIO-Client-Swift](https://github.com/socketio/socket.io-client-swift)
- [easy-logger-server](https://github.com/horlengg/easy-logger-server) running on the same Wi-Fi network (Node.js 18+, or Docker)

-----

## Server Setup

EasyLogger requires the [easy-logger-server](https://github.com/horlengg/easy-logger-server) running on the same local network as your device.

> **Source:** [github.com/horlengg/easy-logger-server](https://github.com/horlengg/easy-logger-server)

The server is a Node.js + Express + Socket.IO app. It binds to your machine’s local IP and port so your iOS device (on the same Wi-Fi) can reach it.

```js
const PORT = process.env.PORT || 3000;
const host = process.env.HOST_IP || "172.20.10.12" // Your machine's local IP
const uri = `http://${host}:${PORT}`
```

### Option A — Run directly with Node

```bash
# Clone the repo
git clone https://github.com/horlengg/easy-logger-server.git
cd easy-logger-server

# Install dependencies (Express 5, Socket.IO 4)
npm install

# Start with your machine's local IP
HOST_IP=172.20.10.12 node server.js

# Or just use the default IP hardcoded in server.js
npm start
```

The log viewer UI will be available at `http://<your-ip>:3000` in your browser.

### Option B — Run with Docker

```bash
# Build the image
docker build -t easy-logger-server .

# Run with your local IP passed as an env variable
docker run -p 3000:3000 -e HOST_IP=172.20.10.12 easy-logger-server
```

The Dockerfile uses `node:18-alpine` and exposes port `3000`.

### Finding your local IP

Your device and Mac must be on the **same Wi-Fi network**.

```bash
# macOS — look for en0 inet address
ifconfig en0 | grep "inet "
```

Example output: `inet 172.20.10.12 netmask 0xffffff00`

Use that IP in both your server startup and in `EasyLogger.shared.initialize(...)`.

### Environment Variables

|Variable |Default       |Description                  |
|---------|--------------|-----------------------------|
|`HOST_IP`|`172.20.10.12`|Your machine’s LAN IP address|
|`PORT`   |`3000`        |Port the server listens on   |

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



## Contact Me

If you have any questions, suggestions, or issues, feel free to reach out via my website:

👉 [Website](https://horleng.vercel.app)
