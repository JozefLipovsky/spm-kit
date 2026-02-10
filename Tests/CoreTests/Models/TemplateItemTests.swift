//
//  TemplateItemTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-20.
//

import Core
import TestHelpers
import Testing

@Suite("TemplateItem Tests", .tags(.unit))
struct TemplateItemTests {
    @Test("initializer - without copyFlags - creates template with empty copyFlags")
    func initializer_withoutCopyFlags_createsTemplateWithEmptyCopyFlags() {
        // Given, When
        let sut = TemplateItem(path: "/fake/path/to/Template")

        // Then
        #expect(sut.copyFlags.isEmpty)
    }

    @Test("initializer - with copyFlags - creates template with specified copyFlags")
    func initializer_withCopyFlags_createsTemplateWithSpecifiedCopyFlags() {
        // Given, When
        let expectedFlags = ["-R", "-v"]
        let sut = TemplateItem(path: "/fake/path/to/Template", copyFlags: expectedFlags)

        // Then
        #expect(sut.copyFlags == expectedFlags)
    }

    @Test("pathString  - returns the correct path string")
    func pathString_returnsCorrectPathString() {
        // Given, When
        let expectedPathString = "/fake/path/to/Template"
        let sut = TemplateItem(path: expectedPathString)

        // Then
        #expect(sut.pathString == expectedPathString)
    }
}
