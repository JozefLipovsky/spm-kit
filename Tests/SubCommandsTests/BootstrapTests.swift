//
//  BootstrapTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-07.
//

import ArgumentParser
import Core
import Noora
import PathKit
import SubCommands
import TestHelpers
import Testing

// swiftlint:disable function_body_length type_body_length
@Suite("Bootstrap Tests", .tags(.unit))
struct BootstrapTests {

    // MARK: - Validation

    @Test(
        "validate() - when directory contains bootstrapped project - throws validation error",
        .bootstrapEnvironmentMock(pathStub: .temporaryWithBase(named: "MyTestProject", includeProjectTemplate: true))
    )
    func validate_whenDirectoryContainsBootstrappedProject_throwsValidationError() async throws {
        // Given
        let sut = Bootstrap()

        let error = #expect(throws: Bootstrap.Error.self) {
            // When
            try sut.validate()
        }

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let contextPath = context.workingDirectory
        let errorDescription = try #require(error?.localizedDescription)
        let expectedError = "Validation failed: Directory '\(contextPath)' already contains a bootstrapped project."
        #expect(errorDescription == expectedError)
    }

    @Test(
        "validate() - when directory doesn't contain bootstrapped project - validation passes",
        .bootstrapEnvironmentMock()
    )
    func validate_whenDirectoryDoesNotContainBootstrappedProject_validationPasses() async throws {
        // Given
        let sut = Bootstrap()

        // Then
        #expect(throws: Never.self) {
            // When
            try sut.validate()
        }
    }

    // MARK: - Run - Configuration

    @Test("run() - with default arguments - executes all commands and edits correctly", .bootstrapEnvironmentMock())
    func run_withDefaultArguments_executesAllCommandsAndEditsCorrectly() async throws {
        // Given
        let rootModule = "RootModuleStub"
        let projectName = "ProjectStub"
        let domain = "example.com"
        let testingLibrary = TestingLibrary.swiftTesting
        let arguments = [
            projectName,
            "--iOS",
            "v26",
            "--company-domain",
            domain,
            "--root-module",
            rootModule,
            "--testing-library",
            testingLibrary.description
        ]
        var sut = try Bootstrap.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let projectBasePath = Path(context.workingDirectory + "/\(projectName)")
        let commands = try #require(await context.subprocessClientSpy.runCalls)
        let resourceRequests = try #require(await context.resourcesClientSpy.templateItemCalls)
        let packageEdits = try #require(await context.packageEditorClientSpy.addedPlatforms)
        let workspaceProjectRefEdits = try #require(await context.xcodeProjClientSpy.projectReferenceUpdates)
        let rootModuleEdits = try #require(await context.stencilTemplateClientSpy.processedRootModuleTemplates)
        let projectConfigEdits = try #require(await context.xcodeProjClientSpy.projectConfigurations)
        let appTemplatesEdits = try #require(await context.stencilTemplateClientSpy.processedAppTargetsTemplates)
        let textInputPrompts = try #require(await context.nooraClientSpy.textInputs)
        let testingLibrarySelection = try #require(await context.nooraClientSpy.testingLibrarySelections)
        let platformSelection = try #require(await context.nooraClientSpy.platformsSelections)
        let swiftFormatConfigPaths = try #require(await context.configClientSpy.swiftFormatConfigPathConfigPaths)

        #expect(commands.count == 13)
        #expect(resourceRequests.count == 4)
        #expect(projectBasePath.exists)
        #expect(textInputPrompts.count == 3)
        #expect(testingLibrarySelection.count == 1)
        #expect(platformSelection.count == 1)
        #expect(packageEdits.count == 1)
        #expect(workspaceProjectRefEdits.count == 1)
        #expect(projectConfigEdits.count == 1)
        #expect(rootModuleEdits.count == 1)
        #expect(appTemplatesEdits.count == 1)
        #expect(swiftFormatConfigPaths.count == 1)

        // Prompts
        #expect(textInputPrompts[0].argument == projectName)
        #expect(textInputPrompts[1].argument == domain)
        #expect(textInputPrompts[2].argument == rootModule)
        #expect(testingLibrarySelection[0].argument == testingLibrary)
        #expect(platformSelection[0].argument?.count == 1)
        #expect(platformSelection[0].argument?[0].platform.identifier == "iOS")
        #expect(platformSelection[0].argument?[0].versionIdentifier == "v26")

        // copyProjectTemplates
        let copyXcodeProjectCommand = ShellCommand.update(
            .copy(TemplateItem(path: "/fake/path/to/XcodeProject", copyFlags: ["-R"]), to: .root())
        )
        let copySpmKitConfigCommand = ShellCommand.update(
            .copy(TemplateItem(path: "/fake/path/to/spm-kit-config.yaml"), to: .root())
        )
        let copySwiftFormatConfigCommand = ShellCommand.update(
            .copy(TemplateItem(path: "/fake/path/to/.swift-format"), to: .root())
        )
        #expect(resourceRequests[0] == .xcodeProject)
        #expect(commands[0].command == copyXcodeProjectCommand)
        #expect(resourceRequests[1] == .spmKitConfig)
        #expect(commands[1].command == copySpmKitConfigCommand)
        #expect(resourceRequests[2] == .swiftFormatConfig)
        #expect(commands[2].command == copySwiftFormatConfigCommand)

        // configurePackage
        let addProductCommand = ShellCommand.swift(
            .package(.addProduct(name: rootModule, type: .library, targets: [rootModule]))
        )
        let addTestTargetCommand = ShellCommand.swift(
            .package(
                .addTarget(
                    name: "\(rootModule)Tests",
                    type: .test,
                    testingLibrary: testingLibrary
                ),
                useCustomScratchPath: true
            )
        )
        let addTargetDependencyCommand = ShellCommand.swift(
            .package(
                .addTargetDependency(
                    dependencyName: rootModule,
                    targetName: "\(rootModule)Tests",
                    package: nil
                ),
                useCustomScratchPath: true
            )
        )
        #expect(commands[3].command == .swift(.package(.setToolsVersion(version: "6.2"))))
        #expect(packageEdits.count == 1)
        #expect(packageEdits[0].platform.identifier == "iOS")
        #expect(packageEdits[0].version == "v26")
        #expect(packageEdits[0].path.hasSuffix("/Modules/Package.swift"))
        #expect(commands[4].command == addProductCommand)
        #expect(commands[5].command == .swift(.package(.addTarget(name: rootModule, type: .library))))
        #expect(commands[6].command == addTestTargetCommand)
        #expect(commands[7].command == addTargetDependencyCommand)

        // configureRootModule
        let rootModuleFile = ProjectDirectory.modules(
            .sources(.module(rootModule, file: .file(rootModule, fileExtension: .swift)))
        )
        let replaceCommand = ShellCommand.update(
            .replace(rootModuleFile, with: TemplateItem(path: "/fake/path/to/RootModuleView.swift"))
        )
        #expect(resourceRequests[3] == .rootModuleView)
        #expect(commands[8].command == replaceCommand)
        #expect(rootModuleEdits[0].path.hasSuffix("\(projectName)/Modules/Sources/\(rootModule)/\(rootModule).swift"))
        #expect(rootModuleEdits[0].projectName == projectName)
        #expect(rootModuleEdits[0].moduleName == rootModule)
        #expect(commands[9].command == .rename(.projectItem(rootModuleFile, to: rootModule + "View")))

        // configureWorkspace
        let workspaceRenameCommand = ShellCommand.rename(
            .projectItem(.root(.file("Template", fileExtension: .xcworkspace)), to: projectName)
        )
        #expect(commands[10].command == workspaceRenameCommand)
        #expect(workspaceProjectRefEdits[0].workspacePath.hasSuffix("\(projectName)/\(projectName).xcworkspace"))
        #expect(workspaceProjectRefEdits[0].newProjectName == projectName)

        // configureProject
        let projectRenameCommand = ShellCommand.rename(
            .projectItem(.app(.root(.file("App", fileExtension: .xcodeproj))), to: projectName)
        )
        #expect(commands[11].command == projectRenameCommand)
        #expect(projectConfigEdits[0].projectPath.hasSuffix("\(projectName)/App/\(projectName).xcodeproj"))
        #expect(projectConfigEdits[0].selectedPlatforms.count == 1)
        #expect(projectConfigEdits[0].selectedPlatforms[0].platform.identifier == "iOS")
        #expect(projectConfigEdits[0].selectedPlatforms[0].version == "v26")
        #expect(projectConfigEdits[0].projectRootPath.hasSuffix("\(projectName)/App"))
        #expect(projectConfigEdits[0].newProjectName == projectName)
        #expect(projectConfigEdits[0].bundleIdentifier == "com.example.\(projectName)")
        #expect(projectConfigEdits[0].rootModuleName == rootModule)
        #expect(appTemplatesEdits[0].paths.count == 1)
        #expect(appTemplatesEdits[0].paths[0].hasSuffix("\(projectName)/App/iOS/iOSApp.swift"))
        #expect(appTemplatesEdits[0].moduleName == rootModule)

        // run swift format
        let swiftFormatCommand = ShellCommand.swift(
            .format(.recursiveInPlace(configurationPath: "/fake/path/to/.swift-format-stub"))
        )
        #expect(swiftFormatConfigPaths[0].hasSuffix("spm-kit-config.yaml"))
        #expect(commands[12].command == swiftFormatCommand)
    }

    @Test(
        "run() - with testing library - configures test targets correctly",
        .bootstrapEnvironmentMock(
            nooraClientStubs: .init(
                projectName: "MyTestProject",
                rootModule: "TestFeature",
                testingLibrary: .xctest
            )
        )
    )
    func run_withTestingLibrary_configuresTestTargetsCorrectly() async throws {
        // Given
        let arguments = [
            "MyTestProject",
            "--iOS",
            "v26",
            "--company-domain",
            "example.com",
            "--root-module",
            "TestFeature",
            "--testing-library",
            "xctest"
        ]

        var sut = try Bootstrap.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let commands = try #require(await context.subprocessClientSpy.runCalls)

        #expect(commands.count == 13)

        let addTestCommand = ShellCommand.swift(
            .package(
                .addTarget(
                    name: "TestFeatureTests",
                    type: .test,
                    testingLibrary: .xctest
                ),
                useCustomScratchPath: true
            )
        )

        let addTargetDependencyCommand = ShellCommand.swift(
            .package(
                .addTargetDependency(
                    dependencyName: "TestFeature",
                    targetName: "TestFeatureTests",
                    package: nil
                ),
                useCustomScratchPath: true
            )
        )

        #expect(commands[6].command == addTestCommand)
        #expect(commands[7].command == addTargetDependencyCommand)
    }

    @Test(
        "run() - with single platform - configures single platform correctly",
        .bootstrapEnvironmentMock(
            nooraClientStubs: .init(
                projectName: "Project",
                platforms: [MacOSVersion.v15],
                testingLibrary: .none
            )
        )
    )
    func run_withSinglePlatform_configuresPlatformCorrectly() async throws {
        // Given
        let arguments = [
            "Project",
            "--company-domain",
            "example.com",
            "--root-module",
            "feature",
            "--testing-library",
            "none",
            "--macOS",
            "v15"
        ]
        var sut = try Bootstrap.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let packageEdits = try #require(await context.packageEditorClientSpy.addedPlatforms)
        let projectConfigEdits = try #require(await context.xcodeProjClientSpy.projectConfigurations)
        let commands = try #require(await context.subprocessClientSpy.runCalls)

        #expect(packageEdits.count == 1)
        #expect(projectConfigEdits.count == 1)
        #expect(commands.count == 11)

        #expect(packageEdits[0].platform.identifier == "macOS")
        #expect(packageEdits[0].version == "v15")
        #expect(packageEdits[0].path.hasSuffix("Project/Modules/Package.swift"))

        #expect(projectConfigEdits[0].selectedPlatforms.count == 1)
        #expect(projectConfigEdits[0].selectedPlatforms[0].platform.identifier == "macOS")
        #expect(projectConfigEdits[0].selectedPlatforms[0].version == "v15")
        #expect(projectConfigEdits[0].projectPath.hasSuffix("Project/App/Project.xcodeproj"))

        #expect(commands[3].command == .swift(.package(.setToolsVersion(version: "6.0"))))
    }

    @Test(
        "run() - with multiple platforms - configures all platforms correctly",
        .bootstrapEnvironmentMock(
            nooraClientStubs: .init(
                projectName: "Project",
                platforms: [MacOSVersion.v14, TVOSVersion.v26],
                testingLibrary: .none
            )
        )
    )
    func run_withMultiplePlatforms_configuresAllPlatformsCorrectly() async throws {
        // Given
        let arguments = [
            "Project",
            "--company-domain",
            "abc.com",
            "--root-module",
            "feature",
            "--testing-library",
            "none",
            "--macOS",
            "v15",
            "--tvOS",
            "v26"
        ]
        var sut = try Bootstrap.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let packageEdits = try #require(await context.packageEditorClientSpy.addedPlatforms)
        let projectConfigEdits = try #require(await context.xcodeProjClientSpy.projectConfigurations)
        let commands = try #require(await context.subprocessClientSpy.runCalls)

        #expect(packageEdits.count == 2)
        #expect(projectConfigEdits.count == 1)
        #expect(commands.count == 11)

        #expect(packageEdits[0].platform.identifier == "macOS")
        #expect(packageEdits[0].version == "v14")
        #expect(packageEdits[0].path.hasSuffix("Project/Modules/Package.swift"))

        #expect(packageEdits[1].platform.identifier == "tvOS")
        #expect(packageEdits[1].version == "v26")
        #expect(packageEdits[1].path.hasSuffix("Project/Modules/Package.swift"))

        #expect(projectConfigEdits[0].selectedPlatforms.count == 2)
        #expect(projectConfigEdits[0].selectedPlatforms[0].platform.identifier == "macOS")
        #expect(projectConfigEdits[0].selectedPlatforms[0].version == "v14")
        #expect(projectConfigEdits[0].selectedPlatforms[1].platform.identifier == "tvOS")
        #expect(projectConfigEdits[0].selectedPlatforms[1].version == "v26")
        #expect(projectConfigEdits[0].projectPath.hasSuffix("Project/App/Project.xcodeproj"))

        #expect(commands[3].command == .swift(.package(.setToolsVersion(version: "5.9"))))
    }

    // MARK: - Noora Prompts Configurations

    @Test("Bootstrap - noora client project name prompt - configuration", .bootstrapEnvironmentMock())
    func bootstrap_nooraClientProjectNamePrompt_configuration() async throws {
        // Given
        let arguments = [
            "--iOS",
            "v26",
            "--company-domain",
            "abc.com",
            "--root-module",
            "feature",
            "--testing-library",
            "none"
        ]
        var sut = try Bootstrap.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let textInputPrompts = try #require(await context.nooraClientSpy.textInputs)

        #expect(textInputPrompts.count == 3)

        let expectedQuestion = "How would you like to name your project?"
        let expectedErrorMessage = "Project name can not be empty."

        #expect(textInputPrompts[0].configuration.title.plain() == "Project name")
        #expect(textInputPrompts[0].configuration.question.plain() == expectedQuestion)
        #expect(textInputPrompts[0].configuration.validationRules[0].error.message == expectedErrorMessage)
        #expect(textInputPrompts[0].argument == nil)
    }

    @Test("Bootstrap - noora client platforms selection prompt - configuration", .bootstrapEnvironmentMock())
    func bootstrap_nooraClientPlatformsSelectionPrompt_configuration() async throws {
        // Given
        let arguments = [
            "MyTestProject",
            "--company-domain",
            "abc.com",
            "--root-module",
            "feature",
            "--testing-library",
            "none"
        ]
        var sut = try Bootstrap.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let platformSelections = try #require(await context.nooraClientSpy.platformsSelections)

        #expect(platformSelections.count == 1)

        let expectedQuestion = "Which platforms would you like to configure?"
        let expectedMinLimitError = "At least one platform must be selected."

        #expect(platformSelections[0].configuration.title.plain() == "Platform(s)")
        #expect(platformSelections[0].configuration.question.plain() == expectedQuestion)
        #expect(platformSelections[0].configuration.minLimitError == expectedMinLimitError)
        #expect(platformSelections[0].argument?.count == 0)
    }

    @Test("Bootstrap - noora client company domain prompt - configuration", .bootstrapEnvironmentMock())
    func bootstrap_nooraClientCompanyDomainPrompt_configuration() async throws {
        // Given
        let arguments = ["MyTestProject", "--iOS", "v26", "--root-module", "feature", "--testing-library", "none"]
        var sut = try Bootstrap.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let textInputPrompts = try #require(await context.nooraClientSpy.textInputs)

        #expect(textInputPrompts.count == 3)

        let expectedQuestion = "What domain or unique namespace should be used to construct the bundle identifier?"
        let expectedErrorMessage = "Company domain can not be empty."

        #expect(textInputPrompts[1].configuration.title.plain() == "Company domain")
        #expect(textInputPrompts[1].configuration.question.plain() == expectedQuestion)
        #expect(textInputPrompts[1].configuration.validationRules[0].error.message == expectedErrorMessage)
        #expect(textInputPrompts[1].argument == nil)
    }

    @Test("Bootstrap - noora client root module prompt - configuration", .bootstrapEnvironmentMock())
    func bootstrap_nooraClientRootModulePrompt_configuration() async throws {
        // Given
        let arguments = [
            "MyTestProject",
            "--iOS",
            "v26",
            "--company-domain",
            "example.com",
            "--testing-library",
            "none"
        ]
        var sut = try Bootstrap.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let textInputPrompts = try #require(await context.nooraClientSpy.textInputs)

        #expect(textInputPrompts.count == 3)

        let expectedQuestion = "How would you like to name the initial root module of the project?"
        let expectedErrorMessage = "Root module name can not be empty."

        #expect(textInputPrompts[2].configuration.title.plain() == "Root module")
        #expect(textInputPrompts[2].configuration.question.plain() == expectedQuestion)
        #expect(textInputPrompts[2].configuration.validationRules[0].error.message == expectedErrorMessage)
        #expect(textInputPrompts[2].argument == nil)
    }

    @Test("Bootstrap - noora client testing library prompt - configuration", .bootstrapEnvironmentMock())
    func bootstrap_nooraClientTestingLibraryPrompt_configuration() async throws {
        // Given
        let arguments = [
            "MyTestProject",
            "--iOS",
            "v26",
            "--company-domain",
            "example.com",
            "--root-module",
            "feature"
        ]
        var sut = try Bootstrap.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let testingLibrarySelection = try #require(await context.nooraClientSpy.testingLibrarySelections)

        #expect(testingLibrarySelection.count == 1)

        let expectedQuestion = "Which testing library would you like to use for the root module tests?"

        #expect(testingLibrarySelection[0].configuration.title.plain() == "Testing library")
        #expect(testingLibrarySelection[0].configuration.question.plain() == expectedQuestion)
        #expect(testingLibrarySelection[0].argument == nil)
    }

    // MARK: - Run - Error Handling

    @Test(
        "run() - when copy project templates fails - throws an error and removes incomplete project directory",
        .bootstrapEnvironmentMock(clientErrorStub: .resourcesClient)
    )
    func run_whenCopyProjectTemplatesFails_throwsErrorAndRemovesIncompleteProjectDirectory() async throws {
        // Given
        let projectName = "MyTestProject"
        let arguments = [
            projectName,
            "--iOS",
            "v26",
            "--company-domain",
            "abc.com",
            "--root-module",
            "feature",
            "--testing-library",
            "xctest"
        ]
        var sut = try Bootstrap.parse(arguments)

        await #expect(throws: Error.self) {
            // When
            try await sut.run()
        }

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let contextPath = context.workingDirectory
        let projectBasePath = Path(contextPath + "/\(projectName)")

        #expect(!projectBasePath.exists)
    }

    @Test(
        "run() - when configure workspace fails - throws an error and removes incomplete project directory",
        .bootstrapEnvironmentMock(clientErrorStub: .xcodeProjClient)
    )
    func run_whenConfigureWorkspaceFails_throwsErrorAndRemovesIncompleteProjectDirectory() async throws {
        // Given
        let projectName = "MyTestProject"
        let arguments = [
            projectName,
            "--iOS",
            "v26",
            "--company-domain",
            "abc.com",
            "--root-module",
            "feature",
            "--testing-library",
            "xctest"
        ]
        var sut = try Bootstrap.parse(arguments)

        await #expect(throws: Error.self) {
            // When
            try await sut.run()
        }

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let contextPath = context.workingDirectory
        let projectBasePath = Path(contextPath + "/\(projectName)")

        #expect(!projectBasePath.exists)
    }

    @Test(
        "run() - when project and current dirs are equal - configuration fails - does not remove current dir",
        .bootstrapEnvironmentMock(clientErrorStub: .resourcesClient)
    )
    func run_whenProjectAndCurrentDirsAreEqual_andConfigurationFails_doesNotRemoveCurrentDir() async throws {
        // Given
        let projectName = "MyTestProject"
        let arguments = [
            projectName,
            "--iOS",
            "v26",
            "--company-domain",
            "abc.com",
            "--root-module",
            "feature",
            "--testing-library",
            "xctest"
        ]
        var sut = try Bootstrap.parse(arguments)
        await #expect(throws: Error.self) {
            // When
            try await sut.run()
        }

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let contextPath = context.workingDirectory
        let currentDirPath = Path(contextPath)

        #expect(currentDirPath.exists)
    }

    @Test(
        "run() - when project and current dirs are not equal - configuration fails - removes project dir",
        .bootstrapEnvironmentMock(pathStub: .temporaryWithBase(named: "Developer"), clientErrorStub: .xcodeProjClient)
    )
    func run_whenProjectAndCurrentDirsAreNotEqual_andConfigurationFails_removesProjectDir() async throws {
        // Given
        let projectName = "MyTestProject"
        let arguments = [
            projectName,
            "--iOS",
            "v26",
            "--company-domain",
            "abc.com",
            "--root-module",
            "feature",
            "--testing-library",
            "xctest"
        ]
        var sut = try Bootstrap.parse(arguments)

        await #expect(throws: Error.self) {
            // When
            try await sut.run()
        }

        // Then
        let context = try #require(BootstrapExecutionContext.current)
        let contextPath = context.workingDirectory
        let projectBasePath = Path(contextPath + "/\(projectName)")

        #expect(!projectBasePath.exists)
    }
}

@Suite("Bootstrap.Error Tests", .tags(.unit))
struct BootstrapErrorTests {
    @Test("errorDescription - with validation error - returns expected message")
    func errorDescription_withValidationError_returnsExpectedMessage() {
        // Given
        let message = "This is a validation error."
        let error = Bootstrap.Error.validation(message: message)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Validation failed: " + message)
    }

    @Test("errorDescription - with configFileNotFound error - returns expected message")
    func errorDescription_withConfigFileNotFoundError_returnsExpectedMessage() {
        // Given
        let error = Bootstrap.Error.configFileNotFound

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Could not find 'spm-kit-config.yaml'. Ensure you are inside a valid project directory.")
    }
}
// swiftlint:enable function_body_length type_body_length
