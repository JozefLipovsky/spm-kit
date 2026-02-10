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
        let modulesPath = try await modulesPath(currentPath: currentPath, configClient: configClient)
        let swiftFormatConfigPath = try await swiftFormatConfigPath(
            currentPath: currentPath,
            configClient: configClient
        )

        let moduleName = await moduleName(nooraClient: nooraClient)
        let productType = await productType(nooraClient: nooraClient)
        let testingLibrary = await testingLibrary(nooraClient: nooraClient)
        let shouldSelectDependencies = await shouldSelectDependencies(nooraClient: nooraClient)
        var dependencies: [any PackageDependency] = []

        if shouldSelectDependencies {
            let targetDependencies = try await targetDependencies(
                productType: productType,
                modulesPath: modulesPath,
                nooraClient: nooraClient,
                subprocessClient: subprocessClient
            )

            let productDependencies = try await productDependencies(
                productType: productType,
                modulesPath: modulesPath,
                nooraClient: nooraClient,
                subprocessClient: subprocessClient
            )

            dependencies.append(contentsOf: targetDependencies)
            dependencies.append(contentsOf: productDependencies)
        }

        try await addTarget(
            at: modulesPath,
            moduleName: moduleName,
            productType: productType,
            testingLibrary: testingLibrary,
            dependencies: dependencies,
            subprocessClient: subprocessClient
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

    func targetDependencies(
        productType: ProductType,
        modulesPath: Path,
        nooraClient: NooraClient,
        subprocessClient: SubprocessClient
    ) async throws -> [any PackageDependency] {
        let availableTargetDependencies = try await availableTargetDependencies(
            productType: productType,
            modulesPath: modulesPath.string,
            nooraClient: nooraClient,
            subprocessClient: subprocessClient
        )

        guard availableTargetDependencies.isEmpty else {
            return await nooraClient.targetDependenciesSelection(
                configuration: NooraPromptConfiguration(
                    title: "Target dependencies",
                    question: "Which target dependencies would you like to include?"
                ),
                options: availableTargetDependencies
            )
        }

        await nooraClient.info(
            "No compatible target dependencies found for product type: \(productType.rawValue). Skipping selection."
        )

        return []
    }

    func productDependencies(
        productType: ProductType,
        modulesPath: Path,
        nooraClient: NooraClient,
        subprocessClient: SubprocessClient
    ) async throws -> [any PackageDependency] {
        let availableProductDependencies = try await availableProductDependencies(
            productType: productType,
            modulesPath: modulesPath.string,
            nooraClient: nooraClient,
            subprocessClient: subprocessClient
        )

        guard availableProductDependencies.isEmpty else {
            return await nooraClient.productDependenciesSelection(
                configuration: NooraPromptConfiguration(
                    title: "External dependencies",
                    question: "Which external dependencies would you like to include?"
                ),
                options: availableProductDependencies
            )
        }

        await nooraClient.info(
            "No compatible external dependencies found for product type: \(productType.rawValue). Skipping selection."
        )

        return []
    }

    func availableTargetDependencies(
        productType: ProductType,
        modulesPath: String,
        nooraClient: NooraClient,
        subprocessClient: SubprocessClient
    ) async throws -> [TargetDependency] {
        try await nooraClient.operationProgress(message: "Fetching target dependencies") {
            let path = Path(modulesPath)
            let packageJSON = try await packageJSON(atPath: path, subprocessClient: subprocessClient)
            switch productType {
                case .library, .staticLibrary, .dynamicLibrary, .executable:
                    let targets = packageJSON.targets.filter { $0.type == .executable || $0.type == .regular }
                    return targets.map { TargetDependency(target: $0) }.sorted { $0.description < $1.description }
                case .plugin:
                    throw Error.unsupportedProductType(productType)
            }
        } as? [TargetDependency] ?? []
    }

    func availableProductDependencies(
        productType: ProductType,
        modulesPath: String,
        nooraClient: NooraClient,
        subprocessClient: SubprocessClient
    ) async throws -> [ProductDependency] {
        try await nooraClient.operationProgress(message: "Fetching external dependencies") {
            let path = Path(modulesPath)
            let dependencies = try await packageGraphDependencies(atPath: path, subprocessClient: subprocessClient)

            var productDependencies: [ProductDependency] = []
            for dependency in dependencies.dependencies {
                let path = dependency.path.path
                let packageJSON = try await packageJSON(atPath: path, subprocessClient: subprocessClient)

                var products: [PackageJSON.Product] = []
                switch productType {
                    case .library, .staticLibrary, .dynamicLibrary:
                        products = packageJSON.products.filter { $0.type == .library }
                    case .executable:
                        products = packageJSON.products.filter { $0.type == .executable }
                    case .plugin:
                        products = packageJSON.products.filter { $0.type == .plugin }
                }

                productDependencies.append(
                    contentsOf: products.map { ProductDependency(product: $0, packageName: packageJSON.name) }
                )
            }

            return productDependencies.sorted { $0.description < $1.description }
        } as? [ProductDependency] ?? []
    }
}

// MARK: - Helpers

private extension AddModule {
    func modulesPath(currentPath: Path, configClient: ConfigClient) async throws -> Path {
        guard let configPath = currentPath.ancestor(containing: "spm-kit-config.yaml") else {
            throw Error.configFileNotFound
        }

        return try await configClient.modulesPath(atConfigPath: configPath)
    }

    func swiftFormatConfigPath(currentPath: Path, configClient: ConfigClient) async throws -> Path {
        guard let configPath = currentPath.ancestor(containing: "spm-kit-config.yaml") else {
            throw Error.configFileNotFound
        }

        return try await configClient.swiftFormatConfigPath(atConfigPath: configPath)
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
        dependencies: [any PackageDependency],
        subprocessClient: SubprocessClient
    ) async throws {
        var targetType: TargetType
        switch productType {
            case .library, .staticLibrary, .dynamicLibrary:
                targetType = .library
            case .executable:
                targetType = .executable
            case .plugin:
                throw Error.unsupportedProductType(productType)
        }

        try await subprocessClient.run(
            command: .swift(.package(.addTarget(name: moduleName, type: targetType), useCustomScratchPath: true)),
            workingDirectory: path.systemFilePath
        )

        for dependency in dependencies {
            try await subprocessClient.run(
                command: .swift(
                    .package(
                        .addTargetDependency(
                            dependencyName: dependency.name,
                            targetName: moduleName,
                            package: dependency.package
                        ),
                        useCustomScratchPath: true
                    )
                ),
                workingDirectory: path.systemFilePath
            )
        }

        switch testingLibrary {
            case .swiftTesting, .xctest:
                try await subprocessClient.run(
                    command: .swift(
                        .package(
                            .addTarget(name: moduleName + "Tests", type: .test, testingLibrary: testingLibrary),
                            useCustomScratchPath: true
                        )
                    ),
                    workingDirectory: path.systemFilePath
                )

                try await subprocessClient.run(
                    command: .swift(
                        .package(
                            .addTargetDependency(dependencyName: moduleName, targetName: moduleName + "Tests"),
                            useCustomScratchPath: true
                        )
                    ),
                    workingDirectory: path.systemFilePath
                )
            case .none:
                break
        }
    }

    func runSwiftFormat(at path: Path, swiftFormatConfigPath: String, subprocessClient: SubprocessClient) async throws {
        try await subprocessClient.run(
            command: .swift(.format(.recursiveInPlace(configurationPath: swiftFormatConfigPath))),
            workingDirectory: path.systemFilePath
        )
    }
}
