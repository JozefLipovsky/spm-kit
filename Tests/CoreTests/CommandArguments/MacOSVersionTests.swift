//
//  MacOSVersionTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-20.
//

import Core
import TestHelpers
import Testing

@Suite("MacOSVersion Tests", .tags(.unit))
struct MacOSVersionTests {
    @Test("toolsVersion - returns expected toolsVersion", arguments: MacOSVersion.allCases)
    func toolsVersion_returnsExpectedToolsVersion(version: MacOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v14:
                #expect(sut.toolsVersion == 5.9)
            case .v15:
                #expect(sut.toolsVersion == 6.0)
            case .v26:
                #expect(sut.toolsVersion == 6.2)
        }
    }

    @Test("versionIdentifier - returns expected versionIdentifier", arguments: MacOSVersion.allCases)
    func versionIdentifier_returnsExpectedVersionIdentifier(version: MacOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v14:
                #expect(sut.versionIdentifier == "v14")
            case .v15:
                #expect(sut.versionIdentifier == "v15")
            case .v26:
                #expect(sut.versionIdentifier == "v26")
        }
    }

    @Test("deploymentTargetSettingValue - returns expected value", arguments: MacOSVersion.allCases)
    func deploymentTargetSettingValue_returnsCorrectValue(version: MacOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v14:
                #expect(sut.deploymentTargetSettingValue == "14.0")
            case .v15:
                #expect(sut.deploymentTargetSettingValue == "15.0")
            case .v26:
                #expect(sut.deploymentTargetSettingValue == "26.0")
        }
    }

    @Test("platform - returns macOS platform", arguments: MacOSVersion.allCases)
    func platform_returnsMacOSPlatform(version: MacOSVersion) {
        // Given, When
        let sut = version

        // Then
        #expect(sut.platform == .macOS)
    }

    @Test("CustomStringConvertible - description - returns expected description", arguments: MacOSVersion.allCases)
    func customStringConvertible_description_returnsExpectedDescription(version: MacOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v14:
                #expect(sut.description == "v14")
            case .v15:
                #expect(sut.description == "v15")
            case .v26:
                #expect(sut.description == "v26")
        }
    }

    @Test(
        "ExpressibleByArgument - defaultValueDescription - returns version description",
        arguments: MacOSVersion.allCases
    )
    func expressibleByArgument_defaultValueDescription_returnsVersionDescription(version: MacOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch version {
            case .v14:
                #expect(sut.defaultValueDescription == "v14")
            case .v15:
                #expect(sut.defaultValueDescription == "v15")
            case .v26:
                #expect(sut.defaultValueDescription == "v26")
        }
    }

    @Test("CaseIterable - returns all expected cases")
    func caseIterable_returnsAllExpectedCases() {
        // Given, When
        let sut = MacOSVersion.allCases

        // Then
        #expect(sut.count == 3)
        #expect(sut.contains(.v14))
        #expect(sut.contains(.v15))
        #expect(sut.contains(.v26))
    }
}
