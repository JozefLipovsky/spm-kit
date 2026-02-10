//
//  ProductDependency.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-01.
//

import Foundation

/// Represents a product dependency in a Swift package.
package struct ProductDependency: Equatable {
    private let product: PackageJSON.Product
    private let packageName: String

    /// Creates a new product dependency.
    /// - Parameters:
    ///   - product: The product from the package manifest.
    ///   - packageName: The name of the package containing the product.
    package init(product: PackageJSON.Product, packageName: String) {
        self.product = product
        self.packageName = packageName
    }
}

extension ProductDependency: PackageDependency {
    /// The name of the product.
    package var name: String {
        product.name
    }

    /// The name of the package containing the product.
    package var package: String? {
        packageName
    }

    /// The textual representation of the product dependency in a `Package.swift` file.
    package var description: String {
        ".product(name: \"\(name)\", package: \"\(packageName)\")"
    }
}
