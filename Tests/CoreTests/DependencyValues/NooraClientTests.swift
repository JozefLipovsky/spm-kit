//
//  NooraClientTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-07.
//

import Core
import Dependencies
import Noora
import TestHelpers
import Testing

@Suite("NooraClient Tests", .tags(.unit))
struct NooraClientTests {
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

    @Test("operationProgress - executes operation")
    func operationProgress_executesOperation() async throws {
        try await withDependencies {
            $0.nooraClient = .liveValue
        } operation: {
            // Given
            @Dependency(\.nooraClient) var sut

            // When
            let output = try await sut.operationProgress(message: "Message") { "OperationStub" }

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
}
