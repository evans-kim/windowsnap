// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WindowSnap",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "WindowSnap", targets: ["WindowSnap"])],
    targets: [
        .target(name: "SnapCore"),
        .executableTarget(name: "WindowSnap", dependencies: ["SnapCore"]),
        .testTarget(name: "SnapCoreTests", dependencies: ["SnapCore"])
    ]
)
