//
//  TemplateItem.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-13.
//

import Foundation

/// Represents a template item.
package struct TemplateItem: Equatable, PathRepresentable {
    private let path: String

    /// Additional flags required when copying this template.
    package let copyFlags: [String]

    /// Creates a new template item.
    /// - Parameters:
    ///   - path: The path to the template.
    ///   - copyFlags: Additional flags required when copying the template.
    package init(path: String, copyFlags: [String] = []) {
        self.path = path
        self.copyFlags = copyFlags
    }

    /// The path to the template.
    package var pathString: String {
        path
    }
}
