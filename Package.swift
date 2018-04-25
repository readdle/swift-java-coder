// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "JavaCoder",
    products:[
        .library(
            name: "JavaCoder", 
            targets:["JavaCoder"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/andriydruk/java_swift.git", .exact("2.1.2")),
        .package(url: "https://github.com/andriydruk/swift-anycodable.git", .exact("1.0.0")),
    ],
    targets: [
        .target(name: "JavaCoder", dependencies: ["java_swift", "AnyCodable"], path: "Sources"),
    ],
    swiftLanguageVersions: [4]
)
