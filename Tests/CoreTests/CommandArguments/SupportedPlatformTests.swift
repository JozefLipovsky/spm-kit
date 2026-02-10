//
//  SupportedPlatformTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-13.
//

import Core
import Noora
import TestHelpers
import Testing

@Suite("SupportedPlatform Tests", .tags(.unit))
struct SupportedPlatformTests {
    @Test("identifier - returns expected identifier", arguments: SupportedPlatform.allCases)
    func rawValue_returnsExpectedIdentifier(platform: SupportedPlatform) {
        // Given, When
        let sut = platform

        // Then
        switch sut {
            case .iOS:
                #expect(sut.identifier == "iOS")
            case .macOS:
                #expect(sut.identifier == "macOS")
            case .tvOS:
                #expect(sut.identifier == "tvOS")
            case .visionOS:
                #expect(sut.identifier == "visionOS")
            case .watchOS:
                #expect(sut.identifier == "watchOS")
        }
    }

    @Test("deploymentTargetSettingKey - returns correct key", arguments: SupportedPlatform.allCases)
    func deploymentTargetSettingKey_returnsCorrectKey(platform: SupportedPlatform) {
        // Given, When
        let sut = platform

        // Then
        switch sut {
            case .iOS:
                #expect(sut.deploymentTargetSettingKey == "IPHONEOS_DEPLOYMENT_TARGET")
            case .macOS:
                #expect(sut.deploymentTargetSettingKey == "MACOSX_DEPLOYMENT_TARGET")
            case .tvOS:
                #expect(sut.deploymentTargetSettingKey == "TVOS_DEPLOYMENT_TARGET")
            case .visionOS:
                #expect(sut.deploymentTargetSettingKey == "XROS_DEPLOYMENT_TARGET")
            case .watchOS:
                #expect(sut.deploymentTargetSettingKey == "WATCHOS_DEPLOYMENT_TARGET")
        }
    }

    @Test("description - returns expected description", arguments: SupportedPlatform.allCases)
    func description_returnsExpectedDescription(platform: SupportedPlatform) {
        // Given, When
        let sut = platform

        // Then
        switch sut {
            case .iOS:
                #expect(sut.description == "iOS")
            case .macOS:
                #expect(sut.description == "macOS")
            case .tvOS:
                #expect(sut.description == "tvOS")
            case .visionOS:
                #expect(sut.description == "visionOS")
            case .watchOS:
                #expect(sut.description == "watchOS")
        }
    }

    @Test("CaseIterable - returns all expected cases")
    func caseIterable_returnsAllExpectedCases() {
        // Given, When
        let sut = SupportedPlatform.allCases

        // Then
        #expect(sut.count == 5)
        #expect(sut.contains(.iOS))
        #expect(sut.contains(.macOS))
        #expect(sut.contains(.tvOS))
        #expect(sut.contains(.visionOS))
        #expect(sut.contains(.watchOS))
    }

    @Test("versionSelectionPromptTitle - returns expected title", arguments: SupportedPlatform.allCases)
    func versionSelectionPromptTitle_returnsExpectedTitle(platform: SupportedPlatform) {
        // Given, When
        let sut = platform

        // Then
        let promptTitle = sut.versionSelectionPromptTitle.plain()
        switch sut {
            case .iOS:
                #expect(promptTitle == "Minimum iOS deployment target")
            case .macOS:
                #expect(promptTitle == "Minimum macOS deployment target")
            case .tvOS:
                #expect(promptTitle == "Minimum tvOS deployment target")
            case .visionOS:
                #expect(promptTitle == "Minimum visionOS deployment target")
            case .watchOS:
                #expect(promptTitle == "Minimum watchOS deployment target")
        }
    }

    @Test("versionSelectionPromptQuestion - returns expected question", arguments: SupportedPlatform.allCases)
    func versionSelectionPromptQuestion_returnsExpectedQuestion(platform: SupportedPlatform) {
        // Given, When
        let sut = platform

        // Then
        let promptQuestion = sut.versionSelectionPromptQuestion.plain()
        switch sut {
            case .iOS:
                #expect(promptQuestion == "Which iOS version would you like to target?")
            case .macOS:
                #expect(promptQuestion == "Which macOS version would you like to target?")
            case .tvOS:
                #expect(promptQuestion == "Which tvOS version would you like to target?")
            case .visionOS:
                #expect(promptQuestion == "Which visionOS version would you like to target?")
            case .watchOS:
                #expect(promptQuestion == "Which watchOS version would you like to target?")
        }
    }
}
