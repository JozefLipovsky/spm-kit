//
//  DependencyGraphFormat.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-05.
//

import Foundation

/// The format for the dependency graph output.
package enum DependencyGraphFormat: String, CaseIterable {
    /// A text-based representation.
    case text
    /// A JSON representation.
    case json
}
