// swift-tools-version: 5.9

import PackageDescription

// MARK: - Dependencies

let dependencies: [PackageDescription.Package.Dependency] = [
    .package(url: "https://github.com/nmdias/FeedKit", exact: "9.1.2"),
    .package(url: "https://github.com/scinfu/SwiftSoup", exact: "2.6.1"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.1.5"),
]

extension PackageDescription.Target.Dependency {
    static let feedKit: Self = .product(name: "FeedKit", package: "FeedKit")
    static let swiftSoup: Self = .product(name: "SwiftSoup", package: "SwiftSoup")
    static let dependencies: Self = .product(name: "Dependencies", package: "swift-dependencies")
}

// MARK: - Targets

let targets: [PackageDescription.Target] = [
    .target(
        name: "IOSApp",
        dependencies: [
            "NavigationState",
        ],
        path: "Sources/App/IOSApp"
    ),
    .target(
        name: "AddFeedFeature",
        dependencies: [
            "FeedClient",
            "Utilities",
        ],
        path: "Sources/Feature/AddFeedFeature"
    ),
    .target(
        name: "NavigationState",
        path: "Sources/State/NavigationState"
    ),
    .target(
        name: "FeedClient",
        dependencies: [
            .feedKit,
            .swiftSoup,
            .dependencies,
        ],
        path: "Sources/Client/FeedClient",
        exclude: ["FeedClient.xctestplan"]
    ),
    .target(
        name: "Utilities",
        path: "Sources/Core/Utilities"
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
].map { (target: PackageDescription.Target) -> PackageDescription.Target in
    guard target.type != .plugin else { return target }
    
    var swiftSettings = target.swiftSettings ?? []
    swiftSettings.append(
        .unsafeFlags(
            [
                "-strict-concurrency=complete",
                "-enable-actor-data-race-checks",
            ],
            .when(configuration: .debug)
        )
    )
    target.swiftSettings = swiftSettings
    
    return target
}

// MARK: - Package

let package = Package(
    name: "RiversidePackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "IOSApp", targets: ["IOSApp"]),
        .library(name: "AddFeedFeature", targets: ["AddFeedFeature"]),
        .library(name: "FeedClient", targets: ["FeedClient"]),
    ],
    dependencies: dependencies,
    targets: targets
)
