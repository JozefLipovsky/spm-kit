//
//  PackageDependency.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-01.
//

import Foundation

/// A dependency that can be added to a package target.
package enum PackageDependency: Equatable, Sendable, CustomStringConvertible, Comparable {
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

    /// CustomStringConvertible
    /// The textual representation of the dependency in a `Package.swift` file.
    package var description: String {
        switch self {
            case .target(let target):
                return ".target(name: \"\(target.name)\")"
            case .product(let product, let packageName):
                return ".product(name: \"\(product.name)\", package: \"\(packageName)\")"
        }
    }

    /// Comparable
    /// Used to sort dependencies description for Noora prompt input.
    static package func < (lhs: Self, rhs: Self) -> Bool {
        lhs.description < rhs.description
    }
}

package extension [PackageDependency] {
    /// Returns dependencies filtered by compatibility with the specified product type.
    /// - Parameter productType: The product type to check compatibility against.
    /// - Returns: Filtered array containing only compatible dependencies.
    func compatible(with productType: ProductType) -> [PackageDependency] {
        filter { dependency in
            switch dependency {
                case .target(let target):
                    return target.isCompatible(with: productType)
                case .product:
                    return true
            }
        }
    }

    /// Returns dependencies filtered by compatibility with test targets.
    /// - Returns: Filtered array containing only test-target-compatible dependencies.
    func compatibleWithTestTarget() -> [PackageDependency] {
        filter { dependency in
            switch dependency {
                case .target(let target):
                    return target.isCompatibleAsTestDependency()
                case .product:
                    return true
            }
        }
    }
}
