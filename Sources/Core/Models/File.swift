//
//  File.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-17.
//

import Foundation

/// Represents a file with a name and an extension.
package enum File: Equatable, PathSegmentConvertible {
    /// A file with a specified name and extension.
    case file(_ name: String, fileExtension: FileExtension)

    /// The path segments representing the file.
    package var pathSegments: [String] {
        switch self {
            case .file(let name, let fileExtension):
                return [fileExtension.pathSegments.reduce(name) { $0 + $1 }]
        }
    }

    /// A new file instance with the base name replaced by the new name.
    /// - Parameter newBaseName: The new base name for the file.
    /// - Returns: A new `File` instance with the updated name.
    package func renamingBase(to newBaseName: String) -> Self {
        switch self {
            case .file(_, let fileExtension):
                return .file(newBaseName, fileExtension: fileExtension)
        }
    }
}

extension File {
    /// Defines supported file extensions.
    package enum FileExtension: Equatable, CaseIterable, PathSegmentConvertible {
        /// The `.swift` file extension.
        case swift
        /// The `.xcworkspace` file extension.
        case xcworkspace
        /// The `.xcodeproj` file extension.
        case xcodeproj

        /// The path segments representing the file extension.
        package var pathSegments: [String] {
            switch self {
                case .swift:
                    return [".swift"]
                case .xcworkspace:
                    return [".xcworkspace"]
                case .xcodeproj:
                    return [".xcodeproj"]
            }
        }
    }
}
