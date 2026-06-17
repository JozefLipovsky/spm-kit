//
//  PackageJSONTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-22.
//

import Core
import Foundation
import TestHelpers
import Testing

@Suite("PackageJSON Tests", .tags(.unit))
struct PackageJSONTests {
    @Test("Decodable - with valid JSON - decodes targets and product types")
    func decodable_withValidJSON_decodesTargetsAndProductTypes() throws {
        // Given, When
        let sut = try packageStub()

        // Then
        #expect(sut.name == "StubPackage")

        #expect(sut.products.count == 6)
        #expect(sut.products[0].name == "Library")
        #expect(sut.products[0].type == .library)
        #expect(sut.products[1].name == "StaticLibrary")
        #expect(sut.products[1].type == .library)
        #expect(sut.products[2].name == "DynamicLibrary")
        #expect(sut.products[2].type == .library)
        #expect(sut.products[3].name == "Executable")
        #expect(sut.products[3].type == .executable)
        #expect(sut.products[4].name == "Plugin")
        #expect(sut.products[4].type == .plugin)
        #expect(sut.products[5].name == "Other")
        #expect(sut.products[5].type == .other)

        #expect(sut.targets.count == 5)
        #expect(sut.targets.count == PackageJSON.Target.TargetType.allCases.count)
        #expect(sut.targets[0].name == "RegularTarget")
        #expect(sut.targets[0].type == .regular)
        #expect(sut.targets[1].name == "TestTarget")
        #expect(sut.targets[1].type == .test)
        #expect(sut.targets[2].name == "MacroTarget")
        #expect(sut.targets[2].type == .macro)
        #expect(sut.targets[3].name == "ExecutableTarget")
        #expect(sut.targets[3].type == .executable)
        #expect(sut.targets[4].name == "OtherTarget")
        #expect(sut.targets[4].type == .other)
    }

    @Test("Targets - compatible - with command argument library product types")
    func targets_compatible_withCommandArgumentLibraryProductTypes() throws {
        // Given
        let sut = try targetStubs()

        // When
        sut.forEach { target in
            // Then
            switch target.type {
                case .executable, .regular, .macro:
                    #expect(target.isCompatible(with: .library))
                    #expect(target.isCompatible(with: .staticLibrary))
                    #expect(target.isCompatible(with: .dynamicLibrary))
                case .other, .test:
                    #expect(!target.isCompatible(with: .library))
                    #expect(!target.isCompatible(with: .staticLibrary))
                    #expect(!target.isCompatible(with: .dynamicLibrary))
            }
        }
    }

    @Test("Targets - compatible - with command argument executable product type")
    func targets_compatible_withCommandArgumentExecutableProductType() throws {
        // Given
        let sut = try targetStubs()

        // When
        sut.forEach { target in
            // Then
            switch target.type {
                case .executable, .regular:
                    #expect(target.isCompatible(with: .executable))
                case .macro, .other, .test:
                    #expect(!target.isCompatible(with: .executable))
            }
        }
    }

    @Test("Targets - compatible - with command argument plugin product type")
    func targets_compatible_withCommandArgumentPluginProductType() throws {
        // Given
        let sut = try targetStubs()

        // When
        sut.forEach { target in
            // Then
            #expect(!target.isCompatible(with: .plugin))
        }
    }

    @Test("Targets - compatible as test dependency")
    func targets_compatibleAsTestDependency() throws {
        // Given
        let sut = try targetStubs()

        // When
        sut.forEach { target in
            // Then
            switch target.type {
                case .regular, .executable, .test:
                    #expect(target.isCompatibleAsTestDependency())
                case .macro, .other:
                    #expect(!target.isCompatibleAsTestDependency())
            }
        }
    }

    @Test("Regular target - is compatible as dependency for - regular, executable and macro targets")
    func regularTarget_isCompatibleAsDependencyFor_regularExecutableAndMacroTargets() throws {
        // Given
        let targetsStub = try targetStubs()
        let sut = try #require(targetsStub.first(where: { $0.type == .regular }))

        // When
        targetsStub.forEach { target in
            // Then
            switch target.type {
                case .regular, .executable, .macro:
                    #expect(target.isCompatible(asDependencyFor: sut))
                case .test, .other:
                    #expect(!target.isCompatible(asDependencyFor: sut))
            }
        }
    }

    @Test("Executable target - is compatible as dependency for - regular, executable and macro targets")
    func executableTarget_isCompatibleAsDependencyFor_regularExecutableAndMacroTargets() throws {
        // Given
        let targetsStub = try targetStubs()
        let sut = try #require(targetsStub.first(where: { $0.type == .executable }))

        // When
        targetsStub.forEach { target in
            // Then
            switch target.type {
                case .regular, .executable, .macro:
                    #expect(target.isCompatible(asDependencyFor: sut))
                case .test, .other:
                    #expect(!target.isCompatible(asDependencyFor: sut))
            }
        }
    }

    @Test("Test target - is compatible as dependency for - regular, executable and test targets")
    func testTarget_isCompatibleAsDependencyFor_regularExecutableAndTestTargets() throws {
        // Given
        let targetsStub = try targetStubs()
        let sut = try #require(targetsStub.first(where: { $0.type == .test }))

        // When
        targetsStub.forEach { target in
            // Then
            switch target.type {
                case .regular, .executable, .test:
                    #expect(target.isCompatible(asDependencyFor: sut))
                case .macro, .other:
                    #expect(!target.isCompatible(asDependencyFor: sut))
            }
        }
    }

    @Test("Macro target - is compatible as dependency for - regular and executable targets")
    func macroTarget_isCompatibleAsDependencyFor_regularAndExecutableTargets() throws {
        // Given
        let targetsStub = try targetStubs()
        let sut = try #require(targetsStub.first(where: { $0.type == .macro }))

        // When
        targetsStub.forEach { target in
            // Then
            switch target.type {
                case .regular, .executable:
                    #expect(target.isCompatible(asDependencyFor: sut))
                case .test, .macro, .other:
                    #expect(!target.isCompatible(asDependencyFor: sut))
            }
        }
    }

    @Test("Other target - is not compatible as dependency for - any target types")
    func otherTarget_isNotCompatibleAsDependencyForAnyTarget() throws {
        // Given
        let targetsStub = try targetStubs()
        let sut = try #require(targetsStub.first(where: { $0.type == .other }))

        // When
        targetsStub.forEach { target in
            // Then
            #expect(!target.isCompatible(asDependencyFor: sut))
        }
    }
}

private extension PackageJSONTests {
    func targetStubs() throws -> [PackageJSON.Target] {
        try packageStub().targets
    }

    func packageStub() throws -> PackageJSON {
        try PackageJSON.stub()
    }
}
