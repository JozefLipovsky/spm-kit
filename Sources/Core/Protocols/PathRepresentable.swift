//
//  PathRepresentable.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-22.
//

import Foundation

/// A type that can be represented as a path string.
package protocol PathRepresentable {
    /// The string representation of the path.
    var pathString: String { get }
}
