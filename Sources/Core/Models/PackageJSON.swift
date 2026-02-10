//
//  PackageJSON.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-22.
//

import Foundation

/// Represents the parsed JSON output of `swift package dump-package`.
package struct PackageJSON: Decodable, Equatable {
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
    package struct Product: Decodable, Equatable {
        /// The name of the product.
        package let name: String
        /// The type of the product.
        package let type: ProductType
    }

    /// Represents a swift package target in a `PackageJSON`.
    package struct Target: Decodable, Equatable {
        /// The name of the target.
        package let name: String
        /// The type of the target.
        package let type: TargetType
    }
}

extension PackageJSON.Target {
    /// Defines the types of targets available in a `PackageJSON.Target`.
    package enum TargetType: Decodable, Equatable {
        /// A target that contains code for the Swift package's functionality.
        case regular
        /// A target that contains code for an executable's main module.
        case executable
        /// A target that contains tests for the Swift package's other targets.
        case test
        /// A target that provides a Swift macro.
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
    package enum ProductType: Equatable, Decodable {
        /// A library product (includes static, dynamic, automatic libraries).
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
