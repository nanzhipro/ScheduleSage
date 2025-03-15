// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ScheduleSage",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", from: "3.8.0"),
        .package(url: "https://github.com/malcommac/SwiftDate.git", from: "7.0.0"),
        .package(url: "https://github.com/Kitura/Swift-JWT.git", from: "4.0.0"),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", from: "3.1.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "8.45.0"),
        .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.19.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.8.7")
    ],
    targets: [
        .target(
            name: "ScheduleSage",
            dependencies: [
                "Kingfisher",
                "Alamofire",
                "CocoaLumberjack",
                "SwiftDate",
                "SwiftJWT",
                "JWTDecode",
                "Sentry",
                "Purchases",
                "SwiftSoup"
            ]
        ),
        .testTarget(
            name: "ScheduleSageTests",
            dependencies: ["ScheduleSage"]
        )
    ]
) 