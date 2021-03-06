// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "bollo-auto",
    platforms: [
        .macOS(.v10_15),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.3.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.0.0")
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "SwiftSoup", package: "SwiftSoup"),
        ]),
        .target(name: "Run", dependencies: [
            .target(name: "App"),
        ]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
        ])
    ]
)

