//
//  PathSegmentConvertible.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-17.
//

import Foundation

/// A type that can be converted into path segments.
package protocol PathSegmentConvertible: PathRepresentable {
    /// The path segments representing the type.
    var pathSegments: [String] { get }

    /// A path string with the last segment replaced by a new name.
    /// - Parameter newName: The new name for the last segment.
    /// - Returns: A path string with the renamed last segment.
    func pathStringRenamingLastSegment(with newName: String) -> String
}

package extension PathSegmentConvertible {
    var pathString: String {
        pathSegments.joined(separator: "/")
    }

    func pathStringRenamingLastSegment(with newName: String) -> String {
        var segments = Array(pathSegments.dropLast())
        segments.append(newName)
        return segments.joined(separator: "/")
    }
}
