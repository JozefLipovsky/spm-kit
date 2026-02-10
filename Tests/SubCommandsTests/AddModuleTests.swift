//
//  AddModuleTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-21.
//

import ArgumentParser
import PathKit
import SubCommands
import TestHelpers
import Testing

@testable import Core

// swiftlint:disable function_body_length type_body_length
@Suite("AddModule Tests", .tags(.unit))
struct AddModuleTests {

    @Test("run() - with default arguments - executes all client calls", .addModuleEnvironmentMock())
    func run_withDefaultArguments_executesAllClientCalls() async throws {
        // Given
        let arguments = [
            "ModuleStub",
            "--product-type", "library",
            "--testing-library", "swift-testing",
            "--skip-dependencies"
        ]
        var sut = try AddModule.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(AddModuleExecutionContext.current)
        let subprocessRunCommands = try #require(await context.subprocessClientSpy.runCalls)
        let subprocessRunAndCaptureCommands = await context.subprocessClientSpy.runAndCaptureCalls
        let moduleNamePrompts = try #require(await context.nooraClientSpy.textInputs)
        let productTypeSelections = try #require(await context.nooraClientSpy.productTypeSelections)
        let testingLibrarySelections = try #require(await context.nooraClientSpy.testingLibrarySelections)
        let yesOrNoConfirmations = try #require(await context.nooraClientSpy.yesOrNoConfirmations)
        let targetDependenciesSelections = await context.nooraClientSpy.targetDependenciesSelections
        let productDependenciesSelections = await context.nooraClientSpy.productDependenciesSelections
        let modulesPathConfigPaths = try #require(await context.configClientSpy.modulesPathConfigPaths)
        let swiftFormatConfigPathConfigPaths = try #require(
            await context.configClientSpy.swiftFormatConfigPathConfigPaths
        )

        #expect(subprocessRunCommands.count == 5)
        #expect(subprocessRunAndCaptureCommands == nil)
        #expect(moduleNamePrompts.count == 1)
        #expect(productTypeSelections.count == 1)
        #expect(testingLibrarySelections.count == 1)
        #expect(yesOrNoConfirmations.count == 1)
        #expect(targetDependenciesSelections == nil)
        #expect(productDependenciesSelections == nil)
        #expect(modulesPathConfigPaths.count == 1)
        #expect(swiftFormatConfigPathConfigPaths.count == 1)

        // Initialization
        #expect(modulesPathConfigPaths[0].hasSuffix("spm-kit-config.yaml"))
        #expect(swiftFormatConfigPathConfigPaths[0].hasSuffix("spm-kit-config.yaml"))

        // Prompts
        #expect(moduleNamePrompts[0].argument == "ModuleStub")
        #expect(productTypeSelections[0].argument == .library)
        #expect(testingLibrarySelections[0].argument == .swiftTesting)
        #expect(yesOrNoConfirmations[0].shouldSkip == true)

        // addTarget
        let addTargetCommand = ShellCommand.swift(
            .package(.addTarget(name: "ModuleStub", type: .library), useCustomScratchPath: true)
        )
        let addTestTargetCommand = ShellCommand.swift(
            .package(
                .addTarget(
                    name: "ModuleStubTests",
                    type: .test,
                    testingLibrary: .swiftTesting
                ),
                useCustomScratchPath: true
            )
        )
        let addTestDependencyCommand = ShellCommand.swift(
            .package(
                .addTargetDependency(
                    dependencyName: "ModuleStub",
                    targetName: "ModuleStubTests",
                    package: nil
                ),
                useCustomScratchPath: true
            )
        )
        #expect(subprocessRunCommands[0].command == addTargetCommand)
        #expect(subprocessRunCommands[1].command == addTestTargetCommand)
        #expect(subprocessRunCommands[2].command == addTestDependencyCommand)

        // addProduct
        let addProductCommand = ShellCommand.swift(
            .package(
                .addProduct(name: "ModuleStub", type: .library, targets: ["ModuleStub"]),
                useCustomScratchPath: true
            )
        )
        #expect(subprocessRunCommands[3].command == addProductCommand)

        // runSwiftFormat
        let formatCommand = ShellCommand.swift(
            .format(.recursiveInPlace(configurationPath: "/fake/path/to/.swift-format-stub"))
        )
        #expect(subprocessRunCommands[4].command == formatCommand)
    }

    @Test(
        "run() - when dependencies selected - fetches dependencies via subprocess",
        .addModuleEnvironmentMock(
            nooraClientStubs: .init(moduleName: "MyModule", testingLibrary: .none, selectDependencies: true)
        )
    )
    func run_whenDependenciesSelected_fetchesDependenciesViaSubprocess() async throws {
        // Given
        let arguments = [
            "MyModule",
            "--product-type", "library",
            "--testing-library", "none"
        ]
        var sut = try AddModule.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(AddModuleExecutionContext.current)
        let subprocessRunCommands = try #require(await context.subprocessClientSpy.runCalls)
        let subprocessRunAndCaptureCommands = try #require(await context.subprocessClientSpy.runAndCaptureCalls)
        let targetDependenciesSelections = try #require(await context.nooraClientSpy.targetDependenciesSelections)
        let productDependenciesSelections = try #require(await context.nooraClientSpy.productDependenciesSelections)
        let operationProgresses = try #require(await context.nooraClientSpy.operationProgresses)

        #expect(subprocessRunCommands.count == 3)
        #expect(subprocessRunAndCaptureCommands.count == 3)
        #expect(targetDependenciesSelections.count == 1)
        #expect(productDependenciesSelections.count == 1)
        #expect(operationProgresses.count == 2)

        // Target Dependencies

        let expectedAddTargetCommand = ShellCommand.swift(
            .package(.addTarget(name: "MyModule", type: .library), useCustomScratchPath: true)
        )

        #expect(subprocessRunAndCaptureCommands[0].command == .swift(.package(.dumpPackage)))
        #expect(subprocessRunAndCaptureCommands[0].workingDirectory == "/fake/path/to/ModulesStub")
        #expect(operationProgresses[0].message == "Fetching target dependencies")
        #expect(targetDependenciesSelections[0].configuration.title.plain() == "Target dependencies")
        #expect(subprocessRunCommands[0].command == expectedAddTargetCommand)

        // External Dependencies

        let expectedAddProductCommand = ShellCommand.swift(
            .package(
                .addProduct(name: "MyModule", type: .library, targets: ["MyModule"]),
                useCustomScratchPath: true
            )
        )

        #expect(subprocessRunAndCaptureCommands[1].command == .swift(.package(.showDependencies(format: .json))))
        #expect(subprocessRunAndCaptureCommands[2].workingDirectory == "/path/to/DependencyA")
        #expect(operationProgresses[1].message == "Fetching external dependencies")
        #expect(productDependenciesSelections[0].configuration.title.plain() == "External dependencies")
        #expect(subprocessRunAndCaptureCommands[2].command == .swift(.package(.dumpPackage)))
        #expect(subprocessRunCommands[1].command == expectedAddProductCommand)
    }

    // MARK: - Noora Prompts Configurations

    @Test("AddModule - noora module name prompt - configuration", .addModuleEnvironmentMock())
    func addModule_nooraModuleNamePrompt_configuration() async throws {
        // Given
        let arguments = [
            "--product-type", "library",
            "--testing-library", "swift-testing",
            "--skip-dependencies"
        ]
        var sut = try AddModule.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(AddModuleExecutionContext.current)
        let moduleNamePrompts = try #require(await context.nooraClientSpy.textInputs)

        #expect(moduleNamePrompts.count == 1)

        let expectedQuestion = "How would you like to name the new module?"
        let expectedErrorMessage = "Module name can not be empty."

        #expect(moduleNamePrompts[0].configuration.title.plain() == "Module name")
        #expect(moduleNamePrompts[0].configuration.question.plain() == expectedQuestion)
        #expect(moduleNamePrompts[0].configuration.validationRules[0].error.message == expectedErrorMessage)
        #expect(moduleNamePrompts[0].argument == nil)
    }

    @Test("AddModule - noora product type prompt - configuration", .addModuleEnvironmentMock())
    func addModule_nooraProductTypePrompt_configuration() async throws {
        // Given
        let arguments = [
            "MyModule",
            "--testing-library", "swift-testing",
            "--skip-dependencies"
        ]
        var sut = try AddModule.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(AddModuleExecutionContext.current)
        let productTypeSelections = try #require(await context.nooraClientSpy.productTypeSelections)

        #expect(productTypeSelections.count == 1)

        let expectedQuestion = "Which product type would you like to use for the new module?"

        #expect(productTypeSelections[0].configuration.title.plain() == "Product type")
        #expect(productTypeSelections[0].configuration.question.plain() == expectedQuestion)
        #expect(productTypeSelections[0].argument == nil)
    }

    @Test("AddModule - noora testing library prompt - configuration", .addModuleEnvironmentMock())
    func addModule_nooraTestingLibraryPrompt_configuration() async throws {
        // Given
        let arguments = [
            "MyModule",
            "--product-type", "library",
            "--skip-dependencies"
        ]
        var sut = try AddModule.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(AddModuleExecutionContext.current)
        let testingLibrarySelections = try #require(await context.nooraClientSpy.testingLibrarySelections)

        #expect(testingLibrarySelections.count == 1)

        let expectedQuestion = "Which testing library would you like to use for the new module tests?"

        #expect(testingLibrarySelections[0].configuration.title.plain() == "Testing library")
        #expect(testingLibrarySelections[0].configuration.question.plain() == expectedQuestion)
        #expect(testingLibrarySelections[0].argument == nil)
    }

    @Test("AddModule - noora dependencies selection prompt - configuration", .addModuleEnvironmentMock())
    func addModule_nooraDependenciesSelectionPrompt_configuration() async throws {
        // Given
        let arguments = [
            "MyModule",
            "--product-type", "library",
            "--testing-library", "none"
        ]
        var sut = try AddModule.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(AddModuleExecutionContext.current)
        let yesOrNoConfirmations = try #require(await context.nooraClientSpy.yesOrNoConfirmations)

        #expect(yesOrNoConfirmations.count == 1)

        let expectedQuestion = "Would you like to select dependencies for the new module?"

        #expect(yesOrNoConfirmations[0].configuration.title.plain() == "Dependencies selection")
        #expect(yesOrNoConfirmations[0].configuration.question.plain() == expectedQuestion)
        #expect(yesOrNoConfirmations[0].shouldSkip == false)
    }

    @Test(
        "AddModule - noora dependency prompts - configuration",
        .addModuleEnvironmentMock(nooraClientStubs: .init(selectDependencies: true))
    )
    func addModule_nooraDependencyPrompts_configuration() async throws {
        // Given
        let arguments = [
            "MyModule",
            "--product-type", "library",
            "--testing-library", "none"
        ]
        var sut = try AddModule.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(AddModuleExecutionContext.current)
        let targetDependenciesSelections = try #require(await context.nooraClientSpy.targetDependenciesSelections)
        let productDependenciesSelections = try #require(await context.nooraClientSpy.productDependenciesSelections)
        let operationProgresses = try #require(await context.nooraClientSpy.operationProgresses)

        #expect(operationProgresses.count == 2)
        #expect(targetDependenciesSelections.count == 1)
        #expect(productDependenciesSelections.count == 1)

        // Target Dependencies Prompt
        let expectedTargets = [
            TargetDependency(target: .init(name: "TargetA", type: .regular)),
            TargetDependency(target: .init(name: "TargetB", type: .regular))
        ]
        let expectedTargetQuestion = "Which target dependencies would you like to include?"

        #expect(operationProgresses[0].message == "Fetching target dependencies")
        #expect(targetDependenciesSelections[0].configuration.title.plain() == "Target dependencies")
        #expect(targetDependenciesSelections[0].configuration.question.plain() == expectedTargetQuestion)
        #expect(targetDependenciesSelections[0].options == expectedTargets)

        // Product Dependencies Prompt
        let expectedProducts = [
            ProductDependency(product: .init(name: "ProductA", type: .library), packageName: "StubPackage"),
            ProductDependency(product: .init(name: "ProductB", type: .library), packageName: "StubPackage")
        ]
        let expectedProductQuestion = "Which external dependencies would you like to include?"

        #expect(operationProgresses[1].message == "Fetching external dependencies")
        #expect(productDependenciesSelections[0].configuration.title.plain() == "External dependencies")
        #expect(productDependenciesSelections[0].configuration.question.plain() == expectedProductQuestion)
        #expect(productDependenciesSelections[0].options == expectedProducts)
    }

    // MARK: - Run - Error Handling

    @Test(
        "run() - when config file not found - throws config file not found error",
        .addModuleEnvironmentMock(configClientStubs: .init(generateConfig: false))
    )
    func run_whenConfigFileNotFound_throwsConfigFileNotFoundError() async throws {
        // Given
        let arguments = ["MyModule", "--product-type", "library", "--skip-dependencies"]
        var sut = try AddModule.parse(arguments)

        // When
        let error = await #expect(throws: AddModule.Error.self) {
            try await sut.run()
        }

        // Then
        #expect(error == .configFileNotFound)
    }

    @Test(
        "run() - when unsupported product type selected - throws unsupported product type error",
        .addModuleEnvironmentMock(nooraClientStubs: .init(productType: .plugin))
    )
    func run_whenUnsupportedProductTypeSelected_throwsUnsupportedProductTypeError() async throws {
        // Given
        let arguments = ["MyModule", "--skip-dependencies", "--testing-library", "none"]
        var sut = try AddModule.parse(arguments)

        // When
        let error = await #expect(throws: AddModule.Error.self) {
            try await sut.run()
        }

        // Then
        #expect(error == .unsupportedProductType(.plugin))
    }
}

@Suite("AddModule.Error Tests", .tags(.unit))
struct AddModuleErrorTests {
    @Test("errorDescription - with configFileNotFound - returns expected message")
    func errorDescription_withConfigFileNotFound_returnsExpectedMessage() {
        // Given
        let error = AddModule.Error.configFileNotFound

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Could not find 'spm-kit-config.yaml'. Ensure you are inside a valid project directory.")
    }

    @Test("errorDescription - with unsupportedProductType - returns expected message")
    func errorDescription_withUnsupportedProductType_returnsExpectedMessage() {
        // Given
        let productType: ProductType = .plugin
        let error = AddModule.Error.unsupportedProductType(productType)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Unsupported product type selected: \(productType.rawValue).")
    }
}
// swiftlint:enable function_body_length type_body_length
