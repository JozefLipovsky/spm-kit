// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPMKit",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "spm-kit",
            targets: [
                "spm-kit"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.0"),
        .package(url: "https://github.com/apple/swift-configuration", from: "1.0.0", traits: [.defaults, "YAML"]),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.0"),    // https://github.com/apple/swift-configuration/issues/89
        .package(url: "https://github.com/kylef/PathKit.git", from: "1.0.1"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.10.1"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.1"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "0.2.1"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
        .package(url: "https://github.com/tuist/noora.git", from: "0.54.0"),
        .package(url: "https://github.com/tuist/xcodeproj.git", from: "9.7.2")
    ],
    targets: [
        .executableTarget(
            name: "spm-kit",
            dependencies: [
                .target(name: "SubCommands")
            ],
            path: "Sources/SPMKit"
        ),
        .target(
            name: "SubCommands",
            dependencies: [
                .target(name: "Core")
            ]
        ),
        .testTarget(
            name: "SubCommandsTests",
            dependencies: [
                .target(name: "SubCommands"),
                .target(name: "TestHelpers"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies")
            ]
        ),
        .target(
            name: "Core",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "Noora", package: "noora"),
                .product(name: "PathKit", package: "pathkit"),
                .product(name: "Stencil", package: "stencil"),
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "XcodeProj", package: "xcodeproj")
            ],
            resources: [
                .copy("_Templates")
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: [
                .target(name: "Core"),
                .target(name: "TestHelpers")
            ],
            resources: [
                .copy("_Fixtures")
            ]
        ),
        .target(
            name: "TestHelpers",
            path: "Tests/TestHelpers"
        )
    ]
)
