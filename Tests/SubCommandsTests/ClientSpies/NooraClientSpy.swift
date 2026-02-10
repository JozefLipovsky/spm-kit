//
//  NooraClientSpy.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-12.
//

import Core
import Dependencies

actor NooraClientSpy {
    private(set) var textInputs: [TextInput]?
    private(set) var testingLibrarySelections: [TestingLibrarySelection]?
    private(set) var platformsSelections: [PlatformsSelection]?
    private(set) var productTypeSelections: [ProductTypeSelection]?
    private(set) var yesOrNoConfirmations: [YesOrNoConfirmation]?
    private(set) var targetDependenciesSelections: [TargetDependenciesSelection]?
    private(set) var productDependenciesSelections: [ProductDependenciesSelection]?
    private(set) var operationProgresses: [OperationProgress]?

    func recordTextInput(configuration: NooraPromptConfiguration, argument: String?) {
        let input = TextInput(configuration: configuration, argument: argument)
        if textInputs == nil {
            textInputs = [input]
        } else {
            textInputs?.append(input)
        }
    }

    func recordTestingLibrarySelection(configuration: NooraPromptConfiguration, testingLibrary: TestingLibrary?) {
        let selection = TestingLibrarySelection(configuration: configuration, argument: testingLibrary)
        if testingLibrarySelections == nil {
            testingLibrarySelections = [selection]
        } else {
            testingLibrarySelections?.append(selection)
        }
    }

    func recordPlatformsSelection(configuration: NooraPromptConfiguration, platforms: [any PlatformVersion]?) {
        let selection = PlatformsSelection(configuration: configuration, argument: platforms)
        if platformsSelections == nil {
            platformsSelections = [selection]
        } else {
            platformsSelections?.append(selection)
        }
    }

    func recordProductTypeSelection(configuration: NooraPromptConfiguration, productType: ProductType?) {
        let selection = ProductTypeSelection(configuration: configuration, argument: productType)
        if productTypeSelections == nil {
            productTypeSelections = [selection]
        } else {
            productTypeSelections?.append(selection)
        }
    }

    func recordYesOrNoConfirmation(configuration: NooraPromptConfiguration, shouldSkip: Bool) {
        let confirmation = YesOrNoConfirmation(configuration: configuration, shouldSkip: shouldSkip)
        if yesOrNoConfirmations == nil {
            yesOrNoConfirmations = [confirmation]
        } else {
            yesOrNoConfirmations?.append(confirmation)
        }
    }

    func recordTargetDependenciesSelection(configuration: NooraPromptConfiguration, options: [TargetDependency]) {
        let selection = TargetDependenciesSelection(configuration: configuration, options: options)
        if targetDependenciesSelections == nil {
            targetDependenciesSelections = [selection]
        } else {
            targetDependenciesSelections?.append(selection)
        }
    }

    func recordProductDependenciesSelection(configuration: NooraPromptConfiguration, options: [ProductDependency]) {
        let selection = ProductDependenciesSelection(configuration: configuration, options: options)
        if productDependenciesSelections == nil {
            productDependenciesSelections = [selection]
        } else {
            productDependenciesSelections?.append(selection)
        }
    }

    func recordOperationProgress(message: String) {
        let progress = OperationProgress(message: message)
        if operationProgresses == nil {
            operationProgresses = [progress]
        } else {
            operationProgresses?.append(progress)
        }
    }
}

extension NooraClientSpy {
    struct TextInput {
        let configuration: NooraPromptConfiguration
        let argument: String?
    }

    struct TestingLibrarySelection {
        let configuration: NooraPromptConfiguration
        let argument: TestingLibrary?
    }

    struct PlatformsSelection {
        let configuration: NooraPromptConfiguration
        let argument: [any PlatformVersion]?
    }

    struct ProductTypeSelection {
        let configuration: NooraPromptConfiguration
        let argument: ProductType?
    }

    struct YesOrNoConfirmation {
        let configuration: NooraPromptConfiguration
        let shouldSkip: Bool
    }

    struct TargetDependenciesSelection {
        let configuration: NooraPromptConfiguration
        let options: [TargetDependency]
    }

    struct ProductDependenciesSelection {
        let configuration: NooraPromptConfiguration
        let options: [ProductDependency]
    }

    struct OperationProgress {
        let message: String
    }
}
