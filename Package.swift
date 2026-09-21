// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedLayerRepricer",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SharedLayerRepricer", targets: ["SharedLayerRepricer"])
    ],
    targets: [
        .target(name: "SharedLayerRepricer"),
        .testTarget(
            name: "SharedLayerRepricerTests",
            dependencies: ["SharedLayerRepricer"]
        )
    ]
)
