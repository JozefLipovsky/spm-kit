//
//  SubprocessClientSpy.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2026-01-18.
//

import Core
import Dependencies
import Foundation
import System

actor SubprocessClientSpy {
    private(set) var runCalls: [Command]?
    private(set) var runAndCaptureCalls: [Command]?

    func recordRun(command: ShellCommand, workingDirectory: FilePath?) {
        let call = Command(command: command, workingDirectory: workingDirectory)
        if runCalls == nil {
            runCalls = [call]
        } else {
            runCalls?.append(call)
        }
    }

    func recordRunAndCapture(command: ShellCommand, workingDirectory: FilePath?) {
        let call = Command(command: command, workingDirectory: workingDirectory)
        if runAndCaptureCalls == nil {
            runAndCaptureCalls = [call]
        } else {
            runAndCaptureCalls?.append(call)
        }
    }
}

extension SubprocessClientSpy {
    struct Command {
        let command: ShellCommand
        let workingDirectory: FilePath?
    }
}
