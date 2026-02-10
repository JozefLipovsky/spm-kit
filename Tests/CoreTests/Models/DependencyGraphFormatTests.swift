//
//  DependencyGraphFormatTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-05.
//

import Core
import TestHelpers
import Testing

@Suite("DependencyGraphFormat Tests", .tags(.unit))
struct DependencyGraphFormatTests {
    @Test("CaseIterable - contains all expected formats")
    func caseIterable_containsAllExpectedFormats() {
        // Given, When
        let sut = DependencyGraphFormat.allCases

        // Then
        #expect(sut.count == 2)
        #expect(sut.contains(.text))
        #expect(sut.contains(.json))
    }
}
