// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NextStoreKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "NextStoreKit", targets: ["NextStoreKit"]),
    ],
    targets: [
        .target(name: "NextStoreKit"),
        .testTarget(name: "NextStoreKitTests", dependencies: ["NextStoreKit"]),
    ]
)
