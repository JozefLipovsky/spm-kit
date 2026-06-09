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
        let targetA = try PackageJSON.Target.stub(name: "TargetA")
        let targetB = try PackageJSON.Target.stub(name: "TargetB")
        let dependencies = [
            PackageDependency.target(targetA),
            PackageDependency.target(targetB)]

        // When
        let sut = dependencies.target(named: "TargetA")

        // Then
        #expect(sut?.name == "TargetA")
        #expect(sut == .target(targetA))
    }

    @Test("Dependencies - target named - returns nil when target name not found")
    func dependencies_targetNamed_returnsNilWhenTargetNameNotFound() throws {
        // Given
        let target = try PackageJSON.Target.stub(name: "ExistingTarget")
        let dependencies = [PackageDependency.target(target)]

        // When
        let sut = dependencies.target(named: "NonExistent")

        // Then
        #expect(sut == nil)
    }

    @Test("Dependencies - target named - skips products to find target")
    func dependencies_targetNamed_skipsProductsToFindTarget() throws {
        // Given
        let target = try PackageJSON.Target.stub(name: "StubName")
        let product = try PackageJSON.Product.stub(name: "StubName")
        let dependencies = [
            PackageDependency.product(product, packageName: "External"),
            PackageDependency.target(target),
            PackageDependency.product(product, packageName: "Other")
        ]

        // When
        let sut = dependencies.target(named: "StubName")

        // Then
        #expect(sut?.name == "StubName")
        #expect(sut == .target(target))
    }

    @Test("Dependencies - target named - returns nil when only products exist")
    func dependencies_targetNamed_returnsNilWhenOnlyProductsExist() throws {
        // Given
        let product = try PackageJSON.Product.stub(name: "StubName")
        let dependencies = [
            PackageDependency.product(product, packageName: "A"),
            PackageDependency.product(product, packageName: "B")
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
        let regularTargetStub = try PackageJSON.Target.stub(type: .regular)
        let testTargetStub = try PackageJSON.Target.stub(type: .test)
        let productStub = try PackageJSON.Product.stub()
        let dependencies = [
            PackageDependency.target(regularTargetStub),
            PackageDependency.target(testTargetStub),
            PackageDependency.product(productStub, packageName: "ExternalA"),
            PackageDependency.product(productStub, packageName: "ExternalB")
        ]

        // When
        let selectedTarget = try PackageJSON.Target.stub(type: .regular)
        let sut = dependencies.compatible(withSelectedDependency: .target(selectedTarget))

        // Then
        #expect(sut.count == 3)
        #expect(sut[0] == .target(regularTargetStub))
        #expect(sut[1] == .product(productStub, packageName: "ExternalA"))
        #expect(sut[2] == .product(productStub, packageName: "ExternalB"))
    }

    @Test("Dependencies - compatible with regular target dependency - filters out test targets")
    func dependencies_compatibleWithRegularTargetDependency_filtersOutTestTargets() throws {
        // Given
        let dependencies = try availableTargetDependenciesStub()

        // When
        let selectedTarget = try PackageJSON.Target.stub(type: .regular)
        let sut = dependencies.compatible(withSelectedDependency: .target(selectedTarget))

        // Then
        #expect(sut.count == 3)
        #expect(sut[0] == .target(try PackageJSON.Target.stub(type: .regular)))
        #expect(sut[1] == .target(try PackageJSON.Target.stub(type: .executable)))
        #expect(sut[2] == .target(try PackageJSON.Target.stub(type: .macro)))
    }

    @Test("Dependencies - compatible with executable target dependency - filters out test targets")
    func dependencies_compatibleWithExecutableTargetDependency_filtersOutTestTargets() throws {
        // Given
        let dependencies = try availableTargetDependenciesStub()

        // When
        let selectedTarget = try PackageJSON.Target.stub(type: .executable)
        let sut = dependencies.compatible(withSelectedDependency: .target(selectedTarget))

        // Then
        #expect(sut.count == 3)
        #expect(sut[0] == .target(try PackageJSON.Target.stub(type: .regular)))
        #expect(sut[1] == .target(try PackageJSON.Target.stub(type: .executable)))
        #expect(sut[2] == .target(try PackageJSON.Target.stub(type: .macro)))
    }

    @Test("Dependencies - compatible with macro target dependency - filters out test and macro targets")
    func dependencies_compatibleWithMacroTargetDependency_filtersOutTestAndMacroTargets() throws {
        // Given
        let dependencies = try availableTargetDependenciesStub()

        // When
        let selectedTarget = try PackageJSON.Target.stub(type: .macro)
        let sut = dependencies.compatible(withSelectedDependency: .target(selectedTarget))

        // Then
        #expect(sut.count == 2)
        #expect(sut[0] == .target(try PackageJSON.Target.stub(type: .regular)))
        #expect(sut[1] == .target(try PackageJSON.Target.stub(type: .executable)))
    }

    @Test("Dependencies - compatible with test target dependency - filters out and macro targets")
    func dependencies_compatibleWithTestTargetDependency_filtersOutTestAndMacroTargets() throws {
        // Given
        let dependencies = try availableTargetDependenciesStub()

        // When
        let selectedTarget = try PackageJSON.Target.stub(type: .test)
        let sut = dependencies.compatible(withSelectedDependency: .target(selectedTarget))

        // Then
        #expect(sut.count == 3)
        #expect(sut[0] == .target(try PackageJSON.Target.stub(type: .regular)))
        #expect(sut[1] == .target(try PackageJSON.Target.stub(type: .executable)))
        #expect(sut[2] == .target(try PackageJSON.Target.stub(type: .test)))
    }
}

private extension PackageDependencyTests {
    func productOnlyDependenciesStub() throws -> [PackageDependency] {
        let productStub = try PackageJSON.Product.stub()
        return [
            .product(productStub, packageName: "product A"),
            .product(productStub, packageName: "product B"),
            .product(productStub, packageName: "product C")
        ]
    }

    func availableTargetDependenciesStub() throws -> [PackageDependency] {
        [
            PackageDependency.target(try PackageJSON.Target.stub(type: .regular)),
            PackageDependency.target(try PackageJSON.Target.stub(type: .executable)),
            PackageDependency.target(try PackageJSON.Target.stub(type: .macro)),
            PackageDependency.target(try PackageJSON.Target.stub(type: .test)),
            PackageDependency.target(try PackageJSON.Target.stub(type: .other))
        ]
    }
}
