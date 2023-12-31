// swift-tools-version: 5.9

import PackageDescription

// MARK: - Dependencies

let dependencies: [PackageDescription.Package.Dependency] = [
    // Libraries
    .package(url: "https://github.com/nmdias/FeedKit", exact: "9.1.2"),
    .package(url: "https://github.com/scinfu/SwiftSoup", exact: "2.6.1"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.1.5"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", exact: "1.1.2"),
    .package(url: "https://github.com/apple/swift-algorithms", exact: "1.2.0"),
    .package(url: "https://github.com/omaralbeik/Drops", exact: "1.7.0"),
    .package(url: "https://github.com/kean/Nuke", exact: "12.2.0"),
    
    // Plugins
    .package(url: "https://github.com/maiyama18/LicensesPlugin", exact: "0.1.6"),
]

extension PackageDescription.Target.Dependency {
    static let feedKit: Self = .product(name: "FeedKit", package: "FeedKit")
    static let swiftSoup: Self = .product(name: "SwiftSoup", package: "SwiftSoup")
    static let dependencies: Self = .product(name: "Dependencies", package: "swift-dependencies")
    static let algorithms: Self = .product(name: "Algorithms", package: "swift-algorithms")
    static let drops: Self = .product(name: "Drops", package: "Drops")
    static let nukeUI: Self = .product(name: "NukeUI", package: "Nuke")
    static let customDump: Self = .product(name: "CustomDump", package: "swift-custom-dump")
}

extension PackageDescription.Target.PluginUsage {
    static let licenses: Self = .plugin(name: "LicensesPlugin", package: "LicensesPlugin")
}

// MARK: - Targets

let targets: [PackageDescription.Target] = [
    .target(
        name: "IOSApp",
        dependencies: [
            "CloudSyncState",
            "FeedsFeature",
            "Models",
            "NavigationState",
            "SettingsFeature",
            "StreamFeature",
        ],
        path: "Sources/App/IOSApp"
    ),
    .target(
        name: "IOSActionExtension",
        dependencies: [
            "FeedUseCase",
            "Models",
        ],
        path: "Sources/App/IOSActionExtension"
    ),
    .target(
        name: "MacApp",
        dependencies: [
            "Models",
            "RootFeature",
        ],
        path: "Sources/App/MacApp"
    ),
    .target(
        name: "SubscribeFeedFeature",
        dependencies: [
            "FeedClient",
            "FeedUseCase",
            "FlashClient",
            "Models",
            "Utilities",
            "UIComponents",
        ],
        path: "Sources/Feature/SubscribeFeedFeature"
    ),
    .target(
        name: "FeedsFeature",
        dependencies: [
            "SubscribeFeedFeature",
            "ClipboardClient",
            "CloudSyncState",
            "FeedUseCase",
            "Models",
            "NavigationState",
            "UIComponents",
        ],
        path: "Sources/Feature/FeedsFeature"
    ),
    .target(
        name: "SettingsFeature",
        dependencies: [
            "CloudSyncState",
            "NavigationState",
        ],
        path: "Sources/Feature/SettingsFeature",
        plugins: [.licenses]
    ),
    .target(
        name: "StreamFeature",
        dependencies: [
            .algorithms,
            "CloudSyncState",
            "FeedUseCase",
            "FlashClient",
            "Models",
            "NavigationState",
            "UIComponents",
        ],
        path: "Sources/Feature/StreamFeature"
    ),
    .target(
        name: "RootFeature",
        dependencies: [
            .algorithms,
            "ClipboardClient",
            "CloudSyncState",
            "FeedUseCase",
            "FlashClient",
            "Models",
            "SettingsFeature",
            "SubscribeFeedFeature",
            "UIComponents",
            "WebView",
        ],
        path: "Sources/Feature/RootFeature"
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
        name: "CloudSyncState",
        path: "Sources/State/CloudSyncState"
    ),
    .target(
        name: "NavigationState",
        dependencies: [
            "Models",
        ],
        path: "Sources/State/NavigationState"
    ),
    .target(
        name: "ClipboardClient",
        dependencies: [
            .dependencies,
        ],
        path: "Sources/Client/ClipboardClient"
    ),
    .target(
        name: "FeedClient",
        dependencies: [
            .feedKit,
            .swiftSoup,
            .dependencies,
            "Models",
            "Utilities",
        ],
        path: "Sources/Client/FeedClient",
        exclude: ["FeedClient.xctestplan"]
    ),
    .target(
        name: "FlashClient",
        dependencies: [
            .dependencies,
            .drops,
        ],
        path: "Sources/Client/FlashClient"
    ),
    .target(
        name: "Models",
        dependencies: [
            .algorithms,
        ],
        path: "Sources/Core/Models"
    ),
    .target(
        name: "Utilities",
        path: "Sources/Core/Utilities"
    ),
    .target(
        name: "UIComponents",
        dependencies: [
            .nukeUI,
            "Models",
        ],
        path: "Sources/Core/UIComponents"
    ),
    .target(
        name: "WebView",
        path: "Sources/Core/WebView"
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
        name: "ModelsTests",
        dependencies: [
            "Models",
        ],
        path: "Tests/Core/ModelsTests"
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
                "-enable-upcoming-feature", "ExistentialAny",
                "-enable-upcoming-feature", "BareSlashRegexLiterals",
                "-enable-upcoming-feature", "DisableOutwardActorInference",
            ]
        )
    )
    target.swiftSettings = swiftSettings
    
    if target.isTest {
        var dependencies = target.dependencies
        dependencies.append(.customDump)
        target.dependencies = dependencies
    }
    
    return target
}

// MARK: - Package

let package = Package(
    name: "RiversidePackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "IOSApp", targets: ["IOSApp"]),
        .library(name: "IOSActionExtension", targets: ["IOSActionExtension"]),
        .library(name: "MacApp", targets: ["MacApp"]),
        .library(
            name: "Features",
            targets: [
                "SubscribeFeedFeature",
                "FeedsFeature",
                "SettingsFeature",
                "StreamFeature",
            ]
        ),
        .library(name: "FeedClient", targets: ["FeedClient"]),
        .library(name: "Models", targets: ["Models"]),
        .library(name: "Utilities", targets: ["Utilities"]),
        .library(name: "UIComponents", targets: ["UIComponents"]),
    ],
    dependencies: dependencies,
    targets: targets
)
