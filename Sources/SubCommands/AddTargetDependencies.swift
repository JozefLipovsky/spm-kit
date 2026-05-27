//
//  AddTargetDependencies.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-05-26.
//

import ArgumentParser
import Core
import Foundation

package struct AddTargetDependencies: AsyncParsableCommand {
    package static let configuration = CommandConfiguration(
        commandName: "add-target-dependencies",
        abstract: "Adds dependencies to an existing target in the current SPM project.",
        discussion:
            """
            Adds additional existing dependencies to an existing target in the Swift package. The target and dependencies can be provided via command-line arguments; missing values will be prompted for interactively.
            """
    )

    package init() {}
}
