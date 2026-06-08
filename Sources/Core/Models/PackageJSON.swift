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


//extension PackageJSON {
//    package struct StubProduct {
//        package let name: String
//        package let type: Product.ProductType.StubType
//        package let targets: [String]
//
//        package init(name: String, type: Product.ProductType.StubType, targets: [String] = []) {
//            self.name = name
//            self.type = type
//            self.targets = targets
//        }
//    }
//
//    package struct StubTarget {
//        package let name: String
//        package let type: Target.TargetType.StubType
//        package let path: String?
//
//        package init(name: String, type: Target.TargetType.StubType, path: String? = nil) {
//            self.name = name
//            self.type = type
//            self.path = path
//        }
//    }
//
//    package init(
//        name: String = "StubPackage",
//        products: [StubProduct] = [],
//        targets: [StubTarget] = []
//    ) throws {
//        let productsJSON: [String: Any] = products.reduce(into: []) { result, stub in
//            let typeKey: String
//            switch stub.type {
//                case .library:
//                    typeKey = "library"
//                case .executable:
//                    typeKey = "executable"
//                case .plugin:
//                    typeKey = "plugin"
//                case .unsupported:
//                    typeKey = "unknown"
//            }
//            let product: [String: Any] = [
//                "name": stub.name,
//                "settings": [] as [[String: Any]],
//                "targets": stub.targets,
//                "type": [typeKey: nil],
//            ]
//            result[stub.name] = product
//        }
//        let productsArray = productsJSON.values.sorted {
//            String(describing: $0["name"] ?? "") < String(describing: $1["name"] ?? "")
//        }
//
//        let targetsJSON: [String: Any] = targets.reduce(into: []) { result, stub in
//            let target: [String: Any] = [
//                "name": stub.name,
//                "type": stub.type.rawValue,
//            ]
//            if let path = stub.path {
//                target["path"] = path
//            }
//            result[stub.name] = target
//        }
//        let targetsArray = targetsJSON.values.sorted {
//            String(describing: $0["name"] ?? "") < String(describing: $1["name"] ?? "")
//        }
//
//        let root: [String: Any] = [
//            "name": name,
//            "products": productsArray,
//            "targets": targetsArray,
//        ]
//
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = [.sortedKeys]
//        let data = try encoder.encode(root)
//        self = try JSONDecoder().decode(PackageJSON.self, from: data)
//    }
//}


//
//extension PackageJSON {
//    package enum StubType: String {
//        case regular
//        case executable
//        case test
//        case macro
//        case unsupported = "other"
//    }
//}
//
//extension PackageJSON.Target.TargetType {
//    package enum StubType: String {
//        case regular
//        case executable
//        case test
//        case macro
//        case unsupported = "other"
//    }
//
//    package init(stub: StubType) throws {
//        let data = Data("\"\(stub.rawValue)\"".utf8)
//        self = try JSONDecoder().decode(PackageJSON.Target.TargetType.self, from: data)
//    }
//}
//
//extension PackageJSON.Product.ProductType {
//    package enum StubType: String {
//        case library
//        case executable
//        case plugin
//        case unsupported = "other"
//    }
//
//    package init(stub: StubType) throws {
//        if stub == .unsupported {
//            // Use a key not recognized by CodingKeys to trigger the `other` fallback
//            let data = Data("{\"unsupported\": {}}".utf8)
//            self = try JSONDecoder().decode(PackageJSON.Product.ProductType.self, from: data)
//        } else {
//            let data = Data("{\"\(stub.rawValue)\": {}}".utf8)
//            self = try JSONDecoder().decode(PackageJSON.Product.ProductType.self, from: data)
//        }
//    }
//}
//
//extension PackageJSON {
//    package struct ProductStub {
//        package let name: String
//        package let type: PackageJSON.Product.ProductType
//
//        package init(
//            name: String = "ProductStub",
//            type: PackageJSON.Product.ProductType = .library
//        ) {
//            self.name = name
//            self.type = type
//        }
//    }
//
//    package struct TargetStub {
//        package let name: String
//        package let type: PackageJSON.Target.TargetType.StubType
//
//        package init(
//            name: String = "ProductStub",
//            type: PackageJSON.Target.TargetType.StubType = .regular
//        ) {
//            self.name = name
//            self.type = type
//        }
//    }
//
//    func test() throws {
//        let product = ProductStub()
//
//        let type = try PackageJSON.Product.ProductType.init(stub: .library)
//    }
//
//}
//
