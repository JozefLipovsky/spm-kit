//
//  CommandHelpers.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-06-06.
//

import Core
import Foundation
import PathKit
import System

/// Finds the `spm-kit-config.yaml` file by searching the given path and its ancestors.
/// - Parameters:
///   - currentPath: The path to start searching from.
/// - Returns: The resolved config file path.
/// - Throws: `SubcommandError.configFileNotFound` if no config file is found.
package func configPath(currentPath: Path) throws -> Path {
    guard let configPath = currentPath.ancestor(containing: "spm-kit-config.yaml") else {
        throw SubcommandError.configFileNotFound
    }

    return configPath
}

/// Runs `swift package dumpPackage` and decodes the result as a `PackageJSON`.
/// - Parameters:
///   - path: The path to the package directory.
///   - subprocessClient: The subprocess client for executing Swift CLI commands.
/// - Returns: The decoded `PackageJSON`.
/// - Throws: An error if the command fails or decoding fails.
package func packageJSON(
    atPath path: Path,
    subprocessClient: SubprocessClient
) async throws -> PackageJSON {
    let output = try await subprocessClient.runAndCapture(
        command: .swift(.package(.dumpPackage)),
        workingDirectory: path.systemFilePath
    )

    return try JSONDecoder().decode(PackageJSON.self, from: output)
}

/// Runs `swift package show-dependencies --json` and decodes the result.
/// - Parameters:
///   - path: The path to the package directory.
///   - subprocessClient: The subprocess client for executing Swift CLI commands.
/// - Returns: The decoded `PackageGraphDependencies`.
/// - Throws: An error if the command fails or decoding fails.
package func packageGraphDependencies(
    atPath path: Path,
    subprocessClient: SubprocessClient
) async throws -> PackageGraphDependencies {
    let output = try await subprocessClient.runAndCapture(
        command: .swift(.package(.showDependencies(format: .json))),
        workingDirectory: path.systemFilePath
    )

    return try JSONDecoder().decode(PackageGraphDependencies.self, from: output)
}

/// Parses all target dependencies from the current project's Package.swift.
/// - Parameters:
///   - modulesPath: The path to the modules directory.
///   - nooraClient: The Noora client for displaying progress.
///   - subprocessClient: The subprocess client for executing Swift CLI commands.
/// - Returns: An array of target dependencies.
package func parseTargetDependencies(
    modulesPath: String,
    nooraClient: NooraClient,
    subprocessClient: SubprocessClient
) async throws -> [PackageDependency] {
    try await nooraClient.progress(
        message: "Parsing target dependencies",
        successMessage: "Target dependencies parsed",
        errorMessage: "Target dependencies parse failed"
    ) { _ in
        let path = Path(modulesPath)
        let packageJSON = try await packageJSON(atPath: path, subprocessClient: subprocessClient)
        return packageJSON.targets.map { PackageDependency.target($0) }.sorted()
    } as? [PackageDependency] ?? []
}

/// Parses all product dependencies from external packages in the project's dependency graph.
/// - Parameters:
///   - modulesPath: The path to the modules directory.
///   - nooraClient: The Noora client for displaying progress.
///   - subprocessClient: The subprocess client for executing Swift CLI commands.
/// - Returns: An array of product dependencies from external packages.
/// - Throws: An error if the command fails or decoding fails.
package func parseProductDependencies(
    modulesPath: String,
    nooraClient: NooraClient,
    subprocessClient: SubprocessClient
) async throws -> [PackageDependency] {
    try await nooraClient.progress(
        message: "Parsing product dependencies",
        successMessage: "Product dependencies parsed",
        errorMessage: "Product dependencies parse failed"
    ) { _ in
        let path = Path(modulesPath)
        let dependencies = try await packageGraphDependencies(atPath: path, subprocessClient: subprocessClient)

        var productDependencies: [PackageDependency] = []
        for dependency in dependencies.dependencies {
            let path = dependency.path.path
            let packageJSON = try await packageJSON(atPath: path, subprocessClient: subprocessClient)
            let products = packageJSON.products.map { PackageDependency.product($0, packageName: packageJSON.name) }
            productDependencies.append(contentsOf: products)
        }

        return productDependencies.sorted()
    } as? [PackageDependency] ?? []
}

/// Adds dependencies to a target, iterating over each dependency and calling the Swift CLI.
/// - Parameters:
///   - dependencies: The dependencies to add.
///   - targetName: The target to add dependencies to.
///   - path: The path to the package directory.
///   - subprocessClient: The subprocess client for executing Swift CLI commands.
/// - Throws: An error if any command fails.
package func addTargetDependencies(
    _ dependencies: [PackageDependency],
    to targetName: String,
    at path: Path,
    subprocessClient: SubprocessClient
) async throws {
    for dependency in dependencies {
        try await subprocessClient.run(
            command: .swift(
                .package(
                    .addTargetDependency(
                        dependencyName: dependency.name,
                        targetName: targetName,
                        package: dependency.package
                    ),
                    useCustomScratchPath: true
                )
            ),
            workingDirectory: path.systemFilePath
        )
    }
}

/// Runs Swift Format on the project directory.
/// - Parameters:
///   - path: The path to the project directory.
///   - swiftFormatConfigPath: The path to the Swift Format configuration file.
///   - subprocessClient: The subprocess client for executing Swift CLI commands.
///   - nooraClient: The Noora client for displaying progress.
/// - Throws: An error if the command fails.
package func runSwiftFormat(
    at path: Path,
    swiftFormatConfigPath: Path,
    subprocessClient: SubprocessClient,
    nooraClient: NooraClient
) async throws {
    let workingDirectory = path.systemFilePath
    let swiftFormatConfiguration = swiftFormatConfigPath.string

    _ = try await nooraClient.progress(
        message: "Running Swift Format",
        successMessage: "Swift Format changes applied",
        errorMessage: "Swift Format failed"
    ) { _ in
        try await subprocessClient.run(
            command: .swift(.format(.recursiveInPlace(configurationPath: swiftFormatConfiguration))),
            workingDirectory: workingDirectory
        )

        return ()
    }
}

package enum SubcommandError: LocalizedError, Equatable {
    case configFileNotFound

    package var errorDescription: String? {
        switch self {
            case .configFileNotFound:
                return "Could not find 'spm-kit-config.yaml'. Ensure you are inside a valid project directory."
        }
    }
}
