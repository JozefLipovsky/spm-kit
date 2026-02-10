//
//  NooraClient.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-06.
//

import Dependencies
import DependenciesMacros
import Noora

/// A client for interacting with `Noora` library components.
@DependencyClient
package struct NooraClient: Sendable {
    /// Prompts the user for text input.
    /// If a value is provided for the `argument` parameter, it is returned immediately without prompting the user.
    /// - Parameters:
    ///   - configuration: The configuration for the prompt.
    ///   - argument: An optional pre-provided argument value.
    /// - Returns: The user's input or the pre-provided argument.
    package var textInput:
        @Sendable (
            _ configuration: NooraPromptConfiguration,
            _ argument: String?
        ) async -> String = { _, _ in "" }

    /// Prompts the user to select a testing library.
    /// If a value is provided for the `argument` parameter, it is returned immediately without prompting the user.
    /// - Parameters:
    ///   - configuration: The configuration for the prompt.
    ///   - argument: An optional pre-provided testing library.
    /// - Returns: The selected testing library or the pre-provided argument.
    package var testingLibrarySelection:
        @Sendable (
            _ configuration: NooraPromptConfiguration,
            _ argument: TestingLibrary?
        ) async -> TestingLibrary = { _, _ in .swiftTesting }

    /// Prompts the user to select platform(s) and their versions.
    /// If a value is provided for the `argument` parameter, it is returned immediately without prompting the user.
    /// - Parameters:
    ///   - configuration: The configuration for the prompt.
    ///   - argument: An optional array of pre-provided platform versions.
    /// - Returns: The selected platform versions or the pre-provided argument.
    package var platformsSelection:
        @Sendable (
            _ configuration: NooraPromptConfiguration,
            _ argument: [any PlatformVersion]?
        ) async -> [any PlatformVersion] = { _, _ in [] }

    /// Prompts the user to select a product type.
    /// If a value is provided for the `argument` parameter, it is returned immediately without prompting the user.
    /// - Parameters:
    ///   - configuration: The configuration for the prompt.
    ///   - argument: An optional pre-provided product type.
    /// - Returns: The selected product type or the pre-provided argument.
    package var productTypeSelection:
        @Sendable (
            _ configuration: NooraPromptConfiguration,
            _ argument: ProductType?
        ) async -> ProductType = { _, _ in .library }

    /// Executes an operation while presenting a progress spinner.
    /// - Parameters:
    ///   - message: The message to display with the spinner.
    ///   - operation: The asynchronous operation to execute.
    /// - Returns: The result of the operation.
    package var operationProgress:
        @Sendable (
            _ message: String,
            _ operation: @escaping @Sendable () async throws -> any Sendable
        ) async throws -> any Sendable = { _, _ in () }

    /// Prompts the user with a yes/no choice.
    /// If `shouldSkip` is `true`, it returns `false` immediately without prompting the user.
    /// - Parameters:
    ///   - configuration: The configuration for the prompt.
    ///   - shouldSkip: A boolean indicating whether the prompt should be skipped.
    /// - Returns: The user's choice or `false` if skipped.
    package var yesOrNoConfirmation:
        @Sendable (
            _ configuration: NooraPromptConfiguration,
            _ shouldSkip: Bool
        ) async -> Bool = { _, _ in false }

    /// Prompts the user to select target dependencies from a list of options.
    /// - Parameters:
    ///   - configuration: The configuration for the prompt.
    ///   - options: The list of available target dependencies.
    /// - Returns: The selected target dependencies.
    package var targetDependenciesSelection:
        @Sendable (
            _ configuration: NooraPromptConfiguration,
            _ options: [TargetDependency]
        ) async -> [TargetDependency] = { _, _ in [] }

    /// Prompts the user to select product dependencies from a list of options.
    /// - Parameters:
    ///   - configuration: The configuration for the prompt.
    ///   - options: The list of available product dependencies.
    /// - Returns: The selected product dependencies.
    package var productDependenciesSelection:
        @Sendable (
            _ configuration: NooraPromptConfiguration,
            _ options: [ProductDependency]
        ) async -> [ProductDependency] = { _, _ in [] }

    /// Posts an info message to inform the user about an issue.
    /// - Parameters:
    ///   - message: The message to display.
    package var info: @Sendable (_ message: String) async -> Void = { _ in }
}

extension NooraClient: DependencyKey {
    /// The live implementation of `NooraClient`.
    package static var liveValue: Self {
        Self(
            textInput: { configuration, argument in
                guard let argument, !argument.isEmpty else {
                    return textInputPrompt(configuration)
                }

                return argument
            },
            testingLibrarySelection: { configuration, argument in
                guard let argument else {
                    return testingLibraryPrompt(configuration)
                }

                return argument
            },
            platformsSelection: { configuration, argument in
                guard let argument, !argument.isEmpty else {
                    return selectedPlatformVersionsPrompt(configuration)
                }

                return argument
            },
            productTypeSelection: { configuration, argument in
                guard let argument else {
                    return productTypePrompt(configuration)
                }

                return argument
            },
            operationProgress: { message, operation in
                try await Noora().progressStep(message: message) { _ in
                    try await operation()
                }
            },
            yesOrNoConfirmation: { configuration, shouldSkip in
                guard shouldSkip else {
                    return yesOrNoChoicePrompt(configuration)
                }

                return false
            },
            targetDependenciesSelection: { configuration, options in
                targetDependenciesPrompt(configuration, options: options)
            },
            productDependenciesSelection: { configuration, options in
                productDependenciesPrompt(configuration, options: options)
            },
            info: { message in
                Noora().info(InfoAlert(stringLiteral: message))
            }
        )
    }
}

package extension DependencyValues {
    /// A client for interacting with `Noora` library components.
    var nooraClient: NooraClient {
        get { self[NooraClient.self] }
        set { self[NooraClient.self] = newValue }
    }
}

private extension NooraClient {
    static func textInputPrompt(_ configuration: NooraPromptConfiguration) -> String {
        Noora().textPrompt(
            title: configuration.title,
            prompt: configuration.question,
            description: configuration.description,
            validationRules: configuration.validationRules
        )
    }

    static func testingLibraryPrompt(_ configuration: NooraPromptConfiguration) -> TestingLibrary {
        let testingLibrary: TestingLibrary = Noora().singleChoicePrompt(
            title: configuration.title,
            question: configuration.question,
            description: configuration.description,
        )

        return testingLibrary
    }

    static func selectedPlatformVersionsPrompt(_ configuration: NooraPromptConfiguration) -> [any PlatformVersion] {
        let selectedPlaforms: [SupportedPlatform] = Noora().multipleChoicePrompt(
            title: configuration.title,
            question: configuration.question,
            description: configuration.description,
            minLimit: .limited(count: 1, errorMessage: configuration.minLimitError)
        )

        var selectedPlatformVersions: [any PlatformVersion] = []
        selectedPlaforms.forEach { platform in
            switch platform {
                case .iOS:
                    let iOSVersion: IOSVersion = Noora().singleChoicePrompt(
                        title: platform.versionSelectionPromptTitle,
                        question: platform.versionSelectionPromptQuestion
                    )

                    selectedPlatformVersions.append(iOSVersion)
                case .macOS:
                    let macOSVersion: MacOSVersion = Noora().singleChoicePrompt(
                        title: platform.versionSelectionPromptTitle,
                        question: platform.versionSelectionPromptQuestion
                    )

                    selectedPlatformVersions.append(macOSVersion)
                case .tvOS:
                    let tvOSVersion: TVOSVersion = Noora().singleChoicePrompt(
                        title: platform.versionSelectionPromptTitle,
                        question: platform.versionSelectionPromptQuestion
                    )

                    selectedPlatformVersions.append(tvOSVersion)
                case .visionOS:
                    let visionOSVersion: VisionOSVersion = Noora().singleChoicePrompt(
                        title: platform.versionSelectionPromptTitle,
                        question: platform.versionSelectionPromptQuestion
                    )

                    selectedPlatformVersions.append(visionOSVersion)
                case .watchOS:
                    let watchOSVersion: WatchOSVersion = Noora().singleChoicePrompt(
                        title: platform.versionSelectionPromptTitle,
                        question: platform.versionSelectionPromptQuestion
                    )

                    selectedPlatformVersions.append(watchOSVersion)
            }
        }

        return selectedPlatformVersions
    }

    static func productTypePrompt(_ configuration: NooraPromptConfiguration) -> ProductType {
        let productType: ProductType = Noora().singleChoicePrompt(
            title: configuration.title,
            question: configuration.question,
            description: configuration.description
        )

        return productType
    }

    static func yesOrNoChoicePrompt(_ configuration: NooraPromptConfiguration) -> Bool {
        Noora().yesOrNoChoicePrompt(
            title: configuration.title,
            question: configuration.question,
            defaultAnswer: true,
            description: configuration.description
        )
    }

    static func targetDependenciesPrompt(
        _ configuration: NooraPromptConfiguration,
        options: [TargetDependency]
    ) -> [TargetDependency] {
        Noora().multipleChoicePrompt(
            title: configuration.title,
            question: configuration.question,
            options: options,
            description: configuration.description
        )
    }

    static func productDependenciesPrompt(
        _ configuration: NooraPromptConfiguration,
        options: [ProductDependency]
    ) -> [ProductDependency] {
        Noora().multipleChoicePrompt(
            title: configuration.title,
            question: configuration.question,
            options: options,
            description: configuration.description
        )
    }
}
