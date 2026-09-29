// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KeyClean",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "KeyCleanCore"),
        .executableTarget(name: "KeyClean", dependencies: ["KeyCleanCore"]),
        .testTarget(name: "KeyCleanCoreTests", dependencies: ["KeyCleanCore"]),
    ]
)
