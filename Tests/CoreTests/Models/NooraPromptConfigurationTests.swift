//
//  NooraPromptConfigurationTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-08.
//

import Core
import Noora
import TestHelpers
import Testing

@Suite("TextInputPrompt Tests", .tags(.unit))
struct NooraPromptConfigurationTests {
    @Test("title - returns formatted title TerminalText")
    func title_returnsFormattedTitleTerminalText() {
        // Given, When
        let sut = NooraPromptConfiguration(title: "Title Stub", question: "Prompt Stub")

        // Then
        #expect(sut.title == TerminalText(stringLiteral: "Title Stub"))
    }

    @Test("question - returns formatted question TerminalText")
    func question_returnsFormattedQuestionTerminalText() {
        // Given, When
        let sut = NooraPromptConfiguration(title: "Title Stub", question: "Question Stub")

        // Then
        #expect(sut.question == TerminalText(stringLiteral: "Question Stub"))
    }

    @Test("description - with description - returns formatted description TerminalText")
    func description_withDescription_returnsFormattedDescriptionTerminalText() {
        // Given, When
        let sut = NooraPromptConfiguration(
            title: "Title Stub",
            question: "Question Stub",
            description: "Description Stub"
        )

        // Then
        #expect(sut.description == TerminalText(stringLiteral: "Description Stub"))
    }

    @Test("description - without description - returns nil description")
    func description_withoutDescription_returnsNil() {
        // Given, When
        let sut = NooraPromptConfiguration(title: "Title Stub", question: "Prompt Stub", validationError: "Error Stub")

        // Then
        #expect(sut.description == nil)
    }

    @Test("validationRules - with validation error - returns ValidatableRules with error description")
    func validationRule_withValidationError_returnsValidationRuleWithErrorDescription() {
        // Given, When
        let sut = NooraPromptConfiguration(
            title: "Title Stub",
            question: "Question Stub",
            validationError: "Error Stub"
        )

        // Then
        #expect(sut.validationRules.count == 1)
        #expect(sut.validationRules[0].error.message == "Error Stub")
    }

    @Test("validationRules - without validation error - returns empty ValidatableRules")
    func validationRule_withoutValidationError_returnsNil() {
        // Given, When
        let sut = NooraPromptConfiguration(title: "Title Stub", question: "Question Stub")

        // Then
        #expect(sut.validationRules.isEmpty)
    }

    @Test("minLimitError - with minLimitError provided - returns the provided error message")
    func minLimitError_withMinLimitErrorProvided_returnsProvidedErrorMessage() {
        // Given, When
        let sut = NooraPromptConfiguration(
            title: "Title Stub",
            question: "Question Stub",
            minLimitError: "Min Limit Error Stub"
        )

        // Then
        #expect(sut.minLimitError == "Min Limit Error Stub")
    }

    @Test("minLimitError - without minLimitError provided - returns empty string as default")
    func minLimitError_withoutMinLimitErrorProvided_returnsEmptyStringAsDefault() {
        // Given, When
        let sut = NooraPromptConfiguration(title: "Title Stub", question: "Question Stub")

        // Then
        #expect(sut.minLimitError == "")
    }
}
