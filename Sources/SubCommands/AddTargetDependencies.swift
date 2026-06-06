//
//  AddTargetDependencies.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-05-26.
//

import ArgumentParser
import Core
import Dependencies
import Foundation
import PathKit
import System

package struct AddTargetDependencies: AsyncParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "add-target-dependencies",
        abstract: "Adds dependencies to an existing target in the current SPM project.",
        discussion:
            """
            Adds additional existing dependencies to an existing target in the Swift package manifest. The target can be provided via command-line argument; missing target value and dependencies will be prompted for interactively.
            """
    )

    @Argument(help: "The name of the target to which dependencies will be added.")
    var targetName: String?

    package init() {}

    package mutating func run() async throws {
        @Dependency(\.pathClient) var pathClient
        @Dependency(\.configClient) var configClient
        @Dependency(\.nooraClient) var nooraClient
        @Dependency(\.subprocessClient) var subprocessClient

        let currentPath = try pathClient.current()
        let configPath = try configPath(currentPath: currentPath)
        let modulesPath = try await configClient.modulesPath(atConfigPath: configPath)
        let swiftFormatConfigPath = try await configClient.swiftFormatConfigPath(atConfigPath: configPath)

        let (selectedTarget, moduleTargets) = try await selectedTarget(
            modulesPath: modulesPath,
            nooraClient: nooraClient,
            subprocessClient: subprocessClient,
            targetName: targetName
        )

        let dependencies = try await selectedDependencies(
            target: selectedTarget,
            moduleTargets: moduleTargets,
            modulesPath: modulesPath,
            nooraClient: nooraClient,
            subprocessClient: subprocessClient
        )

        try await addTargetDependencies(
            dependencies,
            to: selectedTarget,
            at: modulesPath,
            subprocessClient: subprocessClient
        )

        try await runSwiftFormat(
            at: modulesPath,
            swiftFormatConfigPath: swiftFormatConfigPath,
            subprocessClient: subprocessClient,
            nooraClient: nooraClient
        )
    }
}

// MARK: - Errors

package extension AddTargetDependencies {
    /// Errors that can be thrown by the AddTargetDependencies command.
    enum Error: LocalizedError, Equatable {
        /// An error indicating that the spm-kit-config.yaml file was not found.
        case configFileNotFound
        /// An error indicating that no target matching the targetName argument was found.
        case targetNotFound(name: String)
        /// An error indicating that the current project has no targets.
        case targetsNotFound

        package var errorDescription: String? {
            switch self {
                case .configFileNotFound:
                    return "Could not find 'spm-kit-config.yaml'. Ensure you are inside a valid project directory."
                case .targetNotFound(let name):
                    return "Could not find a target named '\(name)'."
                case .targetsNotFound:
                    return "Could not find any targets in the project."
            }
        }
    }
}

// MARK: - Prompts

private extension AddTargetDependencies {
    func selectedTarget(
        modulesPath: Path,
        nooraClient: NooraClient,
        subprocessClient: SubprocessClient,
        targetName: String?
    ) async throws -> (target: PackageDependency, moduleTargets: [PackageDependency]) {
        let targets = try await parseTargetDependencies(
            modulesPath: modulesPath.string,
            nooraClient: nooraClient,
            subprocessClient: subprocessClient
        )

        guard !targets.isEmpty else {
            throw Error.targetsNotFound
        }

        if let targetName {
            guard let target = targets.target(named: targetName) else {
                throw Error.targetNotFound(name: targetName)
            }

            let moduleTargets = targets.filter { $0.name != target.name }
            return (target, moduleTargets)
        } else {
            let selecteTarget = await nooraClient.targetSelection(
                configuration: NooraPromptConfiguration(
                    title: "Selected target",
                    question: "Which target would you like to add dependencies to?"
                ),
                options: targets
            )

            let moduleTargets = targets.filter { $0.name != selecteTarget.name }
            return (selecteTarget, moduleTargets)
        }
    }

    func selectedDependencies(
        target: PackageDependency,
        moduleTargets: [PackageDependency],
        modulesPath: Path,
        nooraClient: NooraClient,
        subprocessClient: SubprocessClient,
    ) async throws -> [PackageDependency] {
        let path = modulesPath.string

        let products = try await parseProductDependencies(
            modulesPath: path,
            nooraClient: nooraClient,
            subprocessClient: subprocessClient
        )

        let availableDependencies = moduleTargets + products
        let compatibleDependencies = availableDependencies.compatible(withSelectedDependency: target)
        if compatibleDependencies.isEmpty {
            await nooraClient.info("No compatible dependencies found.")
            return []
        } else {
            return await nooraClient.dependenciesSelection(
                configuration: NooraPromptConfiguration(
                    title: "Selected target dependencies",
                    question: "Which dependencies would you like to add to the selected target?"
                ),
                options: compatibleDependencies
            )
        }
    }

    func parseTargetDependencies(
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

    func parseProductDependencies(
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
}

// MARK: - Helpers

private extension AddTargetDependencies {
    func configPath(currentPath: Path) throws -> Path {
        guard let configPath = currentPath.ancestor(containing: "spm-kit-config.yaml") else {
            throw Error.configFileNotFound
        }
        return configPath
    }

    func packageJSON(atPath path: Path, subprocessClient: SubprocessClient) async throws -> PackageJSON {
        let output = try await subprocessClient.runAndCapture(
            command: .swift(.package(.dumpPackage)),
            workingDirectory: path.systemFilePath
        )

        return try JSONDecoder().decode(PackageJSON.self, from: output)
    }

    func packageGraphDependencies(
        atPath path: Path,
        subprocessClient: SubprocessClient
    ) async throws -> PackageGraphDependencies {
        let output = try await subprocessClient.runAndCapture(
            command: .swift(.package(.showDependencies(format: .json))),
            workingDirectory: path.systemFilePath
        )

        return try JSONDecoder().decode(PackageGraphDependencies.self, from: output)
    }

    func addTargetDependencies(
        _ dependencies: [PackageDependency],
        to target: PackageDependency,
        at path: Path,
        subprocessClient: SubprocessClient
    ) async throws {
        for dependency in dependencies {
            try await subprocessClient.run(
                command: .swift(
                    .package(
                        .addTargetDependency(
                            dependencyName: dependency.name,
                            targetName: target.name,
                            package: dependency.package
                        ),
                        useCustomScratchPath: true
                    )
                ),
                workingDirectory: path.systemFilePath
            )
        }
    }

    func runSwiftFormat(
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
}
