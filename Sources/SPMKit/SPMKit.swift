//
//  SPMKit.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-01.
//

import ArgumentParser
import SubCommands

@main
struct SPMKit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "spm-kit",
        abstract: "A Swift command-line tool to manage SPM modular projects.",
        usage: nil,
        discussion: "",
        version: "0.0.0",
        shouldDisplay: true,
        subcommands: [
            Bootstrap.self,
            AddModule.self
        ],
        groupedSubcommands: [],
        defaultSubcommand: nil,
        helpNames: nil,
        aliases: []
    )
}
