//
//  PackageJSON.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-22.
//

import Foundation

/// Represents the parsed JSON output of `swift package dump-package`.
package struct PackageJSON: Decodable, Equatable, Sendable {
    /// The name of the package.
    package let name: String
    /// The products defined in the package.
    package let products: [Product]
    /// The targets defined in the package.
    package let targets: [Target]

    private enum CodingKeys: String, CodingKey {
        case name
        case products
        case targets
    }

    package init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.products = try container.decode([Product].self, forKey: .products)
        self.targets = try container.decode([Target].self, forKey: .targets)
    }
}

extension PackageJSON {
    /// Represents a swift package product in a `PackageJSON`.
    package struct Product: Decodable, Equatable, Sendable {
        /// The name of the product.
        package let name: String
        /// The type of the product.
        package let type: ProductType
    }

    /// Represents a swift package target in a `PackageJSON`.
    package struct Target: Decodable, Equatable, Sendable {
        /// The name of the target.
        package let name: String
        /// The type of the target.
        package let type: TargetType
    }
}

extension PackageJSON.Target {
    /// Defines the types of targets available in a `PackageJSON.Target`.
    package enum TargetType: String, Decodable, Equatable, Sendable, CaseIterable {
        /// A regular target.
        case regular
        /// An executable target.
        case executable
        /// A test target.
        case test
        /// A macro target.
        case macro
        /// A `PackageDescription.Target` type that is not explicitly supported by `swift pacakge CLI`.
        case other

        package init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            switch rawValue {
                case "regular":
                    self = .regular
                case "executable":
                    self = .executable
                case "test":
                    self = .test
                case "macro":
                    self = .macro
                default:
                    self = .other
            }
        }
    }
}

extension PackageJSON.Product {
    /// Defines the types of products available in a `PackageJSON.Product`.
    package enum ProductType: String, Equatable, Decodable, Sendable {
        /// A library product (includes static, dynamic).
        case library
        /// An executable product.
        case executable
        /// A plugin product.
        case plugin
        /// A `PackageDescription.Product` type that is not explicitly supported by `swift pacakge CLI`.
        case other

        private enum CodingKeys: String, CodingKey {
            case library
            case executable
            case plugin
        }

        package init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if container.contains(.executable) {
                self = .executable
            } else if container.contains(.library) {
                self = .library
            } else if container.contains(.plugin) {
                self = .plugin
            } else {
                self = .other
            }
        }
    }
}

package extension PackageJSON.Target {
    /// Checks whether a target is compatible as a dependency for the given `ProductType`.
    func isCompatible(with productType: ProductType) -> Bool {
        switch productType {
            case .library, .staticLibrary, .dynamicLibrary:
                switch type {
                    case .executable, .regular, .macro:
                        return true
                    case .other, .test:
                        return false
                }
            case .executable:
                switch type {
                    case .regular, .executable:
                        return true
                    case .macro, .other, .test:
                        return false
                }
            case .plugin:
                return false
        }
    }

    /// Checks whether a target is compatible as a dependency for a test target.
    func isCompatibleAsTestDependency() -> Bool {
        switch type {
            case .regular, .executable, .test:
                return true
            case .macro, .other:
                return false
        }
    }

    /// Checks whether this target is compatible as a dependency for the given target.
    /// - Parameter dependencyTarget: The target that will depend on this target.
    /// - Returns: `true` if this target can be used as a dependency for the given target type.
    func isCompatible(asDependencyFor dependencyTarget: PackageJSON.Target) -> Bool {
        switch dependencyTarget.type {
            case .regular, .executable:
                switch type {
                    case .regular, .executable, .macro:
                        return true
                    case .test, .other:
                        return false
                }
            case .test:
                switch type {
                    case .regular, .executable, .test:
                        return true
                    case .macro, .other:
                        return false
                }
            case .macro:
                switch type {
                    case .regular, .executable:
                        return true
                    case .test, .macro, .other:
                        return false
                }
            case .other:
                return false
        }
    }
}
