//
//  AddTargetDependencies.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-05-26.
//

import ArgumentParser
import Core
import Dependencies
import Foundation
import PathKit
import System

package struct AddTargetDependencies: AsyncParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "add-target-dependencies",
        abstract: "Adds dependencies to an existing target in the current SPM project.",
        discussion:
            """
            Adds additional existing dependencies to an existing target in the Swift package. The target and dependencies can be provided via command-line arguments; missing values will be prompted for interactively.
            """
    )

    @Argument(help: "The name of the dependency to add.")
    var dependencyName: String?

    @Argument(help: "The name of the target to which dependencies will be added.")
    var targetName: String?

    @Option(help: "The name of the package in which the dependency resides.")
    var package: String?

    package init() {}
}
