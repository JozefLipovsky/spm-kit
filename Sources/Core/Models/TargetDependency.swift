//
//  TargetDependency.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-01.
//

import Foundation

/// Represents a target dependency in a Swift package.
package struct TargetDependency: Equatable {
    private let target: PackageJSON.Target

    /// Creates a new target dependency.
    /// - Parameter target: The target from the package manifest.
    package init(target: PackageJSON.Target) {
        self.target = target
    }
}

extension TargetDependency: PackageDependency {
    /// The name of the target.
    package var name: String {
        target.name
    }

    /// The name of the package containing the target.
    package var package: String? {
        nil
    }

    /// The textual representation of the target dependency in a `Package.swift` file.
    package var description: String {
        ".target(name: \"\(name)\")"
    }
}
