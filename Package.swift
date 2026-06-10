// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "JavaCoder",
    products: [
        .library(
            name: "JavaCoder",
            targets: ["JavaCoder"]
        ),
        .library(
            name: "java_swift",
            targets: ["java_swift"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-java-jni-core.git", .upToNextMinor(from: "0.5.1")),
        .package(url: "https://github.com/readdle/swift-anycodable.git", .upToNextMinor(from: "1.0.2")),
    ],
    targets: [
        // compatibility shim exposing the historical `java_swift` API on top of swiftlang's SwiftJavaJNICore (jni-core).
        .target(
            name: "java_swift",
            dependencies: [
                .product(name: "SwiftJavaJNICore", package: "swift-java-jni-core"),
            ],
            path: "Sources/java_swift"
        ),
        .target(
            name: "JavaCoder",
            dependencies: [
                "java_swift",
                .product(name: "AnyCodable", package: "swift-anycodable"),
            ],
            path: "Sources/JavaCoder"
        ),
    ],
    swiftLanguageModes: [.v5]
)
