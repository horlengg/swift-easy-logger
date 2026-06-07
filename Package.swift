// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EasyLogger",
    products: [
        .library(
            name: "EasyLogger",
            targets: ["EasyLogger"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/socketio/socket.io-client-swift", .upToNextMinor(from: "16.1.1"))
    ],
    targets: [
        .target(
            name: "EasyLogger",
            dependencies: [
                // ✅ This was missing
                .product(name: "SocketIO", package: "socket.io-client-swift")
            ]
        ),
        .testTarget(
            name: "EasyLoggerTests",
            dependencies: ["EasyLogger"]
        ),
    ]
)
