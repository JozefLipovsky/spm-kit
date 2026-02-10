//
//  PlatformOptionsTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-20.
//

import Core
import TestHelpers
import Testing

@Suite("PlatformOptions Tests", .tags(.unit))
struct PlatformOptionsTests {

    @Test("selectedVersions - no selection - returns empty array")
    func selectedVersions_noSelection_returnsEmptyArray() throws {
        // Given
        let platforms = try PlatformOptions.parse([])

        // When
        let sut = platforms.selectedVersions

        // Then
        #expect(sut.isEmpty)
    }

    @Test("selectedVersions - multiple selections - returns selected platform versions")
    func selectedVersions_multipleSelections_returnsSelectedPlatformVersions() throws {
        // Given
        let platforms = try PlatformOptions.parse(["--iOS", "v18", "--tvOS", "v26", "--watchOS", "v11"])

        // When
        let sut = platforms.selectedVersions

        // Then
        #expect(sut.count == 3)
        #expect(sut[0].platform == .iOS)
        #expect(sut[0].versionIdentifier == "v18")
        #expect(sut[1].platform == .tvOS)
        #expect(sut[1].versionIdentifier == "v26")
        #expect(sut[2].platform == .watchOS)
        #expect(sut[2].versionIdentifier == "v11")
    }
}
