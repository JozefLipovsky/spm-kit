//
//  ProductDependencyTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-01.
//

import Core
import Foundation
import TestHelpers
import Testing

@Suite("ProductDependency Tests", .tags(.unit))
struct ProductDependencyTests {

    @Test("PackageDependency - name - returns product name")
    func packageDependency_name_returnsProductName() throws {
        // Given
        let product = try productStub()
        let sut = ProductDependency(product: product, packageName: "TestPackage")

        // When, Then
        #expect(sut.name == "TestProduct")
    }

    @Test("PackageDependency - package - returns package name")
    func packageDependency_package_returnsPackageName() throws {
        // Given
        let product = try productStub()
        let sut = ProductDependency(product: product, packageName: "TestPackage")

        // When, Then
        #expect(sut.package == "TestPackage")
    }

    @Test("CustomStringConvertible - description - returns formatted string")
    func customStringConvertible_description_returnsFormattedString() throws {
        // Given
        let product = try productStub()
        let sut = ProductDependency(product: product, packageName: "TestPackage")

        // When, Then
        #expect(sut.description == ".product(name: \"TestProduct\", package: \"TestPackage\")")
    }
}

private extension ProductDependencyTests {
    func productStub() throws -> PackageJSON.Product {
        let productJSON = """
            {
                "name": "TestProduct",
                "type": {"library": ["automatic"]},
                "settings": [],
                "targets": ["TestProductTarget"]
            }
            """

        let productData = try #require(productJSON.data(using: .utf8))
        let product = try? JSONDecoder().decode(PackageJSON.Product.self, from: productData)
        return try #require(product)
    }
}
