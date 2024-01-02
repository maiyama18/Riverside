// swift-tools-version: 5.9

import PackageDescription

// MARK: - Dependencies

let dependencies: [PackageDescription.Package.Dependency] = [
    // Libraries
    .package(url: "https://github.com/nmdias/FeedKit", exact: "9.1.2"),
    .package(url: "https://github.com/scinfu/SwiftSoup", exact: "2.6.1"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.1.5"),
    
    // Plugins
    .package(url: "https://github.com/maiyama18/LicensesPlugin", exact: "0.1.6"),
]

extension PackageDescription.Target.Dependency {
    static let feedKit: Self = .product(name: "FeedKit", package: "FeedKit")
    static let swiftSoup: Self = .product(name: "SwiftSoup", package: "SwiftSoup")
    static let dependencies: Self = .product(name: "Dependencies", package: "swift-dependencies")
}

extension PackageDescription.Target.PluginUsage {
    static let licenses: Self = .plugin(name: "LicensesPlugin", package: "LicensesPlugin")
}

// MARK: - Targets

let targets: [PackageDescription.Target] = [
    .target(
        name: "IOSApp",
        dependencies: [
            "FeedsFeature",
            "Models",
            "NavigationState",
            "SettingsFeature",
            "StreamFeature",
        ],
        path: "Sources/App/IOSApp"
    ),
    .target(
        name: "AddFeedFeature",
        dependencies: [
            "FeedClient",
            "Models",
            "Utilities",
        ],
        path: "Sources/Feature/AddFeedFeature"
    ),
    .target(
        name: "FeedsFeature",
        dependencies: [
            "AddFeedFeature",
            "FeedUseCase",
            "Models",
            "NavigationState",
        ],
        path: "Sources/Feature/FeedsFeature"
    ),
    .target(
        name: "SettingsFeature",
        dependencies: [
            "NavigationState",
        ],
        path: "Sources/Feature/SettingsFeature",
        plugins: [.licenses]
    ),
    .target(
        name: "StreamFeature",
        dependencies: [
            "FeedUseCase",
            "Models",
            "NavigationState",
        ],
        path: "Sources/Feature/StreamFeature"
    ),
    .target(
        name: "FeedUseCase",
        dependencies: [
            "FeedClient",
            "Models",
        ],
        path: "Sources/UseCase/FeedUseCase"
    ),
    .target(
        name: "NavigationState",
        dependencies: [
            "Models",
        ],
        path: "Sources/State/NavigationState"
    ),
    .target(
        name: "FeedClient",
        dependencies: [
            .feedKit,
            .swiftSoup,
            .dependencies,
            "Models",
        ],
        path: "Sources/Client/FeedClient",
        exclude: ["FeedClient.xctestplan"]
    ),
    .target(
        name: "Models",
        path: "Sources/Core/Models"
    ),
    .target(
        name: "Utilities",
        path: "Sources/Core/Utilities"
    ),
    .target(
        name: "TestHelpers",
        dependencies: [
            .dependencies,
        ],
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
    ),
    .testTarget(
        name: "UtilitiesTests",
        dependencies: [
            "Utilities",
        ],
        path: "Tests/Core/UtilitiesTests"
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
        .library(
            name: "Features",
            targets: [
                "AddFeedFeature",
                "FeedsFeature",
                "SettingsFeature",
                "StreamFeature",
            ]
        ),
        .library(name: "FeedClient", targets: ["FeedClient"]),
        .library(name: "Utilities", targets: ["Utilities"]),
    ],
    dependencies: dependencies,
    targets: targets
)
