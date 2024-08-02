// swift-tools-version:5.10

import PackageDescription

let targets: [PackageDescription.Target] = [
    
    // Sources
    
    .target(
        name: "Payloads"
    ),
    .target(
        name: "FeedFetcher",
        dependencies: [
            "Payloads",
            .product(name: "FeedKit", package: "FeedKit"),
            .product(name: "SwiftSoup", package: "SwiftSoup"),
            .product(name: "Vapor", package: "vapor"),
        ]
    ),
    .executableTarget(
        name: "App",
        dependencies: [
            "Payloads",
            "FeedFetcher",
            .product(name: "Vapor", package: "vapor"),
            .product(name: "Fluent", package: "fluent"),
            .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "NIOPosix", package: "swift-nio"),
        ]
    ),
    
    // Tests
    
    .testTarget(
        name: "FeedFetcherTests",
        dependencies: [
            "FeedFetcher",
        ],
        resources: [.process("Resources")]
    ),
    .testTarget(
        name: "AppTests",
        dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ]
    ),
].map { (target: PackageDescription.Target) -> PackageDescription.Target in
    guard target.type != .plugin else { return target }
    
    var swiftSettings = target.swiftSettings ?? []
    swiftSettings.append(
        contentsOf: [
            // ref: https://github.com/apple/swift/blob/main/include/swift/Basic/Features.def
            .enableUpcomingFeature("BareSlashRegexLiterals"),
            .enableUpcomingFeature("ConciseMagicFile"),
            .enableUpcomingFeature("DisableOutwardActorInference"),
            .enableUpcomingFeature("ExistentialAny"),
            .enableExperimentalFeature("StrictConcurrency"),
        ]
    )
    target.swiftSettings = swiftSettings
    
    return target
}

let package = Package(
    name: "RiversideServer",
    platforms: [
       .macOS(.v14),
       .iOS(.v17),
    ],
    products: [
        .library(name: "FeedFetcher", targets: ["FeedFetcher"]),
        .library(name: "Payloads", targets: ["Payloads"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", exact: "4.102.1"),
        .package(url: "https://github.com/vapor/fluent.git", exact: "4.11.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", exact: "4.7.4"),
        .package(url: "https://github.com/apple/swift-nio.git", exact: "2.69.0"),
        .package(url: "https://github.com/nmdias/FeedKit", exact: "9.1.2"),
        .package(url: "https://github.com/scinfu/SwiftSoup", exact: "2.6.1"),
    ],
    targets: targets
)
