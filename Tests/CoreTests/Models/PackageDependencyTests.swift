//
//  PackageDependencyTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-03-13.
//

import Core
import Foundation
import TestHelpers
import Testing

@Suite("PackageDependency Tests", .tags(.unit))
struct PackageDependencyTests {

    @Test("Target case - name - returns target name")
    func targetCase_name_returnsTargetName() throws {
        // Given
        let target = try PackageJSON.Target.stub()

        // When
        let sut = PackageDependency.target(target)

        // Then
        #expect(sut.name == "TargetStub")
    }

    @Test("Target case - package - returns nil")
    func targetCase_package_returnsNil() throws {
        // Given
        let target = try PackageJSON.Target.stub()

        // When
        let sut = PackageDependency.target(target)

        // Then
        #expect(sut.package == nil)
    }

    @Test("Target case - description - returns formatted string")
    func targetCase_description_returnsFormattedString() throws {
        // Given
        let target = try PackageJSON.Target.stub()

        // When
        let sut = PackageDependency.target(target)

        // Then
        #expect(sut.description == ".target(name: \"TargetStub\")")
    }

    @Test("Product case - name - returns product name")
    func productCase_name_returnsProductName() throws {
        // Given
        let product = try PackageJSON.Product.stub()

        // When
        let sut = PackageDependency.product(product, packageName: "TestPackage")

        // Then
        #expect(sut.name == "ProductStub")
    }

    @Test("Product case - package - returns package name")
    func productCase_package_returnsPackageName() throws {
        // Given
        let product = try PackageJSON.Product.stub()

        // When
        let sut = PackageDependency.product(product, packageName: "TestPackage")

        // Then
        #expect(sut.package == "TestPackage")
    }

    @Test("Product case - description - returns formatted string")
    func productCase_description_returnsFormattedString() throws {
        // Given
        let product = try PackageJSON.Product.stub()

        // When
        let sut = PackageDependency.product(product, packageName: "TestPackage")

        // Then
        #expect(sut.description == ".product(name: \"ProductStub\", package: \"TestPackage\")")
    }

    @Test("Dependencies - compatible with product type - products always pass through")
    func dependencies_compatibleWithProductType_productsAlwaysPassThrough() throws {
        // Given
        let productDependencies = try productOnlyDependenciesStub()
        #expect(productDependencies.count == 3)

        // When
        let sut = productDependencies.compatible(with: .library)

        // Then
        #expect(sut == productDependencies)
        #expect(sut.count == 3)
    }

    @Test("Dependencies - compatibleWithTestTarget - products always pass through")
    func dependencies_compatibleWithTestTarget_productsAlwaysPassThrough() throws {
        // Given
        let productDependencies = try productOnlyDependenciesStub()
        #expect(productDependencies.count == 3)

        // When
        let sut = productDependencies.compatibleWithTestTarget()

        // Then
        #expect(sut == productDependencies)
        #expect(sut.count == 3)
    }

    @Test("Dependencies - target named - returns matching target dependency")
    func dependencies_targetNamed_returnsMatchingTargetDependency() throws {
        // Given
        let targetStubA = try PackageDependency.targetStub(name: "TargetA")
        let targetStubB = try PackageDependency.targetStub(name: "TargetB")
        let dependencies = [targetStubA, targetStubB]

        // When
        let sut = dependencies.target(named: "TargetA")

        // Then
        #expect(sut?.name == "TargetA")
        #expect(sut == targetStubA)
    }

    @Test("Dependencies - target named - returns nil when target name not found")
    func dependencies_targetNamed_returnsNilWhenTargetNameNotFound() throws {
        // Given
        let dependencies = [try PackageDependency.targetStub(name: "ExistingTarget")]

        // When
        let sut = dependencies.target(named: "NonExistent")

        // Then
        #expect(sut == nil)
    }

    @Test("Dependencies - target named - skips products to find target")
    func dependencies_targetNamed_skipsProductsToFindTarget() throws {
        // Given
        let targetStub = try PackageDependency.targetStub(name: "StubName")
        let dependencies = [
            try PackageDependency.productStub(name: "StubName", packageName: "External"),
            targetStub,
            try PackageDependency.productStub(name: "StubName", packageName: "Other")
        ]

        // When
        let sut = dependencies.target(named: "StubName")

        // Then
        #expect(sut?.name == "StubName")
        #expect(sut == targetStub)
    }

    @Test("Dependencies - target named - returns nil when only products exist")
    func dependencies_targetNamed_returnsNilWhenOnlyProductsExist() throws {
        // Given
        let dependencies = [
            try PackageDependency.productStub(name: "StubName", packageName: "A"),
            try PackageDependency.productStub(name: "StubName", packageName: "B")
        ]

        // When
        let sut = dependencies.target(named: "StubName")

        // Then
        #expect(sut == nil)
    }

    @Test("Dependencies - target named - returns nil for empty array")
    func dependencies_targetNamed_returnsNilForEmptyArray() {
        // Given
        let dependencies: [PackageDependency] = []

        // When
        let sut = dependencies.target(named: "anything")

        // Then
        #expect(sut == nil)
    }

    @Test("Dependencies - compatible with selected dependency - products always pass through")
    func dependencies_compatibleWithSelectedDependency_productsAlwaysPassThrough() throws {
        // Given
        let targetStub = try PackageDependency.targetStub(type: .regular)
        let productStubA = try PackageDependency.productStub(packageName: "ExternalA")
        let productStubB = try PackageDependency.productStub(packageName: "ExternalB")
        let dependencies = [
            targetStub,
            try PackageDependency.targetStub(type: .test),
            productStubA,
            productStubB
        ]

        // When
        let sut = dependencies.compatible(withSelectedDependency: try .targetStub(type: .regular))

        // Then
        #expect(sut.count == 3)
        #expect(sut[0] == targetStub)
        #expect(sut[1] == productStubA)
        #expect(sut[2] == productStubB)
    }

    @Test("Dependencies - compatible with regular target dependency - filters out test targets")
    func dependencies_compatibleWithRegularTargetDependency_filtersOutTestTargets() throws {
        // Given
        let dependencies = try availableTargetDependenciesStub()

        // When
        let sut = dependencies.compatible(withSelectedDependency: try .targetStub(type: .regular))

        // Then
        let expectedRegularTarget = try PackageDependency.targetStub(type: .regular)
        let expectedExecutableTarget = try PackageDependency.targetStub(type: .executable)
        let expectedMacroTarget = try PackageDependency.targetStub(type: .macro)
        #expect(sut.count == 3)
        #expect(sut[0] == expectedRegularTarget)
        #expect(sut[1] == expectedExecutableTarget)
        #expect(sut[2] == expectedMacroTarget)
    }

    @Test("Dependencies - compatible with executable target dependency - filters out test targets")
    func dependencies_compatibleWithExecutableTargetDependency_filtersOutTestTargets() throws {
        // Given
        let dependencies = try availableTargetDependenciesStub()

        // When
        let sut = dependencies.compatible(withSelectedDependency: try .targetStub(type: .executable))

        // Then
        #expect(sut.count == 3)
        let expectedRegularTarget = try PackageDependency.targetStub(type: .regular)
        let expectedExecutableTarget = try PackageDependency.targetStub(type: .executable)
        let expectedMacroTarget = try PackageDependency.targetStub(type: .macro)
        #expect(sut[0] == expectedRegularTarget)
        #expect(sut[1] == expectedExecutableTarget)
        #expect(sut[2] == expectedMacroTarget)
    }

    @Test("Dependencies - compatible with macro target dependency - filters out test and macro targets")
    func dependencies_compatibleWithMacroTargetDependency_filtersOutTestAndMacroTargets() throws {
        // Given
        let dependencies = try availableTargetDependenciesStub()

        // When
        let sut = dependencies.compatible(withSelectedDependency: try .targetStub(type: .macro))

        // Then
        #expect(sut.count == 2)
        let expectedRegularTarget = try PackageDependency.targetStub(type: .regular)
        let expectedExecutableTarget = try PackageDependency.targetStub(type: .executable)
        #expect(sut[0] == expectedRegularTarget)
        #expect(sut[1] == expectedExecutableTarget)
    }

    @Test("Dependencies - compatible with test target dependency - filters out macro targets")
    func dependencies_compatibleWithTestTargetDependency_filtersOutMacroTargets() throws {
        // Given
        let dependencies = try availableTargetDependenciesStub()

        // When
        let sut = dependencies.compatible(withSelectedDependency: try .targetStub(type: .test))

        // Then
        #expect(sut.count == 3)
        let expectedRegularTarget = try PackageDependency.targetStub(type: .regular)
        let expectedExecutableTarget = try PackageDependency.targetStub(type: .executable)
        let expectedTestTarget = try PackageDependency.targetStub(type: .test)
        #expect(sut[0] == expectedRegularTarget)
        #expect(sut[1] == expectedExecutableTarget)
        #expect(sut[2] == expectedTestTarget)
    }
}

private extension PackageDependencyTests {
    func productOnlyDependenciesStub() throws -> [PackageDependency] {
        [
            try .productStub(packageName: "product A"),
            try .productStub(packageName: "product B"),
            try .productStub(packageName: "product C")
        ]
    }

    func availableTargetDependenciesStub() throws -> [PackageDependency] {
        [
            try .targetStub(type: .regular),
            try .targetStub(type: .executable),
            try .targetStub(type: .macro),
            try .targetStub(type: .test),
            try .targetStub(type: .other)
        ]
    }
}
