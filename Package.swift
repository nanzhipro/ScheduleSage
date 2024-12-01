// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ScheduleSage",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.1"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "ScheduleSage",
            dependencies: [
                "SwiftSoup",
                "Kingfisher"
            ]
        ),
        .testTarget(
            name: "ScheduleSageTests",
            dependencies: ["ScheduleSage"]
        )
    ]
) 