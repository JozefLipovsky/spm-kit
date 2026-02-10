//
//  PackageGraphDependency.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-25.
//

import Foundation

/// Represents a dependency in the Swift package dependency graph.
package struct PackageGraphDependency: Decodable, Equatable {
    /// The local path to the dependency.
    package let path: String
}
