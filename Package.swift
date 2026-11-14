// swift-tools-version: 5.7
import PackageDescription

// A standalone test harness for the Foundation-only Micropub client code.
// The iOS app uses Apple's CryptoKit; swift-crypto is only needed by Linux tests.
let package = Package(
    name: "SunlitMicropubTests",
    platforms: [.macOS(.v10_15)],
    dependencies: [.package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0")],
    targets: [
        .target(name: "MicropubClient", dependencies: [
            .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux]))
        ], path: "Sunlit/Source/Micropub"),
        .testTarget(name: "MicropubClientTests", dependencies: ["MicropubClient"], path: "Tests/MicropubClientTests")
    ]
)
