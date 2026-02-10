//
//  SubprocessClientTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-06.
//

import Core
import Dependencies
import PathKit
import Subprocess
import System
import TestHelpers
import Testing

@Suite("SubprocessClient Tests", .tags(.integration))
struct SubprocessClientTests {
    @Test("run - with succeeding command - completes without error")
    func run_succeedingCommand_completesWithoutError() async throws {
        try await withDependencies {
            $0.subprocessClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let sourceFile = tempPath + "source.txt"
            try sourceFile.write("test")

            let destinationDir = tempPath + "destination"
            try destinationDir.mkdir()

            @Dependency(\.subprocessClient) var sut

            // When
            try await sut.run(
                .update(.copy(TemplateItem(path: sourceFile.string), to: .root())),
                FilePath(destinationDir.string)
            )

            // Then
            let copiedFile = destinationDir + "source.txt"
            #expect(copiedFile.exists)
        }
    }

    @Test("run - with failing command - throws SubprocessClient.Error")
    func run_withFailingCommand_throwsCommandError() async throws {
        try await withDependencies {
            $0.subprocessClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            @Dependency(\.subprocessClient) var sut

            let error = await #expect(throws: SubprocessClient.Error.self) {
                // When
                try await sut.run(
                    .swift(.package(.setToolsVersion(version: "5.9"))),
                    FilePath(tempPath.string)
                )
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Command execution failed"))
        }
    }

    @Test("runAndCapture - with succeeding command and output - returns output")
    func runAndCapture_succeedingCommandWithOutput_returnsOutput() async throws {
        try await withDependencies {
            $0.subprocessClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let packagePath = tempPath + "Package.swift"
            try packagePath.write(
                """
                // swift-tools-version: 5.9
                import PackageDescription
                let package = Package(name: "StubPackage")
                """
            )

            @Dependency(\.subprocessClient) var sut

            // When
            let data = try await sut.runAndCapture(
                .swift(.package(.dumpPackage)),
                FilePath(tempPath.string)
            )

            // Then
            let output = try #require(String(data: data, encoding: .utf8))
            #expect(!output.isEmpty)
            #expect(output.contains("5.9"))
            #expect(output.contains("StubPackage"))
        }
    }

    @Test("runAndCapture - with succeeding command but empty output - throws missingOutput error")
    func runAndCapture_succeedingCommandWithEmptyOutput_throwsMissingOutputError() async throws {
        try await withDependencies {
            $0.subprocessClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let sourceFile = tempPath + "source.swift"
            try sourceFile.write("content")

            @Dependency(\.subprocessClient) var sut

            let error = await #expect(throws: SubprocessClient.Error.self) {
                // When
                _ = try await sut.runAndCapture(
                    .rename(.projectItem(.root(.file("source", fileExtension: .swift)), to: "destination")),
                    FilePath(tempPath.string)
                )
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("finished successfully but returned no output"))
        }
    }

    @Test("runAndCapture - with failing command - throws SubprocessClient.Error")
    func runAndCapture_withFailingCommand_throwsCommandError() async throws {
        try await withDependencies {
            $0.subprocessClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            @Dependency(\.subprocessClient) var sut

            let error = await #expect(throws: SubprocessClient.Error.self) {
                // When
                _ = try await sut.runAndCapture(
                    .swift(.package(.dumpPackage)),
                    FilePath(tempPath.string)
                )
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Command execution failed"))
        }
    }
}

@Suite("SubprocessClient.Error Tests", .tags(.unit))
struct SubprocessClientErrorTests {
    @Test("errorDescription - with subprocessFailed and error prefix - returns sanitized message")
    func errorDescription_withSubprocessFailedAndErrorPrefix_returnsSanitizedMessage() {
        // Given
        let errorMessage = "compilation failed"
        let standardError = "error: \(errorMessage)"
        let error = SubprocessClient.Error.subprocessFailed(underlyingError: standardError)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Command execution failed: \(errorMessage)")
    }

    @Test("errorDescription - with subprocessFailed and no error prefix - returns full message")
    func errorDescription_withSubprocessFailedAndNoErrorPrefix_returnsFullMessage() {
        // Given
        let errorMessage = "tests failed"
        let error = SubprocessClient.Error.subprocessFailed(underlyingError: errorMessage)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Command execution failed: \(errorMessage)")
    }

    @Test("errorDescription - with subprocessFailed and whitespace - returns trimmed message")
    func errorDescription_withSubprocessFailedAndWhitespace_returnsTrimmedMessage() {
        // Given
        let errorMessage = "invalid arguments"
        let standardError = "  \n \(errorMessage) \n  "
        let error = SubprocessClient.Error.subprocessFailed(underlyingError: standardError)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "Command execution failed: \(errorMessage)")
    }

    @Test("errorDescription - with missingOutput - returns correct message")
    func errorDescription_withMissingOutput_returnsCorrectMessage() {
        // Given
        let command = "swift package dump-package"
        let error = SubprocessClient.Error.missingOutput(command: command)

        // When
        let sut = error.errorDescription

        // Then
        #expect(sut == "The command 'swift package dump-package' finished successfully but returned no output.")
    }
}
