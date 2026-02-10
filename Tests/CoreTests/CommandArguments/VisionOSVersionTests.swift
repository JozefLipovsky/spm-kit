//
//  VisionOSVersionTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-20.
//

import Core
import TestHelpers
import Testing

@Suite("VisionOSVersion Tests", .tags(.unit))
struct VisionOSVersionTests {
    @Test("toolsVersion - returns expected toolsVersion", arguments: VisionOSVersion.allCases)
    func toolsVersion_returnsExpectedToolsVersion(version: VisionOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v1:
                #expect(sut.toolsVersion == 5.9)
            case .v2:
                #expect(sut.toolsVersion == 6.0)
            case .v26:
                #expect(sut.toolsVersion == 6.2)
        }
    }

    @Test("versionIdentifier - returns expected versionIdentifier", arguments: VisionOSVersion.allCases)
    func versionIdentifier_returnsExpectedVersionIdentifier(version: VisionOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v1:
                #expect(sut.versionIdentifier == "v1")
            case .v2:
                #expect(sut.versionIdentifier == "v2")
            case .v26:
                #expect(sut.versionIdentifier == "v26")
        }
    }

    @Test("deploymentTargetSettingValue - returns expected value", arguments: VisionOSVersion.allCases)
    func deploymentTargetSettingValue_returnsCorrectValue(version: VisionOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v1:
                #expect(sut.deploymentTargetSettingValue == "1.0")
            case .v2:
                #expect(sut.deploymentTargetSettingValue == "2.0")
            case .v26:
                #expect(sut.deploymentTargetSettingValue == "26.0")
        }
    }

    @Test("platform - returns visionOS platform", arguments: VisionOSVersion.allCases)
    func platform_returnsVisionOSPlatform(version: VisionOSVersion) {
        // Given, When
        let sut = version

        // Then
        #expect(sut.platform == .visionOS)
    }

    @Test("CustomStringConvertible - description - returns expected description", arguments: VisionOSVersion.allCases)
    func customStringConvertible_description_returnsExpectedDescription(version: VisionOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v1:
                #expect(sut.description == "v1")
            case .v2:
                #expect(sut.description == "v2")
            case .v26:
                #expect(sut.description == "v26")
        }
    }

    @Test(
        "ExpressibleByArgument - defaultValueDescription - returns version description",
        arguments: VisionOSVersion.allCases
    )
    func expressibleByArgument_defaultValueDescription_returnsVersionDescription(version: VisionOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch version {
            case .v1:
                #expect(sut.defaultValueDescription == "v1")
            case .v2:
                #expect(sut.defaultValueDescription == "v2")
            case .v26:
                #expect(sut.defaultValueDescription == "v26")
        }
    }

    @Test("CaseIterable - returns all expected cases")
    func caseIterable_returnsAllExpectedCases() {
        // Given, When
        let sut = VisionOSVersion.allCases

        // Then
        #expect(sut.count == 3)
        #expect(sut.contains(.v1))
        #expect(sut.contains(.v2))
        #expect(sut.contains(.v26))
    }
}
