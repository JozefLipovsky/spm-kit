//
//  AddTargetDependenciesTest.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-06-13.
//

import SubCommands
import TestHelpers
import Testing

@Suite("AddTargetDependencies Tests", .tags(.unit))
struct AddTargetDependenciesTest {


}

@Suite("AddTargetDependencies.Error Tests", .tags(.unit))
struct AddTargetDependenciesErrorTests {

    @Test("errorDescription - with selected targetNotFound - returns expected message")
    func errorDescription_withSelectedTargetNotFound_returnsExpectedMessage() {
        // Given
        let targetName = "NonExistentTarget"
        let error = AddTargetDependencies.Error.targetNotFound(name: targetName)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Could not find a target named '\(targetName)'.")
    }


    @Test("errorDescription - with targetsNotFound - returns expected message")
    func errorDescription_withTargetsNotFound_returnsExpectedMessage() {
        // Given
        let error = AddTargetDependencies.Error.targetsNotFound

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Could not find any targets in the project.")
    }
}
