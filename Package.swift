// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "JavaCoder",
    products:[
        .library(
            name: "JavaCoder", 
            type: .dynamic, 
            targets:["JavaCoder"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftJava/java_swift.git", from: "2.1.1"),
    ],
    targets: [
        .target(name: "JavaCoder", dependencies: ["java_swift"], path: "Sources"),
    ],
    swiftLanguageVersions: [4]
)
