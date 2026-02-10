//
//  TargetDependencyTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-01.
//

import Core
import Foundation
import TestHelpers
import Testing

@Suite("TargetDependency Tests", .tags(.unit))
struct TargetDependencyTests {

    @Test("PackageDependency - name - returns target name")
    func packageDependency_name_returnsTargetName() throws {
        // Given
        let target = try targetStub()
        let sut = TargetDependency(target: target)

        // When, Then
        #expect(sut.name == "TestTarget")
    }

    @Test("PackageDependency - package - returns nil")
    func packageDependency_package_returnsNil() throws {
        // Given
        let target = try targetStub()
        let sut = TargetDependency(target: target)

        // When, Then
        #expect(sut.package == nil)
    }

    @Test("CustomStringConvertible - description - returns formatted string")
    func customStringConvertible_description_returnsFormattedString() throws {
        // Given
        let target = try targetStub()
        let sut = TargetDependency(target: target)

        // When, Then
        #expect(sut.description == ".target(name: \"TestTarget\")")
    }
}

private extension TargetDependencyTests {
    func targetStub() throws -> PackageJSON.Target {
        let targetJSON = """
            {
                "name": "TestTarget",
                "type": "regular"
            }
            """

        let targetData = try #require(targetJSON.data(using: .utf8))
        let target = try? JSONDecoder().decode(PackageJSON.Target.self, from: targetData)
        return try #require(target)
    }
}
