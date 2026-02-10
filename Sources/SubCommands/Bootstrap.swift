//
//  Bootstrap.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-03.
//

import ArgumentParser
import Core
import Dependencies
import Foundation
import Noora
import PathKit

package struct Bootstrap: AsyncParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "bootstrap-project",
        abstract: "Initializes a new, modular Swift Package Manager (SPM) based project.",
        discussion:
            """
            Initializes a new SPM project with maximum flexibility in configuration. Any of the project configuration and options values can be provided via command-line arguments; missing values will be prompted for interactively.
            """
    )

    @Argument(help: "The name of the new project.")
    var name: String?

    @Option(
        help:
            """
            The company domain or unique namespace that will be reversed and combined with the project name. For example, 'example.com' becomes 'com.example' which is then combined with the project name to create the bundle identifier in reverse DNS format 'com.example.projectName'.
            """
    )
    var companyDomain: String?

    @OptionGroup(title: "Project platform(s) configuration")
    var platforms: PlatformOptions

    @Option(help: "The name for the initial 'root' module of the project.")
    var rootModule: String?

    @Option(help: "The testing framework to use for the 'root' module tests.")
    var testingLibrary: TestingLibrary?

    package init() {}

    package func validate() throws {
        @Dependency(\.pathClient) var pathClient
        let currentPath = try pathClient.current()

        if currentPath.containsBootstrappedProject {
            let errorMessage = "Directory '\(currentPath)' already contains a bootstrapped project."
            throw Error.validation(message: errorMessage)
        }
    }

    package mutating func run() async throws {
        @Dependency(\.pathClient) var pathClient
        @Dependency(\.configClient) var configClient
        @Dependency(\.subprocessClient) var subprocessClient
        @Dependency(\.resourcesClient) var resourcesClient
        @Dependency(\.packageEditorClient) var packageEditorClient
        @Dependency(\.stencilTemplateClient) var stencilTemplateClient
        @Dependency(\.xcodeProjClient) var xcodeProjClient
        @Dependency(\.nooraClient) var nooraClient

        let projectName = await projectName(nooraClient: nooraClient)
        let selectedPlatforms = await platforms(nooraClient: nooraClient)
        let bundleIdentifier = await bundleIdentifier(nooraClient: nooraClient, projectName: projectName)
        let rootModule = await rootModule(nooraClient: nooraClient)
        let testingLibrary = await testingLibrary(nooraClient: nooraClient)

        let currentPath = try pathClient.current()
        let projectBasePath = try createRootDirectoryIfNeeded(projectName: projectName, at: currentPath)

        do {
            try await copyProjectTemplates(
                to: projectBasePath,
                subprocessClient: subprocessClient,
                resourcesClient: resourcesClient
            )

            try await configurePackage(
                at: projectBasePath,
                selectedPlatforms: selectedPlatforms,
                rootModule: rootModule,
                testingLibrary: testingLibrary,
                subprocessClient: subprocessClient,
                packageEditorClient: packageEditorClient
            )

            try await configureRootModule(
                at: projectBasePath,
                projectName: projectName,
                rootModule: rootModule,
                subprocessClient: subprocessClient,
                stencilTemplateClient: stencilTemplateClient,
                resourcesClient: resourcesClient
            )

            try await configureWorkspace(
                at: projectBasePath,
                projectName: projectName,
                subprocessClient: subprocessClient,
                xcodeProjClient: xcodeProjClient
            )

            try await configureProject(
                at: projectBasePath,
                projectName: projectName,
                selectedPlatforms: selectedPlatforms,
                bundleIdentifier: bundleIdentifier,
                rootModule: rootModule,
                subprocessClient: subprocessClient,
                xcodeProjClient: xcodeProjClient,
                stencilTemplateClient: stencilTemplateClient
            )
        } catch {
            // Remove incomplete project when one of the configurations steps failed.
            try deleteRootProjectDirectoryIfNeeded(projectBasePath: projectBasePath, currentPath: currentPath)
            // Re-throw the error, inform user about failure reasons.
            throw error
        }

        try await runSwiftFormat(
            at: projectBasePath,
            configClient: configClient,
            subprocessClient: subprocessClient
        )
    }
}

// MARK: - Errors

package extension Bootstrap {
    /// Errors that can be thrown by the Bootstrap command.
    enum Error: LocalizedError, Equatable {
        /// An error indicating that a command's preconditions have not been met.
        case validation(message: String)
        /// An error indicating that the spm-kit-config.yaml file was not found.
        case configFileNotFound

        package var errorDescription: String? {
            switch self {
                case .validation(let message):
                    return "Validation failed: " + message
                case .configFileNotFound:
                    return "Could not find 'spm-kit-config.yaml'. Ensure you are inside a valid project directory."
            }
        }
    }
}

// MARK: - Prompts

private extension Bootstrap {
    func projectName(nooraClient: NooraClient) async -> String {
        await nooraClient.textInput(
            configuration: NooraPromptConfiguration(
                title: "Project name",
                question: "How would you like to name your project?",
                validationError: "Project name can not be empty."
            ),
            argument: name
        )
    }

    func platforms(nooraClient: NooraClient) async -> [any PlatformVersion] {
        await nooraClient.platformsSelection(
            configuration: NooraPromptConfiguration(
                title: "Platform(s)",
                question: "Which platforms would you like to configure?",
                minLimitError: "At least one platform must be selected."
            ),
            argument: platforms.selectedVersions
        )
    }

    func bundleIdentifier(nooraClient: NooraClient, projectName: String) async -> String {
        let companyDomain = await nooraClient.textInput(
            configuration: NooraPromptConfiguration(
                title: "Company domain",
                question: "What domain or unique namespace should be used to construct the bundle identifier?",
                validationError: "Company domain can not be empty."
            ),
            argument: companyDomain
        )

        let reversedDomain = companyDomain.components(separatedBy: ".").reversed().joined(separator: ".")
        return "\(reversedDomain).\(projectName)"
    }

    func rootModule(nooraClient: NooraClient) async -> String {
        await nooraClient.textInput(
            configuration: NooraPromptConfiguration(
                title: "Root module",
                question: "How would you like to name the initial root module of the project?",
                validationError: "Root module name can not be empty."
            ),
            argument: rootModule
        )
    }

    func testingLibrary(nooraClient: NooraClient) async -> TestingLibrary {
        await nooraClient.testingLibrarySelection(
            configuration: NooraPromptConfiguration(
                title: "Testing library",
                question: "Which testing library would you like to use for the root module tests?"
            ),
            argument: testingLibrary
        )
    }
}

// MARK: - Helpers

private extension Bootstrap {
    func createRootDirectoryIfNeeded(projectName: String, at path: Path) throws -> Path {
        guard !path.isRootPath(of: projectName) else {
            return path
        }

        let projectRootPath = path + projectName
        try projectRootPath.mkdir()
        return projectRootPath
    }

    func deleteRootProjectDirectoryIfNeeded(projectBasePath: Path, currentPath: Path) throws {
        guard currentPath != projectBasePath, projectBasePath.exists, projectBasePath.isDeletable else {
            return
        }

        try projectBasePath.delete()
    }

    func copyProjectTemplates(
        to projectBasePath: Path,
        subprocessClient: SubprocessClient,
        resourcesClient: ResourcesClient
    ) async throws {
        let projectRootDirectory = ProjectDirectory.root()

        let xcodeProjectTemplate = try await resourcesClient.templateItem(type: .xcodeProject)
        try await subprocessClient.run(
            command: .update(.copy(xcodeProjectTemplate, to: projectRootDirectory)),
            workingDirectory: projectBasePath.systemFilePath
        )

        let spmKitConfigTemplate = try await resourcesClient.templateItem(type: .spmKitConfig)
        try await subprocessClient.run(
            command: .update(.copy(spmKitConfigTemplate, to: projectRootDirectory)),
            workingDirectory: projectBasePath.systemFilePath
        )

        let swiftFormatConfigTemplate = try await resourcesClient.templateItem(type: .swiftFormatConfig)
        try await subprocessClient.run(
            command: .update(.copy(swiftFormatConfigTemplate, to: projectRootDirectory)),
            workingDirectory: projectBasePath.systemFilePath
        )
    }

    func configurePackage(
        at projectBasePath: Path,
        selectedPlatforms: [any PlatformVersion],
        rootModule: String,
        testingLibrary: TestingLibrary,
        subprocessClient: SubprocessClient,
        packageEditorClient: PackageEditorClient
    ) async throws {
        let modulesDirectory = ProjectDirectory.modules()
        let modulesPath = projectBasePath + modulesDirectory.pathString

        let minToolsVersion = selectedPlatforms.min { $0.toolsVersion < $1.toolsVersion }
        if let minToolsVersionIdentifier = minToolsVersion?.toolsVersionIdentifier {
            try await subprocessClient.run(
                command: .swift(.package(.setToolsVersion(version: minToolsVersionIdentifier))),
                workingDirectory: modulesPath.systemFilePath
            )
        }

        let packageManifestDirectory = ProjectDirectory.modules(.packageManifest)
        let packageManifestPath = projectBasePath + packageManifestDirectory.pathString
        try await packageEditorClient.add(platforms: selectedPlatforms, toManifestAt: packageManifestPath)

        try await subprocessClient.run(
            command: .swift(.package(.addProduct(name: rootModule, targets: [rootModule]))),
            workingDirectory: modulesPath.systemFilePath
        )

        try await subprocessClient.run(
            command: .swift(.package(.addTarget(name: rootModule))),
            workingDirectory: modulesPath.systemFilePath
        )

        switch testingLibrary {
            case .swiftTesting, .xctest:
                let addTargetSubcommand = ShellCommand.SwiftSubCommand.PackageSubCommand.addTarget(
                    name: rootModule + "Tests",
                    type: .test,
                    testingLibrary: testingLibrary
                )

                try await subprocessClient.run(
                    command: .swift(.package(addTargetSubcommand, useCustomScratchPath: true)),
                    workingDirectory: modulesPath.systemFilePath
                )

                try await subprocessClient.run(
                    command: .swift(
                        .package(
                            .addTargetDependency(
                                dependencyName: rootModule,
                                targetName: rootModule + "Tests",
                                package: nil
                            ),
                            useCustomScratchPath: true
                        )
                    ),
                    workingDirectory: modulesPath.systemFilePath
                )
            case .none:
                break
        }
    }

    func configureRootModule(
        at projectBasePath: Path,
        projectName: String,
        rootModule: String,
        subprocessClient: SubprocessClient,
        stencilTemplateClient: StencilTemplateClient,
        resourcesClient: ResourcesClient
    ) async throws {
        let rootModuleFileTemplate = try await resourcesClient.templateItem(type: .rootModuleView)
        let rootModuleFile = ProjectDirectory.modules(
            .sources(.module(rootModule, file: .file(rootModule, fileExtension: .swift)))
        )

        try await subprocessClient.run(
            command: .update(.replace(rootModuleFile, with: rootModuleFileTemplate)),
            workingDirectory: projectBasePath.systemFilePath
        )

        let rootModuleFilePath = projectBasePath + rootModuleFile.pathString
        try await stencilTemplateClient.processRootModuleTemplate(
            atPath: rootModuleFilePath,
            projectName: projectName,
            moduleName: rootModule
        )

        try await subprocessClient.run(
            command: .rename(.projectItem(rootModuleFile, to: rootModule + "View")),
            workingDirectory: projectBasePath.systemFilePath
        )
    }

    func configureWorkspace(
        at projectBasePath: Path,
        projectName: String,
        subprocessClient: SubprocessClient,
        xcodeProjClient: XcodeProjClient
    ) async throws {
        let workspace = ProjectDirectory.root(.file("Template", fileExtension: .xcworkspace))
        try await subprocessClient.run(
            command: .rename(.projectItem(workspace, to: projectName)),
            workingDirectory: projectBasePath.systemFilePath
        )

        let renamedWorkspace = ProjectDirectory.root(.file(projectName, fileExtension: .xcworkspace))
        let renamedWorkspacePath = projectBasePath + renamedWorkspace.pathString
        try await xcodeProjClient.updateProjectReference(inWorkspace: renamedWorkspacePath, newProjectName: projectName)
    }

    func configureProject(
        at projectBasePath: Path,
        projectName: String,
        selectedPlatforms: [any PlatformVersion],
        bundleIdentifier: String,
        rootModule: String,
        subprocessClient: SubprocessClient,
        xcodeProjClient: XcodeProjClient,
        stencilTemplateClient: StencilTemplateClient
    ) async throws {
        let project = ProjectDirectory.app(.root(.file("App", fileExtension: .xcodeproj)))
        try await subprocessClient.run(
            command: .rename(.projectItem(project, to: projectName)),
            workingDirectory: projectBasePath.systemFilePath
        )

        let renamedProject = ProjectDirectory.app(.root(.file(projectName, fileExtension: .xcodeproj)))
        let projectPath = projectBasePath + renamedProject.pathString
        let projectRoot = ProjectDirectory.app()
        let projectRootPath = projectBasePath + projectRoot.pathString

        let projectConfig = ProjectConfiguration(
            projectPath: projectPath,
            projectRootPath: projectRootPath,
            newProjectName: projectName,
            selectedPlatforms: selectedPlatforms,
            bundleIdentifier: bundleIdentifier,
            rootModuleName: rootModule
        )

        try await xcodeProjClient.configureProject(configuration: projectConfig)

        try await stencilTemplateClient.processSelectedTargetsAppTemplates(
            targetAppTemplates: projectConfig.selectedTargetsAppTemplates,
            moduleName: rootModule
        )
    }

    func runSwiftFormat(
        at projectBasePath: Path,
        configClient: ConfigClient,
        subprocessClient: SubprocessClient
    ) async throws {
        guard let configPath = projectBasePath.ancestor(containing: "spm-kit-config.yaml") else {
            throw Error.configFileNotFound
        }

        let swiftFormatConfigPath = try await configClient.swiftFormatConfigPath(atConfigPath: configPath)

        try await subprocessClient.run(
            command: .swift(.format(.recursiveInPlace(configurationPath: swiftFormatConfigPath.string))),
            workingDirectory: projectBasePath.systemFilePath
        )
    }
}
