//
//  Path+Extensions.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-24.
//

import PathKit
import System
import SystemPackage

package extension Path {
    /// The path represented as a `System.FilePath`.
    var systemFilePath: System.FilePath {
        FilePath(string)
    }

    /// The path represented as a `SystemPackage.FilePath`.
    var systemPackageFilePath: SystemPackage.FilePath {
        FilePath(string)
    }

    /// A boolean value indicating whether the path contains a bootstrapped project structure.
    var containsBootstrappedProject: Bool {
        (self + "App").exists || (self + "Modules").exists
    }

    /// A boolean value indicating whether the path's last component matches the project name.
    /// - Parameter projectName: The project name to check.
    /// - Returns: `true` if the last component matches the project name.
    func isRootPath(of projectName: String) -> Bool {
        lastComponent == projectName
    }

    /// A new path with the filename replaced by the new name.
    /// - Parameter newFileName: The new filename.
    /// - Returns: A new `Path` instance with the updated filename.
    func pathByRenaming(to newFileName: String) -> Path {
        parent() + Path(newFileName)
    }

    /// The absolute path to a file found by recursively searching the current directory and its ancestors.
    /// - Parameter fileName: The name of the file to search for.
    /// - Returns: The absolute path to the file if found, otherwise `nil`.
    func ancestor(containing fileName: String) -> Path? {
        var currentPath = absolute()
        while currentPath.parent() != currentPath {
            let filePath = currentPath + fileName
            if filePath.exists { return filePath }
            currentPath = currentPath.parent()
        }

        return nil
    }
}
