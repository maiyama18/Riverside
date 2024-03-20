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
    .package(url: "https://github.com/danielsaidi/SystemNotification", exact: "0.7.2"),
    .package(url: "https://github.com/kean/Nuke", exact: "12.2.0"),
    
    // Plugins
    .package(url: "https://github.com/maiyama18/LicensesPlugin", exact: "0.1.6"),
]

extension PackageDescription.Target.Dependency {
    static let feedKit: Self = .product(name: "FeedKit", package: "FeedKit")
    static let swiftSoup: Self = .product(name: "SwiftSoup", package: "SwiftSoup")
    static let dependencies: Self = .product(name: "Dependencies", package: "swift-dependencies")
    static let algorithms: Self = .product(name: "Algorithms", package: "swift-algorithms")
    static let systemNotification: Self = .product(name: "SystemNotification", package: "SystemNotification")
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
            "FlashClient",
            "NavigationState",
            "IOSMainTabFeature",
            "LocalPushNotificationClient",
        ],
        path: "Sources/App/IOSApp"
    ),
    .target(
        name: "IOSActionExtension",
        dependencies: [
            "SubscribeFeedUseCase",
            "Entities",
        ],
        path: "Sources/App/IOSActionExtension"
    ),
    .target(
        name: "IOSWidgetExtension",
        dependencies: [
            "Entities",
        ],
        path: "Sources/App/IOSWidgetExtension",
        resources: [
            .process("Resources"),
        ]
    ),
    .target(
        name: "MacApp",
        dependencies: [
            "FlashClient",
            "Entities",
            "MacRootFeature",
            "LogFeature",
        ],
        path: "Sources/App/MacApp"
    ),
    .target(
        name: "IOSMainTabFeature",
        dependencies: [
            "AppAppearanceClient",
            "BackgroundRefreshUseCase",
            "FlashClient",
            "NavigationState",
            "IOSFeedsFeature",
            "IOSSettingsFeature",
            "IOSStreamFeature",
            "ViewModifiers",
        ],
        path: "Sources/Feature/IOS/IOSMainTabFeature"
    ),
    .target(
        name: "IOSFeedsFeature",
        dependencies: [
            .algorithms,
            "SubscribeFeedFeature",
            "ClipboardClient",
            "CloudSyncState",
            "Entities",
            "AddNewEntriesUseCase",
            "NavigationState",
            "UIComponents",
        ],
        path: "Sources/Feature/IOS/IOSFeedsFeature"
    ),
    .target(
        name: "IOSSettingsFeature",
        dependencies: [
            "CloudSyncStatusFeature",
            "LicensesFeature",
            "LocalPushNotificationClient",
            "LogFeature",
            "NavigationState",
            "Utilities",
            "UIComponents",
        ],
        path: "Sources/Feature/IOS/IOSSettingsFeature"
    ),
    .target(
        name: "IOSStreamFeature",
        dependencies: [
            .algorithms,
            .dependencies,
            "AddNewEntriesUseCase",
            "CloudSyncState",
            "Entities",
            "FlashClient",
            "NavigationState",
            "UIComponents",
        ],
        path: "Sources/Feature/IOS/IOSStreamFeature"
    ),
    .target(
        name: "MacRootFeature",
        dependencies: [
            .algorithms,
            "ClipboardClient",
            "CloudSyncStatusFeature",
            "CloudSyncState",
            "DeleteDuplicatedEntriesUseCase",
            "Entities",
            "AddNewEntriesUseCase",
            "FlashClient",
            "LicensesFeature",
            "SubscribeFeedFeature",
            "UIComponents",
            "WebView",
            "ViewModifiers",
        ],
        path: "Sources/Feature/Mac/MacRootFeature"
    ),
    .target(
        name: "CloudSyncStatusFeature",
        dependencies: [
            "CloudSyncState",
        ],
        path: "Sources/Feature/Shared/CloudSyncStatusFeature"
    ),
    .target(
        name: "LogFeature",
        dependencies: [
            "FlashClient",
            "Utilities",
        ],
        path: "Sources/Feature/Shared/LogFeature"
    ),
    .target(
        name: "SubscribeFeedFeature",
        dependencies: [
            "FeedClient",
            "SubscribeFeedUseCase",
            "FlashClient",
            "Entities",
            "Utilities",
            "UIComponents",
        ],
        path: "Sources/Feature/Shared/SubscribeFeedFeature"
    ),
    .target(
        name: "LicensesFeature",
        path: "Sources/Feature/Shared/LicensesFeature",
        plugins: [.licenses]
    ),
    .target(
        name: "ViewModifiers",
        dependencies: [
            "AddNewEntriesUseCase",
            "CloudSyncState",
            "DeleteDuplicatedEntriesUseCase",
            "ForegroundRefreshState",
        ],
        path: "Sources/Feature/Shared/ViewModifiers"
    ),
    .target(
        name: "CloudSyncState",
        dependencies: [
            .dependencies,
        ],
        path: "Sources/State/CloudSyncState"
    ),
    .target(
        name: "ForegroundRefreshState",
        dependencies: [
            "AddNewEntriesUseCase",
        ],
        path: "Sources/State/ForegroundRefreshState"
    ),
    .target(
        name: "NavigationState",
        dependencies: [
            "Entities",
        ],
        path: "Sources/State/NavigationState"
    ),
    .target(
        name: "AddNewEntriesUseCase",
        dependencies: [
            "Entities",
            "FeedClient",
        ],
        path: "Sources/UseCase/AddNewEntriesUseCase"
    ),
    .target(
        name: "DeleteDuplicatedEntriesUseCase",
        dependencies: [
            "Entities",
            "FeedClient",
        ],
        path: "Sources/UseCase/DeleteDuplicatedEntriesUseCase"
    ),
    .target(
        name: "SubscribeFeedUseCase",
        dependencies: [
            "Entities",
            "FeedClient",
        ],
        path: "Sources/UseCase/SubscribeFeedUseCase"
    ),
    .target(
        name: "BackgroundRefreshUseCase",
        dependencies: [
            "AddNewEntriesUseCase",
            "Entities",
            "LocalPushNotificationClient",
        ],
        path: "Sources/UseCase/BackgroundRefreshUseCase"
    ),
    .target(
        name: "AppAppearanceClient",
        dependencies: [
            .dependencies,
        ],
        path: "Sources/Client/AppAppearanceClient"
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
            "Entities",
            "Utilities",
        ],
        path: "Sources/Client/FeedClient",
        exclude: ["FeedClient.xctestplan"]
    ),
    .target(
        name: "FlashClient",
        dependencies: [
            .dependencies,
            .systemNotification,
        ],
        path: "Sources/Client/FlashClient"
    ),
    .target(
        name: "LocalPushNotificationClient",
        dependencies: [
            .dependencies,
        ],
        path: "Sources/Client/LocalPushNotificationClient"
    ),
    .target(
        name: "AppConfig",
        dependencies: [
            .dependencies,
        ],
        path: "Sources/Core/AppConfig"
    ),
    .target(
        name: "Entities",
        dependencies: [
            .algorithms,
            "AppConfig",
        ],
        path: "Sources/Core/Entities"
    ),
    .target(
        name: "Logging",
        dependencies: [
            .dependencies,
        ],
        path: "Sources/Core/Logging"
    ),
    .target(
        name: "Utilities",
        dependencies: [
            .dependencies,
        ],
        path: "Sources/Core/Utilities"
    ),
    .target(
        name: "UIComponents",
        dependencies: [
            .nukeUI,
            "Entities",
            "ForegroundRefreshState",
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
        name: "DeleteDuplicatedEntriesUseCaseTests",
        dependencies: [
            "DeleteDuplicatedEntriesUseCase",
        ],
        path: "Tests/UseCase/DeleteDuplicatedEntriesUseCaseTests"
    ),
    .testTarget(
        name: "CloudSyncStateTests",
        dependencies: [
            "CloudSyncState",
        ],
        path: "Tests/State/CloudSyncStateTests"
    ),
    .testTarget(
        name: "FeedClientTests",
        dependencies: [
            "FeedClient",
        ],
        path: "Tests/Client/FeedClientTests",
        resources: [.process("Resources")]
    ),
    .testTarget(
        name: "EntitiesTests",
        dependencies: [
            "Entities",
        ],
        path: "Tests/Core/EntitiesTests"
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
    
    if target.isTest {
        var dependencies = target.dependencies
        dependencies.append(contentsOf: [.customDump, "TestHelpers"])
        target.dependencies = dependencies
    }
    if target.name != "Logging" {
        var dependencies = target.dependencies
        dependencies.append("Logging")
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
        .library(name: "IOSWidgetExtension", targets: ["IOSWidgetExtension"]),
        .library(name: "MacApp", targets: ["MacApp"]),
        .library(
            name: "AllTests",
            targets: targets.filter({ $0.isTest }).map(\.name)
        ),
        .library(
            name: "Features",
            targets: [
                "SubscribeFeedFeature",
                "IOSFeedsFeature",
                "IOSSettingsFeature",
                "IOSStreamFeature",
            ]
        ),
        .library(name: "CloudSyncState", targets: ["CloudSyncState"]),
        .library(name: "DeleteDuplicatedEntriesUseCase", targets: ["DeleteDuplicatedEntriesUseCase"]),
        .library(name: "FeedClient", targets: ["FeedClient"]),
        .library(name: "Entities", targets: ["Entities"]),
        .library(name: "Utilities", targets: ["Utilities"]),
        .library(name: "UIComponents", targets: ["UIComponents"]),
    ],
    dependencies: dependencies,
    targets: targets
)
