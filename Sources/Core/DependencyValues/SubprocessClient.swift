//
//  SubprocessClient.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-07-03.
//

import Dependencies
import DependenciesMacros
import Foundation
import IssueReporting
import Subprocess
import System

/// A client for running subprocess commands.
@DependencyClient
package struct SubprocessClient: Sendable {
    /// Runs a shell command.
    /// - Parameters:
    ///   - command: The `ShellCommand` to execute.
    ///   - workingDirectory: The working directory for the command.
    package var run: @Sendable (_ command: ShellCommand, _ workingDirectory: FilePath?) async throws -> Void

    /// Runs a shell command and returns its standard output.
    /// - Parameters:
    ///   - command: The `ShellCommand` to execute.
    ///   - workingDirectory: The working directory for the command.
    /// - Returns: The standard output of the command.
    package var runAndCapture: @Sendable (_ command: ShellCommand, _ workingDirectory: FilePath?) async throws -> Data
}

extension SubprocessClient: DependencyKey {
    /// The live implementation of `SubprocessClient`.
    package static let liveValue = Self(
        run: { command, workingDirectory in
            let result = try await execute(command, in: workingDirectory)

            if let error = result.standardError, !error.isEmpty {
                throw Error.subprocessFailed(underlyingError: error)
            }

            if let output = result.standardOutput, !output.isEmpty {
                print(output)
            }
        },
        runAndCapture: { command, workingDirectory in
            let result = try await execute(command, in: workingDirectory)

            if let error = result.standardError, !error.isEmpty {
                throw Error.subprocessFailed(underlyingError: error)
            }

            guard
                let output = result.standardOutput,
                !output.isEmpty,
                let data = output.data(using: .utf8)
            else {
                throw Error.missingOutput(command: "\(command.executable) \(command.arguments)")
            }

            return data
        }
    )
}

package extension DependencyValues {
    /// A client for running subprocess commands.
    var subprocessClient: SubprocessClient {
        get { self[SubprocessClient.self] }
        set { self[SubprocessClient.self] = newValue }
    }
}

package extension SubprocessClient {
    /// Errors that can be thrown by the SubprocessClient.
    enum Error: LocalizedError, Equatable {
        /// An error indicating that a subprocess command failed to execute.
        case subprocessFailed(underlyingError: String)
        /// An error indicating that the subprocess command finished successfully but returned no output.
        case missingOutput(command: String)

        package var errorDescription: String? {
            switch self {
                case .subprocessFailed(let underlyingError):
                    var sanitizedError = underlyingError.trimmingCharacters(in: .whitespacesAndNewlines)

                    // Remove duplicate error string prefix
                    let pattern = "^error\\s*:?\\s*"
                    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                        let range = NSRange(location: 0, length: sanitizedError.utf16.count)
                        sanitizedError = regex.stringByReplacingMatches(
                            in: sanitizedError,
                            options: [],
                            range: range,
                            withTemplate: ""
                        )
                    }

                    return "Command execution failed: " + sanitizedError
                case .missingOutput(let command):
                    return "The command '\(command)' finished successfully but returned no output."
            }
        }
    }
}

private extension SubprocessClient {
    static func execute(
        _ command: ShellCommand,
        in workingDirectory: FilePath?
    ) async throws -> CollectedResult<StringOutput<Unicode.UTF8>, StringOutput<Unicode.UTF8>> {
        try await Subprocess.run(
            command.executable,
            arguments: command.arguments,
            workingDirectory: workingDirectory,
            input: .none,
            output: .string(limit: .max),
            error: .string(limit: .max)
        )
    }
}
