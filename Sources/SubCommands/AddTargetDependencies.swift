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
            Adds additional existing dependencies to an existing target in the Swift package. The target and dependencies can be provided via command-line arguments; missing values will be prompted for interactively.
            """
    )

    @Argument(help: "The name of the dependency to add.")
    var dependencyName: String?

    @Argument(help: "The name of the target to which dependencies will be added.")
    var targetName: String?

    @Option(help: "The name of the package in which the dependency resides.")
    var package: String?

    package init() {}

    package mutating func run() async throws {
        @Dependency(\.pathClient) var pathClient
        @Dependency(\.configClient) var configClient
        @Dependency(\.nooraClient) var nooraClient
        @Dependency(\.subprocessClient) var subprocessClient

        let currentPath = try pathClient.current()
        let configPath = try configPath(currentPath: currentPath)
        let modulesPath = try await configClient.modulesPath(atConfigPath: configPath)

        let target = try await selectedTarget(
            modulesPath: modulesPath,
            nooraClient: nooraClient,
            subprocessClient: subprocessClient,
            targetName: targetName
        )

        // TODO: Add
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
    ) async throws -> PackageDependency {
        let targets = try await parseTargetDependencies(
            modulesPath: modulesPath.string,
            nooraClient: nooraClient,
            subprocessClient: subprocessClient
        )

        guard !targets.isEmpty else {
            throw Error.targetsNotFound
        }

        if let targetName {
            guard let target = targets.first(where: { $0.name == targetName }) else {
                throw Error.targetNotFound(name: targetName)
            }

            return target
        } else {
            return await nooraClient.targetSelection(
                configuration: NooraPromptConfiguration(
                    title: "Target name",
                    question: "Which target would you like to add dependencies to?"
                ),
                options: targets
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
}
