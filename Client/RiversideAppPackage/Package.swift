// swift-tools-version: 5.9

import PackageDescription

// MARK: - Dependencies

let dependencies: [PackageDescription.Package.Dependency] = [
    // Libraries
    .package(url: "https://github.com/maiyama18/RiversideShared.git", exact: "0.9.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.1.5"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", exact: "1.1.2"),
    .package(url: "https://github.com/apple/swift-algorithms", exact: "1.2.0"),
    .package(url: "https://github.com/danielsaidi/SystemNotification", exact: "0.7.2"),
    .package(url: "https://github.com/kean/Nuke", exact: "12.2.0"),
    
    // Plugins
    .package(url: "https://github.com/maiyama18/LicensesPlugin", exact: "0.1.6"),
]

extension PackageDescription.Target.Dependency {
    static let payloads: Self = .product(name: "Payloads", package: "RiversideShared")
    
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
            .payloads,
            "Entities",
            "Utilities",
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
            "ForegroundRefreshState",
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
            "CloudSyncState",
            "FeedClient",
            "Utilities",
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
            "Entities",
            "FeedClient",
            "LocalPushNotificationClient",
            "Utilities",
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
            .dependencies,
            .payloads,
            "Entities",
            "Utilities",
        ],
        path: "Sources/Client/FeedClient"
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
            .payloads,
            "AppConfig",
            "Utilities",
        ],
        path: "Sources/Core/Entities"
    ),
    .target(
        name: "RiversideLogging",
        dependencies: [
            .dependencies,
        ],
        path: "Sources/Core/RiversideLogging"
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
    if target.name != "RiversideLogging" {
        var dependencies = target.dependencies
        dependencies.append("RiversideLogging")
        target.dependencies = dependencies
    }
    
    return target
}

// MARK: - Package

let package = Package(
    name: "RiversideAppPackage",
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
        .library(name: "TestHelpers", targets: ["TestHelpers"]),
    ],
    dependencies: dependencies,
    targets: targets
)
