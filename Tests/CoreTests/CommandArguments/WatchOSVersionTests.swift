//
//  WatchOSVersionTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-20.
//

import Core
import TestHelpers
import Testing

@Suite("WatchOSVersion Tests", .tags(.unit))
struct WatchOSVersionTests {
    @Test("toolsVersion - returns expected toolsVersion", arguments: WatchOSVersion.allCases)
    func toolsVersion_returnsExpectedToolsVersion(version: WatchOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v10:
                #expect(sut.toolsVersion == 5.9)
            case .v11:
                #expect(sut.toolsVersion == 6.0)
            case .v26:
                #expect(sut.toolsVersion == 6.2)
        }
    }

    @Test("versionIdentifier - returns expected versionIdentifier", arguments: WatchOSVersion.allCases)
    func versionIdentifier_returnsExpectedVersionIdentifier(version: WatchOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v10:
                #expect(sut.versionIdentifier == "v10")
            case .v11:
                #expect(sut.versionIdentifier == "v11")
            case .v26:
                #expect(sut.versionIdentifier == "v26")
        }
    }

    @Test("deploymentTargetSettingValue - returns expected value", arguments: WatchOSVersion.allCases)
    func deploymentTargetSettingValue_returnsCorrectValue(version: WatchOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v10:
                #expect(sut.deploymentTargetSettingValue == "10.0")
            case .v11:
                #expect(sut.deploymentTargetSettingValue == "11.0")
            case .v26:
                #expect(sut.deploymentTargetSettingValue == "26.0")
        }
    }

    @Test("platform - returns watchOS platform", arguments: WatchOSVersion.allCases)
    func platform_returnsWatchOSPlatform(version: WatchOSVersion) {
        // Given, When
        let sut = version

        // Then
        #expect(sut.platform == .watchOS)
    }

    @Test("CustomStringConvertible - description - returns expected description", arguments: WatchOSVersion.allCases)
    func customStringConvertible_description_returnsExpectedDescription(version: WatchOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch sut {
            case .v10:
                #expect(sut.description == "v10")
            case .v11:
                #expect(sut.description == "v11")
            case .v26:
                #expect(sut.description == "v26")
        }
    }

    @Test(
        "ExpressibleByArgument - defaultValueDescription - returns version description",
        arguments: WatchOSVersion.allCases
    )
    func expressibleByArgument_defaultValueDescription_returnsVersionDescription(version: WatchOSVersion) {
        // Given, When
        let sut = version

        // Then
        switch version {
            case .v10:
                #expect(sut.defaultValueDescription == "v10")
            case .v11:
                #expect(sut.defaultValueDescription == "v11")
            case .v26:
                #expect(sut.defaultValueDescription == "v26")
        }
    }

    @Test("CaseIterable - returns all expected cases")
    func caseIterable_returnsAllExpectedCases() {
        // Given, When
        let sut = WatchOSVersion.allCases

        // Then
        #expect(sut.count == 3)
        #expect(sut.contains(.v10))
        #expect(sut.contains(.v11))
        #expect(sut.contains(.v26))
    }
}
