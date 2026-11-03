// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GentleNight",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GentleNightCore", targets: ["GentleNightCore"]),
        .executable(name: "gentle-night-preview", targets: ["GentleNightPreview"]),
    ],
    targets: [
        .target(name: "GentleNightCore"),
        .executableTarget(name: "GentleNightPreview", dependencies: ["GentleNightCore"]),
        .testTarget(name: "GentleNightCoreTests", dependencies: ["GentleNightCore"]),
    ]
)
