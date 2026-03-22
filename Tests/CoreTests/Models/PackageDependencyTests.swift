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
        let target = try targetStub()

        // When
        let sut = PackageDependency.target(target)

        // Then
        #expect(sut.name == "TestTarget")
    }

    @Test("Target case - package - returns nil")
    func targetCase_package_returnsNil() throws {
        // Given
        let target = try targetStub()

        // When
        let sut = PackageDependency.target(target)

        // Then
        #expect(sut.package == nil)
    }

    @Test("Target case - description - returns formatted string")
    func targetCase_description_returnsFormattedString() throws {
        // Given
        let target = try targetStub()

        // When
        let sut = PackageDependency.target(target)

        // Then
        #expect(sut.description == ".target(name: \"TestTarget\")")
    }

    @Test("Product case - name - returns product name")
    func productCase_name_returnsProductName() throws {
        // Given
        let product = try productStub()

        // When
        let sut = PackageDependency.product(product, packageName: "TestPackage")

        // Then
        #expect(sut.name == "TestProduct")
    }

    @Test("Product case - package - returns package name")
    func productCase_package_returnsPackageName() throws {
        // Given
        let product = try productStub()

        // When
        let sut = PackageDependency.product(product, packageName: "TestPackage")

        // Then
        #expect(sut.package == "TestPackage")
    }

    @Test("Product case - description - returns formatted string")
    func productCase_description_returnsFormattedString() throws {
        // Given
        let product = try productStub()

        // When
        let sut = PackageDependency.product(product, packageName: "TestPackage")

        // Then
        #expect(sut.description == ".product(name: \"TestProduct\", package: \"TestPackage\")")
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
}

private extension PackageDependencyTests {
    func targetStub(name: String = "TestTarget") throws -> PackageJSON.Target {
        let targetJSON = Data(
            """
            {
                "name": "\(name)",
                "type": "regular"
            }
            """.utf8
        )

        return try JSONDecoder().decode(PackageJSON.Target.self, from: targetJSON)
    }

    func productStub(name: String = "TestProduct") throws -> PackageJSON.Product {
        let productJSON = Data(
            """
            {
                "name": "\(name)",
                "type": { "library": ["automatic"] }
            }
            """.utf8
        )

        return try JSONDecoder().decode(PackageJSON.Product.self, from: productJSON)
    }

    func productOnlyDependenciesStub() throws -> [PackageDependency] {
        let productStub = try productStub()
        return [
            .product(productStub, packageName: "product A"),
            .product(productStub, packageName: "product B"),
            .product(productStub, packageName: "product C")
        ]
    }
}
