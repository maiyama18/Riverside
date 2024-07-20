// swift-tools-version:5.10

import PackageDescription

let targets: [PackageDescription.Target] = [
    .executableTarget(
        name: "App",
        dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "NIOPosix", package: "swift-nio"),
        ]
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
       .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", exact: "4.99.3"),
        .package(url: "https://github.com/apple/swift-nio.git", exact: "2.65.0"),
    ],
    targets: targets
)
