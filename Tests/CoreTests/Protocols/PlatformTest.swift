//
//  PlatformTest.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-13.
//

import Core
import TestHelpers
import Testing

@Suite("Platform protocol default implementation tests", .tags(.unit))
struct PlatformTest {
    @Test("displayNameSettingKey - returns displayNameSettingKey constant")
    func displayNameSettingKey_returnsDisplayNameSettingKeyConstant() {
        // Given
        let platform = Mock.testPlatform

        // When
        let sut = platform.displayNameSettingKey

        // Then
        #expect(sut == "INFOPLIST_KEY_CFBundleDisplayName")
    }

    @Test("displayNameSettingKey - returns bundleIdentifierSettingKey constant")
    func bundleIdentifierSettingKey_returnsBundleIdentifierSettingKeyConstant() {
        // Given
        let platform = Mock.testPlatform

        // When
        let sut = platform.bundleIdentifierSettingKey

        // Then
        #expect(sut == "PRODUCT_BUNDLE_IDENTIFIER")
    }
}

private extension PlatformTest {
    enum Mock: String, Platform {
        case testPlatform

        var description: String {
            rawValue
        }
    }
}
