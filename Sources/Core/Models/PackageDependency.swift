//
//  PackageDependency.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-01.
//

import Foundation

/// A dependency that can be added to a package target.
package enum PackageDependency: Equatable, Sendable, CustomStringConvertible {
    /// A target dependency within the same package.
    case target(PackageJSON.Target)
    /// A product dependency from an external package.
    case product(PackageJSON.Product, packageName: String)

    /// The name of the dependency.
    package var name: String {
        switch self {
            case .target(let target):
                return target.name
            case .product(let product, _):
                return product.name
        }
    }

    /// The name of the package containing the dependency, if it's an external dependency.
    /// For target dependencies within the same package, this value is nil.
    package var package: String? {
        switch self {
            case .target:
                return nil
            case .product(_, let packageName):
                return packageName
        }
    }

    /// The textual representation of the dependency in a `Package.swift` file.
    package var description: String {
        switch self {
            case .target(let target):
                return ".target(name: \"\(target.name)\")"
            case .product(let product, let packageName):
                return ".product(name: \"\(product.name)\", package: \"\(packageName)\")"
        }
    }
}
