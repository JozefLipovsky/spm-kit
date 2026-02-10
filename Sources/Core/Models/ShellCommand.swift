//
//  ShellCommand.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-16.
//

import Foundation
import Subprocess

/// A complete, validated command that can be executed by the application.
package enum ShellCommand: Equatable {
    /// A command to be executed by the `swift` tool.
    case swift(SwiftSubCommand)
    /// A command to be executed by the `cp` tool.
    case update(CopySubCommand)
    /// A command to be executed by the `mv` tool.
    case rename(RenameSubCommand)

    /// The executable used to run this command.
    package var executable: Subprocess.Executable {
        switch self {
            case .swift:
                return .name("swift")
            case .update:
                return .name("cp")
            case .rename:
                return .name("mv")
        }
    }

    /// The complete list of arguments for the command.
    package var arguments: Subprocess.Arguments {
        switch self {
            case .swift(let subCommand):
                return Subprocess.Arguments(subCommand.arguments)
            case .update(let subCommand):
                return Subprocess.Arguments(subCommand.arguments)
            case .rename(let subCommand):
                return Subprocess.Arguments(subCommand.arguments)
        }
    }
}

extension ShellCommand {
    /// A subcommand for the `swift` tool.
    package enum SwiftSubCommand: Equatable {
        /// A `swift package` subcommand.
        case package(PackageSubCommand, useCustomScratchPath: Bool = false)
        /// A `swift format` subcommand.
        case format(SwiftFormatSubcommand)

        fileprivate var arguments: [String] {
            switch self {
                case .package(let command, let useCustomScratchPath):
                    var baseArguments = ["package"]
                    // TODO: Figure out why we need --scratch-path in some cases
                    // Running some package commands without --scratch-path argument failing with error:
                    // Another instance of SwiftPM (PID: XYZ) is already running using '/Path/To/Modules/.build', waiting until that process has finished execution...
                    // Even though .build/scratchPath does not exists. Seems like running multiple sequential commands like add-target or add-target-dependency can trigger another SwiftPM process in background unrelated to the SPMKit that could cause default .build dir access deadlock.
                    if useCustomScratchPath {
                        let customPath = ".build/" + (command.arguments.first ?? "scratchPath")
                        baseArguments.append(contentsOf: ["--scratch-path", customPath])
                    }

                    return baseArguments + command.arguments
                case .format(let formatCommand):
                    return formatCommand.arguments
            }
        }
    }

    /// A subcommand for the `cp` tool.
    package enum CopySubCommand: Equatable {
        /// A command that copies a template item to a specified project destination.
        case copy(TemplateItem, to: ProjectDirectory)
        /// A command that replaces a project item with a template item.
        case replace(ProjectDirectory, with: TemplateItem)

        fileprivate var arguments: [String] {
            var arguments: [String] = []
            switch self {
                case .copy(let template, let projectDirectory):
                    arguments.append(contentsOf: template.copyFlags)
                    arguments.append(template.pathString)
                    arguments.append(projectDirectory.pathString)
                case .replace(let projectItem, let templateItem):
                    arguments.append(templateItem.pathString)
                    arguments.append(projectItem.pathString)
            }

            return arguments
        }
    }

    /// A subcommand for the `mv` tool.
    package enum RenameSubCommand: Equatable {
        /// A command that renames a project item with an updated name.
        case projectItem(ProjectDirectory, to: String)

        fileprivate var arguments: [String] {
            var arguments: [String] = []
            switch self {
                case .projectItem(let projectItem, let newName):
                    arguments.append(projectItem.pathString)
                    arguments.append(projectItem.renamingBase(to: newName).pathString)
            }

            return arguments
        }
    }
}

extension ShellCommand.SwiftSubCommand {
    /// A subcommand for the `swift package` command.
    package enum PackageSubCommand: Equatable {
        /// Adds a new target to the package manifest.
        case addTarget(
            name: String,
            type: TargetType = .library,
            dependencies: [String] = [],
            testingLibrary: TestingLibrary? = nil
        )
        /// Adds a new product to the package manifest.
        case addProduct(name: String, type: ProductType = .library, targets: [String] = [])
        /// Sets the Swift tools version for the package.
        case setToolsVersion(version: String)
        /// Prints parsed Package.swift as JSON.
        case dumpPackage
        /// Prints the resolved dependency graph.
        case showDependencies(format: DependencyGraphFormat = .json)
        /// Adds a new target dependency to the manifest.
        case addTargetDependency(dependencyName: String, targetName: String, package: String? = nil)

        fileprivate var arguments: [String] {
            var arguments: [String] = []
            switch self {
                case .addTarget(let name, let type, let dependencies, let testingLibrary):
                    arguments = ["add-target", name, "--type", type.rawValue]

                    if !dependencies.isEmpty {
                        arguments += ["--dependencies"] + dependencies
                    }

                    if let testingLibrary, type == .test {
                        arguments += ["--testing-library", testingLibrary.rawValue]
                    }
                case .addProduct(let name, let type, let targets):
                    arguments = ["add-product", name, "--type", type.rawValue]

                    if !targets.isEmpty {
                        arguments += ["--targets"] + targets
                    }
                case .setToolsVersion(let version):
                    arguments = ["tools-version", "--set", version]
                case .dumpPackage:
                    arguments = ["dump-package"]
                case .showDependencies(let format):
                    arguments = ["show-dependencies", "--format", format.rawValue]
                case .addTargetDependency(let dependencyName, let targetName, let package):
                    arguments = ["add-target-dependency", dependencyName, targetName]

                    if let package {
                        arguments += ["--package", package]
                    }
            }
            return arguments
        }
    }

    /// A subcommand for the `swift format` command.
    package enum SwiftFormatSubcommand: Equatable {
        /// A command that formats Swift source code with `--in-place --recursive .` arguments.
        case recursiveInPlace(configurationPath: String)

        fileprivate var arguments: [String] {
            switch self {
                case .recursiveInPlace(let configurationPath):
                    return ["format", "--configuration", configurationPath, "--in-place", "--recursive", "."]
            }
        }
    }
}
