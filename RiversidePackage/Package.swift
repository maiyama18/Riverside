// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RiversidePackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "IOSApp", targets: ["IOSApp"]),
        .library(name: "FeedClient", targets: ["FeedClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nmdias/FeedKit", exact: "9.1.2"),
        .package(url: "https://github.com/scinfu/SwiftSoup", exact: "2.6.1"),
    ],
    targets: [
        .target(
            name: "IOSApp",
            dependencies: [
                "NavigationState",
            ],
            path: "Sources/App/IOSApp"
        ),
        .target(
            name: "NavigationState",
            path: "Sources/State/NavigationState"
        ),
        .target(
            name: "FeedClient",
            dependencies: [
                .product(name: "FeedKit", package: "FeedKit"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
            ],
            path: "Sources/Client/FeedClient"
        ),
        .target(
            name: "TestHelpers",
            path: "Sources/Core/TestHelpers"
        ),
        .testTarget(
            name: "FeedClientTests",
            dependencies: [
                "FeedClient",
                "TestHelpers",
            ],
            path: "Tests/Client/FeedClientTests",
            resources: [.process("Resources")]
        )
    ]
)
