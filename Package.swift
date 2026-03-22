// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CameraSessionSDK",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "CameraSessionSDK", targets: ["CameraSession", "CameraShim"]),
    ],
    targets: [
        .target(
            name: "CameraSession",
            dependencies: []),
        .target(
            name: "CameraShim",
            dependencies: ["CameraSession"],
            publicHeadersPath: "include"),
        .testTarget(
            name: "CameraSessionTests",
            dependencies: ["CameraSession"]),
    ]
)
