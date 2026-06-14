//
//  AddTargetDependenciesTest.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-06-13.
//

import SubCommands
import TestHelpers
import Testing

@testable import Core

@Suite("AddTargetDependencies Tests", .tags(.unit))
struct AddTargetDependenciesTest {

    @Test(
        "run() - with default arguments - executes expected client calls",
        .addTargetDependenciesEnvironmentMock(nooraClientStubs: .init(dependencies: ["TargetA"]))
    )
    func run_withDefaultArguments_executesExpectedClientCalls() async throws {
        // Given
        let arguments = ["TargetB"]

        var sut = try AddTargetDependencies.parse(arguments)

        // When
        try await sut.run()

        // Then
        let context = try #require(AddTargetDependenciesExecutionContext.current)
        let subprocessRunCommands = try #require(await context.subprocessClientSpy.runCalls)
        let subprocessRunAndCaptureCommands = try #require(await context.subprocessClientSpy.runAndCaptureCalls)
        let dependenciesSelections = try #require(await context.nooraClientSpy.dependenciesSelections)
        let operationProgresses = try #require(await context.nooraClientSpy.operationProgresses)
        let modulesPathConfigPaths = try #require(await context.configClientSpy.modulesPathConfigPaths)
        let swiftFormatConfigPathConfigPaths = try #require(
            await context.configClientSpy.swiftFormatConfigPathConfigPaths
        )

        #expect(subprocessRunCommands.count == 2)
        #expect(subprocessRunAndCaptureCommands.count == 3)
        #expect(dependenciesSelections.count == 1)
        #expect(operationProgresses.count == 3)
        #expect(modulesPathConfigPaths.count == 1)
        #expect(swiftFormatConfigPathConfigPaths.count == 1)

        // Initialization
        #expect(modulesPathConfigPaths[0].hasSuffix("spm-kit-config.yaml"))
        #expect(swiftFormatConfigPathConfigPaths[0].hasSuffix("spm-kit-config.yaml"))

        // Package manifest dependencies parsing
        #expect(operationProgresses[0].message == "Parsing target dependencies")
        #expect(operationProgresses[0].successMessage == "Target dependencies parsed")
        #expect(subprocessRunAndCaptureCommands[0].command == .swift(.package(.dumpPackage)))

        #expect(operationProgresses[1].message == "Parsing product dependencies")
        #expect(operationProgresses[1].successMessage == "Product dependencies parsed")
        #expect(subprocessRunAndCaptureCommands[1].command == .swift(.package(.showDependencies(format: .json))))
        #expect(subprocessRunAndCaptureCommands[2].command == .swift(.package(.dumpPackage)))

        // Dependencies selection prompt
        let expectedQuestion = "Which dependencies would you like to add to the selected target?"
        let addTestDependencyCommand = ShellCommand.swift(
            .package(
                .addTargetDependency(
                    dependencyName: "TargetA",
                    targetName: "TargetB",
                    package: nil
                ),
                useCustomScratchPath: true
            )
        )
        #expect(dependenciesSelections[0].configuration.title == "Selected target dependencies")
        #expect(dependenciesSelections[0].configuration.question.plain() == expectedQuestion)
        #expect(subprocessRunCommands[0].command == addTestDependencyCommand)

        // Swift format
        let swiftFormatCommand = ShellCommand.swift(
            .format(.recursiveInPlace(configurationPath: "/fake/path/to/.swift-format-stub"))
        )
        #expect(subprocessRunCommands[1].command == swiftFormatCommand)
    }
}

@Suite("AddTargetDependencies.Error Tests", .tags(.unit))
struct AddTargetDependenciesErrorTests {

    @Test("errorDescription - with selected targetNotFound - returns expected message")
    func errorDescription_withSelectedTargetNotFound_returnsExpectedMessage() {
        // Given
        let targetName = "NonExistentTarget"
        let error = AddTargetDependencies.Error.targetNotFound(name: targetName)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Could not find a target named '\(targetName)'.")
    }


    @Test("errorDescription - with targetsNotFound - returns expected message")
    func errorDescription_withTargetsNotFound_returnsExpectedMessage() {
        // Given
        let error = AddTargetDependencies.Error.targetsNotFound

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Could not find any targets in the project.")
    }
}
