//
//  NooraPromptConfiguration.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-06.
//

import Noora

/// Configuration for a Noora prompt.
package struct NooraPromptConfiguration: Equatable {
    private let promptTitle: String
    private let promptQuestion: String
    private let promptDescription: String?
    private let promptValidationError: String?
    private let promptMinLimitError: String?

    /// Creates a new prompt configuration
    /// - Parameters:
    ///   - title: The prompt name, typically a command argument.
    ///   - question: The instructional text shown to the user describing what to enter.
    ///   - description: An optional description to clarify what the prompt is for.
    ///   - validationError: An optional error message shown when an input validation fails.
    ///   - minLimitError: An optional error message shown when a multi choice prompt selection validation fails.
    package init(
        title: String,
        question: String,
        description: String? = nil,
        validationError: String? = nil,
        minLimitError: String? = nil
    ) {
        self.promptTitle = title
        self.promptQuestion = question
        self.promptDescription = description
        self.promptValidationError = validationError
        self.promptMinLimitError = minLimitError
    }
}

package extension NooraPromptConfiguration {
    /// Formatted prompt name, typically a command argument.
    var title: TerminalText {
        TerminalText(stringLiteral: promptTitle)
    }

    /// Formatted instruction text describing what to enter.
    var question: TerminalText {
        TerminalText(stringLiteral: promptQuestion)
    }

    /// An optional formatted description to clarify what the prompt is for.
    var description: TerminalText? {
        guard let promptDescription else { return nil }
        return TerminalText(stringLiteral: promptDescription)
    }

    /// An optional formatted message shown when an input validation fails.
    var validationRules: [ValidatableRule] {
        guard let promptValidationError else { return [] }
        return [NonEmptyValidationRule(error: promptValidationError)]
    }

    /// Error message shown when a multi choice prompt selection validation fails.
    var minLimitError: String {
        promptMinLimitError ?? ""
    }
}
