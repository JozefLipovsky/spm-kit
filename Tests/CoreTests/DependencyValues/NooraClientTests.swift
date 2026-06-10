//
//  NooraClientTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-07.
//

import Foundation
import Core
import Dependencies
import Noora
import TestHelpers
import Testing

@Suite("NooraClient Tests", .tags(.unit, .integration))
struct NooraClientTests {

    // MARK: Unit

    @Test("textInput - when argument is not nil - returns argument without prompting")
    func textInput_whenArgumentIsNotNil_returnsArgumentWithoutPrompting() async {
        await withDependencies {
            $0.nooraClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.nooraClient) var sut

            // When
            let configStub = NooraPromptConfiguration(title: "Title", question: "Question")
            let output = await sut.textInput(configuration: configStub, argument: "ProjectNameStub")

            // Then
            #expect(output == "ProjectNameStub")
        }
    }

    @Test("testingLibrarySelection - when argument is not nil - returns argument without prompting")
    func testingLibrarySelection_whenArgumentIsNotNil_returnsArgumentWithoutPrompting() async {
        await withDependencies {
            $0.nooraClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.nooraClient) var sut

            // When
            let configStub = NooraPromptConfiguration(title: "Title", question: "Question")
            let output = await sut.testingLibrarySelection(configuration: configStub, argument: .xctest)

            // Then
            #expect(output == .xctest)
        }
    }

    @Test("platformsSelection - when argument is not nil and not empty - returns argument without prompting")
    func platformsSelection_whenArgumentIsNotNilAndNotEmpty_returnsArgumentWithoutPrompting() async {
        await withDependencies {
            $0.nooraClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.nooraClient) var sut

            // When
            let configStub = NooraPromptConfiguration(title: "Title", question: "Question")
            let output = await sut.platformsSelection(configuration: configStub, argument: [IOSVersion.v17])

            // Then
            #expect(output.count == 1)
            #expect(output[0].platform == .iOS)
            #expect(output[0].versionIdentifier == "v17")
        }
    }

    @Test("productTypeSelection - when argument is not nil - returns argument without prompting")
    func productTypeSelection_whenArgumentIsNotNil_returnsArgumentWithoutPrompting() async {
        await withDependencies {
            $0.nooraClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.nooraClient) var sut

            // When
            let configStub = NooraPromptConfiguration(title: "Title", question: "Question")
            let output = await sut.productTypeSelection(configuration: configStub, argument: .executable)

            // Then
            #expect(output == .executable)
        }
    }

    @Test("progress - executes operation")
    func progress_executesOperation() async throws {
        try await withDependencies {
            $0.nooraClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.nooraClient) var sut

            // When
            let output = try await sut.progress(
                message: "Message",
                successMessage: "Success",
                errorMessage: "Error"
            ) { _ in "OperationStub" }

            // Then
            #expect(output as? String == "OperationStub")
        }
    }

    @Test("yesOrNoConfirmation - when shouldSkip is true - returns false without prompting")
    func yesOrNoConfirmation_whenShouldSkipIsTrue_returnsTrueWithoutPrompting() async {
        await withDependencies {
            $0.nooraClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.nooraClient) var sut

            // When
            let configStub = NooraPromptConfiguration(title: "Title", question: "Question")
            let output = await sut.yesOrNoConfirmation(configuration: configStub, shouldSkip: true)

            // Then
            #expect(output == false)
        }
    }

    // MARK: Integration

    @Test("dependenciesSelection - returns selected dependencies from options")
    func dependenciesSelection_returnsSelectedDependenciesFromOptions() async throws {
        try await withDependencies {
            $0.nooraClient = .liveValue
            $0.nooraClient.dependenciesSelection = { _, options in [options[1], options[3]] }
        } operation: {
            // Given
            @Dependency(\.nooraClient) var sut
            let configStub = NooraPromptConfiguration(title: "Title", question: "Question")
            let optionsStub: [PackageDependency] = [
                try .targetStub(name: "TargetA"),
                try .targetStub(name: "TargetB"),
                try .targetStub(name: "TargetC"),
                try .targetStub(name: "TargetD"),
                try .targetStub(name: "TargetE")
            ]

            // When
            let output = await sut.dependenciesSelection(configuration: configStub, options: optionsStub)

            // Then
            #expect(output.count == 2)
            #expect(output[0].name == "TargetB")
            #expect(output[1].name == "TargetD")
        }
    }

    @Test("targetSelection - returns selected target from options")
    func targetSelection_returnsSelectedTargetFromOptions() async throws {
        try await withDependencies {
            $0.nooraClient = .liveValue
            $0.nooraClient.targetSelection = { _, options in options[1] }
        } operation: {
            // Given
            @Dependency(\.nooraClient) var sut
            let configStub = NooraPromptConfiguration(title: "Title", question: "Question")
            let optionsStub: [PackageDependency] = [
                try .targetStub(name: "TargetA"),
                try .targetStub(name: "TargetB"),
                try .targetStub(name: "TargetC"),
            ]

            // When
            let output = await sut.targetSelection(configuration: configStub, options: optionsStub)

            // Then
            #expect(output.name == "TargetB")
        }
    }
}
