// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RiversidePackage",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "IOSApp", targets: ["IOSApp"]),
    ],
    targets: [
        .target(
            name: "IOSApp",
            path: "Sources/App/IOSApp"
        ),
    ]
)
