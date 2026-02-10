//
//  ProjectDirectory.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-17.
//

import Foundation
import PathKit

/// Defines the main structural components of a project.
package enum ProjectDirectory: Equatable, PathSegmentConvertible {
    /// Represents the root directory of the project, which can contain a file.
    case root(File? = nil)
    /// Represents the application-specific directory, which can contain a specific app target directory(ies).
    case app(AppsDirectory? = nil)
    /// Represents the SPM Modules directory, which can contain sources and tests directories.
    case modules(ModulesDirectory? = nil)

    /// The path segments representing the project directory.
    package var pathSegments: [String] {
        switch self {
            case .root(let file):
                return file?.pathSegments ?? []
            case .app(let app):
                return ["App"] + (app?.pathSegments ?? [])
            case .modules(let modules):
                return ["Modules"] + (modules?.pathSegments ?? [])
        }
    }

    /// A new project directory instance with the base name replaced by the new name.
    /// - Parameter newBaseName: The new base name for the directory or its file.
    /// - Returns: A new `ProjectDirectory` instance with the updated name.
    package func renamingBase(to newBaseName: String) -> Self {
        switch self {
            case .root(let file):
                return .root(file?.renamingBase(to: newBaseName))
            case .app(let app):
                return .app(app?.renamingBase(to: newBaseName))
            case .modules(let modules):
                return .modules(modules?.renamingBase(to: newBaseName))
        }
    }
}

extension ProjectDirectory {
    /// Defines the components within the 'App' directory.
    package enum AppsDirectory: Equatable, PathSegmentConvertible {
        /// Represents the root of the 'App' directory, which can optionally contain a file.
        case root(File? = nil)
        /// The directory for the iOS-specific target.
        case iOS(File? = nil)
        /// The directory for the macOS-specific target.
        case macOS(File? = nil)
        /// The directory for the tvOS-specific target.
        case tvOS(File? = nil)
        /// The directory for the visionOS-specific target.
        case visionOS(File? = nil)
        /// The directory for the watchOS-specific target.
        case watchOS(File? = nil)

        /// The path segments representing the apps directory.
        package var pathSegments: [String] {
            switch self {
                case .root(let file):
                    return file?.pathSegments ?? []
                case .iOS(let file):
                    return ["iOS"] + (file?.pathSegments ?? [])
                case .macOS(let file):
                    return ["macOS"] + (file?.pathSegments ?? [])
                case .tvOS(let file):
                    return ["tvOS"] + (file?.pathSegments ?? [])
                case .visionOS(let file):
                    return ["visionOS"] + (file?.pathSegments ?? [])
                case .watchOS(let file):
                    return ["watchOS"] + (file?.pathSegments ?? [])
            }
        }

        /// A new apps directory instance with the base name replaced by the new name.
        /// - Parameter newBaseName: The new base name for the directory or its file.
        /// - Returns: A new `AppsDirectory` instance with the updated name.
        package func renamingBase(to newBaseName: String) -> Self {
            switch self {
                case .root(let file):
                    return .root(file?.renamingBase(to: newBaseName))
                case .iOS(let file):
                    return .iOS(file?.renamingBase(to: newBaseName))
                case .macOS(let file):
                    return .macOS(file?.renamingBase(to: newBaseName))
                case .tvOS(let file):
                    return .tvOS(file?.renamingBase(to: newBaseName))
                case .visionOS(let file):
                    return .visionOS(file?.renamingBase(to: newBaseName))
                case .watchOS(let file):
                    return .watchOS(file?.renamingBase(to: newBaseName))
            }
        }
    }

    /// Defines the structure of the 'Modules' directory.
    package enum ModulesDirectory: Equatable, PathSegmentConvertible {
        /// Represents the `Package.swift` manifest file.
        case packageManifest
        /// Represents the 'Sources' directory, containing a specific module(s).
        case sources(ModuleDirectory)
        /// Represents the 'Tests' directory, containing tests for a specific module(s).
        case tests(TestDirectory)

        /// The path segments representing the modules directory.
        package var pathSegments: [String] {
            switch self {
                case .packageManifest:
                    return ["Package.swift"]
                case .sources(let module):
                    return ["Sources"] + module.pathSegments
                case .tests(let test):
                    return ["Tests"] + test.pathSegments
            }
        }

        /// A new modules directory instance with the base name replaced by the new name.
        /// - Parameter newBaseName: The new base name for the module.
        /// - Returns: A new `ModulesDirectory` instance with the updated name.
        package func renamingBase(to newBaseName: String) -> Self {
            switch self {
                case .packageManifest:
                    return self
                case .sources(let module):
                    return .sources(module.renamingBase(to: newBaseName))
                case .tests(let test):
                    return .tests(test.renamingBase(to: newBaseName))
            }
        }
    }
}

extension ProjectDirectory.ModulesDirectory {
    /// Represents a single module within the 'Sources' directory.
    package enum ModuleDirectory: Equatable, PathSegmentConvertible {
        /// A module with a given name, which can optionally contain a specific file.
        case module(_ name: String, file: File? = nil)

        /// The path segments representing the module directory.
        package var pathSegments: [String] {
            switch self {
                case .module(let name, let file):
                    return [name] + (file?.pathSegments ?? [])
            }
        }

        /// A new module directory instance with the base name replaced by the new name.
        /// - Parameter newBaseName: The new base name for the module or its file.
        /// - Returns: A new `ModuleDirectory` instance with the updated name.
        package func renamingBase(to newBaseName: String) -> Self {
            switch self {
                case .module(let name, let file):
                    guard let file = file else {
                        return .module(newBaseName, file: nil)
                    }
                    return .module(name, file: file.renamingBase(to: newBaseName))
            }
        }
    }

    /// Represents a single test module within the 'Tests' directory.
    package enum TestDirectory: Equatable, PathSegmentConvertible {
        /// A test module with a given name, which can optionally contain a specific file.
        case module(_ name: String, file: File? = nil)

        /// The path segments representing the test directory.
        package var pathSegments: [String] {
            switch self {
                case .module(let name, let file):
                    return [name] + (file?.pathSegments ?? [])
            }
        }

        /// A new test directory instance with the base name replaced by the new name.
        /// - Parameter newBaseName: The new base name for the test module or its file.
        /// - Returns: A new `TestDirectory` instance with the updated name.
        package func renamingBase(to newBaseName: String) -> Self {
            switch self {
                case .module(let name, let file):
                    guard let file = file else {
                        return .module(newBaseName, file: nil)
                    }
                    return .module(name, file: file.renamingBase(to: newBaseName))
            }
        }
    }
}
