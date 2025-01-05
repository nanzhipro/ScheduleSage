// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ScheduleSage",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.1"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/nanzhipro/SwiftWebCrawler.git", branch: "main"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", from: "3.8.0")
    ],
    targets: [
        .target(
            name: "ScheduleSage",
            dependencies: [
                "SwiftSoup",
                "Kingfisher",
                "Alamofire",
                "SwiftWebCrawler",
                "CocoaLumberjack"
            ]
        ),
        .testTarget(
            name: "ScheduleSageTests",
            dependencies: ["ScheduleSage"]
        )
    ]
) 