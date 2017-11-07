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
        .package(url: "https://github.com/andriydruk/java_swift.git", .branch("master")),
    ],
    targets: [
        .target(name: "JavaCoder", dependencies: ["java_swift"], path: "Sources"),
    ],
    swiftLanguageVersions: [4]
)
