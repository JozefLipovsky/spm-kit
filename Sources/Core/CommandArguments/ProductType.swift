//
//  ProductType.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-08-18.
//

import ArgumentParser
import Foundation

/// The type of product to add.
package enum ProductType: String, CaseIterable, CustomStringConvertible, ExpressibleByArgument {
    /// A library product.
    case library
    /// A static library product.
    case staticLibrary = "static-library"
    /// A dynamic library product.
    case dynamicLibrary = "dynamic-library"
    /// An executable product.
    case executable
    /// A plugin product.
    case plugin

    /// CustomStringConvertible
    package var description: String { rawValue }

    /// ExpressibleByArgument
    package static var allValueStrings: [String] {
        allCases.map(\.rawValue)
    }

    /// CaseIterable
    package static var allCases: [ProductType] {
        // As of Dec 28, 2025, the `swift package` CLI `add-target` command
        // does not support the `plugin` type. We exclude it here to prevent
        // users from selecting the `plugin` product type via the `add-module` command.
        [.library, .staticLibrary, .dynamicLibrary, .executable]
    }
}
