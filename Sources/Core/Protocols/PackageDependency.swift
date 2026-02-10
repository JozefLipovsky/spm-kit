//
//  PackageDependency.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-01.
//

import Foundation

/// A dependency that can be added to a package target.
package protocol PackageDependency: CustomStringConvertible {
    /// The name of the dependency.
    var name: String { get }

    /// The name of the package containing the dependency, if it's an external dependency.
    /// For target dependencies within the same package, this value is nil.
    var package: String? { get }
}
