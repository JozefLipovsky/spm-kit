//
//  PBXTargetExtensionsTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-11-18.
//

import Core
import Foundation
import PathKit
import TestHelpers
import Testing
import XcodeProj

@Suite("PBXTarget Extensions Tests", .tags(.integration))
struct PBXTargetExtensionsTests {

    @Test("propertyIdentifiers - returns expected identifiers")
    func propertyIdentifiers_returnsExpectedIdentifiers() throws {
        // Given
        let projectStub = try projectStub()
        let sut = try #require(projectStub.pbxproj.nativeTargets.first)

        // When
        let propertyIdentifiers = sut.propertyIdentifiers()

        // Then
        // NOTE: This will need to be updated to match the fixture stub values if the fixture is modified.
        #expect(propertyIdentifiers.count == 15)
        #expect(propertyIdentifiers.contains("6836DAE32ECECE04002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAE22ECECE04002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAF72ECECEDE002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAE42ECECE04002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAF22ECECE06002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAF52ECECEC0002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAE52ECECE04002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAE72ECECE04002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAF62ECECEDE002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAF42ECECEC0002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAF12ECECE06002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAF02ECECE06002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAF32ECECEC0002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAF82ECECEDE002D2CA1"))
        #expect(propertyIdentifiers.contains("6836DAE12ECECE04002D2CA1"))
    }

    @Test("filePaths - returns expected paths")
    func filePaths_returnsExpectedPaths() throws {
        // Given
        let projectStub = try projectStub()
        let sut = try #require(projectStub.pbxproj.nativeTargets.first)

        // When
        let filePaths = sut.filePaths()

        // Then
        // NOTE: This will need to be updated to match the fixture stub values if the fixture is modified.
        #expect(filePaths.count == 3)
        #expect(filePaths.contains("MobilePlatform.app"))
        #expect(filePaths.contains("Algorithms"))
        #expect(filePaths.contains("Collections"))
    }
}

private extension PBXTargetExtensionsTests {
    func projectStub() throws -> XcodeProj {
        let url = try #require(
            Bundle.module.url(
                forResource: "ProjectStub",
                withExtension: "xcodeproj",
                subdirectory: "_Fixtures/PBXTargetExtensionsTests"
            )
        )

        return try XcodeProj(path: Path(url.path))
    }
}
