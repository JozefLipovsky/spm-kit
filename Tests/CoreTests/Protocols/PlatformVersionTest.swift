//
//  PlatformVersionTest.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-13.
//

import Core
import TestHelpers
import Testing

@Suite("PlatformVersion protocol default implementation tests", .tags(.unit))
struct PlatformVersionTest {
    @Test("toolsVersionIdentifier - returns formatted tools version")
    func toolsVersionIdentifier_returnsFormattedToolsVersion() {
        // Given
        let platformVersion = Mock.testPlatformVersion

        // When
        let sut = platformVersion.toolsVersionIdentifier

        // Then
        #expect(sut == "6.0")
    }
}

private extension PlatformVersionTest {
    enum Mock: String, PlatformVersion {
        case testPlatformVersion

        var toolsVersion: Double {
            6.01
        }

        var versionIdentifier: String {
            rawValue
        }

        var deploymentTargetSettingValue: String {
            "mockDeploymentTargetSettingValue"
        }

        var platform: SupportedPlatform {
            .iOS
        }

        var description: String {
            rawValue
        }
    }
}
