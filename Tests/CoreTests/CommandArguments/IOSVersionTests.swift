//
//  IOSVersionTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-20.
//

import Core
import TestHelpers
import Testing

@Suite("IOSVersion Tests", .tags(.unit))
struct IOSVersionTests {
    @Test("toolsVersion - returns expected toolsVersion", arguments: IOSVersion.allCases)
    func toolsVersion_returnsExpectedToolsVersion(version: IOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v17:
                #expect(sut.toolsVersion == 5.9)
            case .v18:
                #expect(sut.toolsVersion == 6.0)
            case .v26:
                #expect(sut.toolsVersion == 6.2)
        }
    }

    @Test("versionIdentifier - returns expected versionIdentifier", arguments: IOSVersion.allCases)
    func versionIdentifier_returnsExpectedVersionIdentifier(version: IOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v17:
                #expect(sut.versionIdentifier == "v17")
            case .v18:
                #expect(sut.versionIdentifier == "v18")
            case .v26:
                #expect(sut.versionIdentifier == "v26")
        }
    }

    @Test("deploymentTargetSettingValue - returns expected value", arguments: IOSVersion.allCases)
    func deploymentTargetSettingValue_returnsCorrectValue(version: IOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v17:
                #expect(sut.deploymentTargetSettingValue == "17.0")
            case .v18:
                #expect(sut.deploymentTargetSettingValue == "18.0")
            case .v26:
                #expect(sut.deploymentTargetSettingValue == "26.0")
        }
    }

    @Test("platform - returns iOS platform", arguments: IOSVersion.allCases)
    func platform_returnsIOSPlatform(version: IOSVersion) {
        // Given, When
        let sut = version

        // Then
        #expect(sut.platform == .iOS)
    }

    @Test("CustomStringConvertible - description - returns expected description", arguments: IOSVersion.allCases)
    func customStringConvertible_description_returnsExpectedDescription(version: IOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v17:
                #expect(sut.description == "v17")
            case .v18:
                #expect(sut.description == "v18")
            case .v26:
                #expect(sut.description == "v26")
        }
    }

    @Test(
        "ExpressibleByArgument - defaultValueDescription - returns version description",
        arguments: IOSVersion.allCases
    )
    func expressibleByArgument_defaultValueDescription_returnsVersionDescription(version: IOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch version {
            case .v17:
                #expect(sut.defaultValueDescription == "v17")
            case .v18:
                #expect(sut.defaultValueDescription == "v18")
            case .v26:
                #expect(sut.defaultValueDescription == "v26")
        }
    }

    @Test("CaseIterable - returns all expected cases")
    func caseIterable_returnsAllExpectedCases() {
        // Given, When
        let sut = IOSVersion.allCases

        // Then
        #expect(sut.count == 3)
        #expect(sut.contains(.v17))
        #expect(sut.contains(.v18))
        #expect(sut.contains(.v26))
    }
}
