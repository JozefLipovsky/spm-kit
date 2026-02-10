//
//  PackageGraphDependencies.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-25.
//

import Foundation

/// Represents the collection of dependencies for a Swift package.
package struct PackageGraphDependencies: Decodable, Equatable {
    /// The list of immediate dependencies.
    package let dependencies: [PackageGraphDependency]
}
