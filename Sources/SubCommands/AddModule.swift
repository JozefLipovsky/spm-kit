//
//  AddModule.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-18.
//

import ArgumentParser
import Core
import Dependencies
import Foundation
import PathKit
import System

package struct AddModule: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "add-module",
        abstract: "Adds a module to the current SPM project.",
        discussion:
            """
            Creates and configures a new module, including its source files, targets, and products. Any of the module configuration and options values can be provided via command-line arguments; missing values will be prompted for interactively.
            """
    )

    @Argument(help: "The name of the module to add.")
    var name: String?

    @Option(help: "The product type to create for the module.")
    var productType: ProductType?

    @Flag(help: "Skip adding dependencies to the module.")
    var skipDependencies: Bool = false

    @Option(help: "The testing library to use for the module.")
    var testingLibrary: TestingLibrary?

    package init() {}

    package mutating func run() async throws {
        @Dependency(\.pathClient) var pathClient
        @Dependency(\.configClient) var configClient
        @Dependency(\.nooraClient) var nooraClient
        @Dependency(\.subprocessClient) var subprocessClient

        let currentPath = try pathClient.current()
        let configPath = try self.configPath(currentPath: currentPath)
        let modulesPath = try await configClient.modulesPath(atConfigPath: configPath)
        let swiftFormatConfigPath = try await configClient.swiftFormatConfigPath(atConfigPath: configPath)

        let moduleName = await moduleName(nooraClient: nooraClient)
        let productType = await productType(nooraClient: nooraClient)
        let testingLibrary = await testingLibrary(nooraClient: nooraClient)
        let shouldSelectDependencies = await shouldSelectDependencies(nooraClient: nooraClient)
        var targetDependencies: [PackageDependency] = []
        var testTargetDependencies: [PackageDependency] = []

        if shouldSelectDependencies {
            let availableDependencies = try await availableDependencies(
                modulesPath: modulesPath,
                nooraClient: nooraClient,
                subprocessClient: subprocessClient
            )

            if !availableDependencies.isEmpty {
                targetDependencies = try await selectedTargetDependencies(
                    from: availableDependencies,
                    productType: productType,
                    nooraClient: nooraClient
                )

                if testingLibrary != .none {
                    testTargetDependencies = try await selectedTestTargetDependencies(
                        from: availableDependencies,
                        nooraClient: nooraClient
                    )
                }
            }
        }

        try await addTarget(
            at: modulesPath,
            moduleName: moduleName,
            productType: productType,
            testingLibrary: testingLibrary,
            targetDependencies: targetDependencies,
            testTargetDependencies: testTargetDependencies,
            subprocessClient: subprocessClient,
            nooraClient: nooraClient
        )

        try await addProduct(
            at: modulesPath,
            moduleName: moduleName,
            productType: productType,
            subprocessClient: subprocessClient
        )

        try await runSwiftFormat(
            at: currentPath,
            swiftFormatConfigPath: swiftFormatConfigPath.string,
            subprocessClient: subprocessClient
        )
    }
}

// MARK: - Errors

package extension AddModule {
    /// Errors that can be thrown by the AddModule command.
    enum Error: LocalizedError, Equatable {
        /// An error indicating that the spm-kit-config.yaml file was not found.
        case configFileNotFound
        /// An error indicating that an unsupported product type was selected.
        case unsupportedProductType(ProductType)

        package var errorDescription: String? {
            switch self {
                case .configFileNotFound:
                    return "Could not find 'spm-kit-config.yaml'. Ensure you are inside a valid project directory."
                case .unsupportedProductType(let productType):
                    return "Unsupported product type selected: \(productType.rawValue)."
            }
        }
    }
}

// MARK: - Prompts

private extension AddModule {
    func moduleName(nooraClient: NooraClient) async -> String {
        await nooraClient.textInput(
            configuration: NooraPromptConfiguration(
                title: "Module name",
                question: "How would you like to name the new module?",
                validationError: "Module name can not be empty."
            ),
            argument: name
        )
    }

    func productType(nooraClient: NooraClient) async -> ProductType {
        await nooraClient.productTypeSelection(
            configuration: NooraPromptConfiguration(
                title: "Product type",
                question: "Which product type would you like to use for the new module?"
            ),
            argument: productType
        )
    }

    func testingLibrary(nooraClient: NooraClient) async -> TestingLibrary {
        await nooraClient.testingLibrarySelection(
            configuration: NooraPromptConfiguration(
                title: "Testing library",
                question: "Which testing library would you like to use for the new module tests?"
            ),
            argument: testingLibrary
        )
    }

    func shouldSelectDependencies(nooraClient: NooraClient) async -> Bool {
        await nooraClient.yesOrNoConfirmation(
            configuration: NooraPromptConfiguration(
                title: "Dependencies selection",
                question: "Would you like to select dependencies for the new module?"
            ),
            shouldSkip: skipDependencies
        )
    }

    func selectedTargetDependencies(
        from dependencies: [PackageDependency],
        productType: ProductType,
        nooraClient: NooraClient
    ) async throws -> [PackageDependency] {
        let compatibleDependencies = dependencies.compatible(with: productType)
        guard !compatibleDependencies.isEmpty else {
            await nooraClient.info("No compatible target dependencies found.")
            return []
        }

        return await nooraClient.dependenciesSelection(
            configuration: NooraPromptConfiguration(
                title: "Target dependencies",
                question: "Which dependencies would you like to include for the module target?"
            ),
            options: compatibleDependencies
        )
    }

    func selectedTestTargetDependencies(
        from dependencies: [PackageDependency],
        nooraClient: NooraClient
    ) async throws -> [PackageDependency] {
        let compatibleDependencies = dependencies.compatibleWithTestTarget()
        guard !compatibleDependencies.isEmpty else {
            await nooraClient.info("No compatible test target dependencies found.")
            return []
        }

        return await nooraClient.dependenciesSelection(
            configuration: NooraPromptConfiguration(
                title: "Test target dependencies",
                question: "Which dependencies would you like to include for the module test target?",
                description: "The new module's main target will be added automatically."
            ),
            options: compatibleDependencies
        )
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

    func availableDependencies(
        modulesPath: Path,
        nooraClient: NooraClient,
        subprocessClient: SubprocessClient
    ) async throws -> [PackageDependency] {
        let path = modulesPath.string

        let targets = try await parseTargetDependencies(
            modulesPath: path,
            nooraClient: nooraClient,
            subprocessClient: subprocessClient
        )

        let products = try await parseProductDependencies(
            modulesPath: path,
            nooraClient: nooraClient,
            subprocessClient: subprocessClient
        )

        let availableDependencies = targets + products
        if availableDependencies.isEmpty {
            await nooraClient.info("No compatible dependencies found.")
            return []
        } else {
            return availableDependencies
        }
    }
}

// MARK: - Helpers

private extension AddModule {
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

    func addProduct(
        at path: Path,
        moduleName: String,
        productType: ProductType,
        subprocessClient: SubprocessClient
    ) async throws {
        try await subprocessClient.run(
            command: .swift(
                .package(
                    .addProduct(name: moduleName, type: productType, targets: [moduleName]),
                    useCustomScratchPath: true
                )
            ),
            workingDirectory: path.systemFilePath
        )
    }

    func addTarget(
        at path: Path,
        moduleName: String,
        productType: ProductType,
        testingLibrary: TestingLibrary,
        targetDependencies: [PackageDependency],
        testTargetDependencies: [PackageDependency],
        subprocessClient: SubprocessClient,
        nooraClient: NooraClient
    ) async throws {
        guard let targetType = productType.correspondingTargetType() else {
            throw Error.unsupportedProductType(productType)
        }

        let workingDirectory = path.systemFilePath
        let pathString = path.string

        _ = try await nooraClient.progress(
            message: "Adding module target",
            successMessage: "Module target added",
            errorMessage: "Adding module target failed"
        ) { messageUpdate in
            try await subprocessClient.run(
                command: .swift(.package(.addTarget(name: moduleName, type: targetType), useCustomScratchPath: true)),
                workingDirectory: workingDirectory
            )

            if !targetDependencies.isEmpty {
                messageUpdate("Adding target dependencies")
                try await addTargetDependencies(
                    targetDependencies,
                    to: moduleName,
                    at: Path(pathString),
                    subprocessClient: subprocessClient
                )
            }

            switch testingLibrary {
                case .swiftTesting, .xctest:
                    let testTarget = moduleName + "Tests"
                    messageUpdate("Adding test target")
                    try await subprocessClient.run(
                        command: .swift(
                            .package(
                                .addTarget(name: testTarget, type: .test, testingLibrary: testingLibrary),
                                useCustomScratchPath: true
                            )
                        ),
                        workingDirectory: workingDirectory
                    )

                    try await subprocessClient.run(
                        command: .swift(
                            .package(
                                .addTargetDependency(dependencyName: moduleName, targetName: testTarget),
                                useCustomScratchPath: true
                            )
                        ),
                        workingDirectory: workingDirectory
                    )

                    if !testTargetDependencies.isEmpty {
                        messageUpdate("Adding test target dependencies")
                        try await addTargetDependencies(
                            testTargetDependencies,
                            to: testTarget,
                            at: Path(pathString),
                            subprocessClient: subprocessClient
                        )
                    }

                case .none:
                    break
            }

            return ()
        }
    }

    func runSwiftFormat(at path: Path, swiftFormatConfigPath: String, subprocessClient: SubprocessClient) async throws {
        try await subprocessClient.run(
            command: .swift(.format(.recursiveInPlace(configurationPath: swiftFormatConfigPath))),
            workingDirectory: path.systemFilePath
        )
    }

    func addTargetDependencies(
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
}
