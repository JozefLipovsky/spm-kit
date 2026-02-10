//
//  ConfigClientTests.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-21.
//

import Core
import Dependencies
import PathKit
import TestHelpers
import Testing

@Suite("ConfigClient Tests", .tags(.integration))
struct ConfigClientTests {
    @Test("modulesPath - with valid config - returns absolute path to modules directory")
    func modulesPath_withValidConfig_returnsAbsolutePathToModulesDirectory() async throws {
        try await withDependencies {
            $0.configClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let configPath = tempPath + "spm-kit-config.yaml"
            try configPath.write(
                """
                modules-path: ./Modules
                swift-format-config-path: .swift-format
                """
            )

            let modulesPath = tempPath + "Modules"
            try modulesPath.mkpath()

            @Dependency(\.configClient) var sut

            // When
            let result = try await sut.modulesPath(atConfigPath: configPath)

            // Then
            #expect(result == modulesPath)
        }
    }

    @Test("modulesPath - when modules directory does not exist - throws modulesDirectoryNotFound error")
    func modulesPath_whenModulesDirectoryDoesNotExist_throwsModulesDirectoryNotFoundError() async throws {
        try await withDependencies {
            $0.configClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let configPath = tempPath + "spm-kit-config.yaml"
            try configPath.write(
                """
                modules-path: ./Missing
                swift-format-config-path: .swift-format
                """
            )

            @Dependency(\.configClient) var sut

            let error = await #expect(throws: ConfigClient.Error.self) {
                // When
                _ = try await sut.modulesPath(atConfigPath: configPath)
            }

            // Then
            let expectedPath = (tempPath + "Missing").string
            #expect(error == .modulesDirectoryNotFound(path: expectedPath))
        }
    }

    @Test("modulesPath - when config file not found - throws initializationFailed error")
    func modulesPath_whenConfigFileNotFound_throwsInitializationFailedError() async throws {
        try await withDependencies {
            $0.configClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let configPath = tempPath + "non-existent.yaml"

            @Dependency(\.configClient) var sut

            let error = await #expect(throws: ConfigClient.Error.self) {
                // When
                _ = try await sut.modulesPath(atConfigPath: configPath)
            }

            // Then
            let errorDescription = try #require(error?.localizedDescription)
            #expect(errorDescription.contains("Failed to initialize configuration"))
        }
    }

    @Test("modulesPath - when modules-path key is missing - throws modulesPathNotFound error")
    func modulesPath_whenKeyMissing_throwsModulesPathNotFoundError() async throws {
        try await withDependencies {
            $0.configClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let configPath = tempPath + "spm-kit-config.yaml"
            try configPath.write(
                """
                invalid-modules-path: ./Modules
                swift-format-config-path: .swift-format
                """
            )

            @Dependency(\.configClient) var sut

            let error = await #expect(throws: ConfigClient.Error.self) {
                // When
                _ = try await sut.modulesPath(atConfigPath: configPath)
            }

            // Then
            #expect(error == .modulesPathNotFound)
        }
    }

    @Test("swiftFormatConfigPath - with valid config - returns absolute path to swift format config file")
    func swiftFormatConfigPath_withValidConfig_returnsAbsolutePathToSwiftFormatConfigFile() async throws {
        try await withDependencies {
            $0.configClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let configPath = tempPath + "spm-kit-config.yaml"
            try configPath.write(
                """
                modules-path: ./Modules
                swift-format-config-path: .swift-format
                """
            )

            let swiftFormatConfigPath = tempPath + ".swift-format"
            try swiftFormatConfigPath.write("some swift format config content")

            @Dependency(\.configClient) var sut

            // When
            let result = try await sut.swiftFormatConfigPath(atConfigPath: configPath)

            // Then
            #expect(result == swiftFormatConfigPath)
        }
    }

    @Test("swiftFormatConfigPath - when swift format file does not exist - throws swiftFormatConfigNotFound error")
    func swiftFormatConfigPath_whenSwiftFormatFileDoesNotExist_throwsSwiftFormatConfigNotFound_error() async throws {
        try await withDependencies {
            $0.configClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let configPath = tempPath + "spm-kit-config.yaml"
            try configPath.write(
                """
                modules-path: ./Modules
                swift-format-config-path: .swift-format
                """
            )

            @Dependency(\.configClient) var sut

            let error = await #expect(throws: ConfigClient.Error.self) {
                // When
                _ = try await sut.swiftFormatConfigPath(atConfigPath: configPath)
            }

            // Then
            let expectedPath = (tempPath + ".swift-format").string
            #expect(error == .swiftFormatConfigNotFound(path: expectedPath))
        }
    }

    @Test("swiftFormatConfigPath - when swift-format key is missing - throws swiftFormatConfigPathNotFound error")
    func swiftFormatConfigPath_whenKeyIsMissing_throwsSwiftFormatConfigPathNotFound_error() async throws {
        try await withDependencies {
            $0.configClient = .liveValue
        } operation: {
            // Given
            let tempPath = try Path.uniqueTemporary()
            defer { try? tempPath.delete() }

            let configPath = tempPath + "spm-kit-config.yaml"
            try configPath.write(
                """
                modules-path: ./Modules
                invalid-swift-format-config-path: .swift-format
                """
            )

            @Dependency(\.configClient) var sut

            let error = await #expect(throws: ConfigClient.Error.self) {
                // When
                _ = try await sut.swiftFormatConfigPath(atConfigPath: configPath)
            }

            // Then
            #expect(error == .swiftFormatConfigPathNotFound)
        }
    }
}

@Suite("ConfigClient.Error Tests", .tags(.unit))
struct ConfigClientErrorTests {
    @Test("errorDescription - with initializationFailed - returns correctly formatted message")
    func errorDescription_withInitializationFailed_returnsCorrectlyFormattedMessage() {
        // Given, When
        let sut = ConfigClient.Error.initializationFailed(underlyingError: "Stub error")

        // Then
        #expect(sut.errorDescription == "Failed to initialize configuration: Stub error")
    }

    @Test("errorDescription - with modulesPathNotFound - returns correctly formatted message")
    func errorDescription_withModulesPathNotFound_returnsCorrectlyFormattedMessage() {
        // Given, When
        let sut = ConfigClient.Error.modulesPathNotFound

        // Then
        #expect(sut.errorDescription == "Could not find a 'modules-path' in the spm-kit-config.yaml configuration.")
    }

    @Test("errorDescription - with modulesDirectoryNotFound - returns correctly formatted message")
    func errorDescription_withModulesDirectoryNotFound_returnsCorrectlyFormattedMessage() {
        // Given, When
        let path = "/path/to/Modules"
        let sut = ConfigClient.Error.modulesDirectoryNotFound(path: path)

        // Then
        #expect(sut.errorDescription == "The modules directory at '/path/to/Modules' could not be found.")
    }

    @Test("errorDescription - with swiftFormatConfigNotFound - returns correctly formatted message")
    func errorDescription_withSwiftFormatConfigNotFound_returnsCorrectlyFormattedMessage() {
        // Given, When
        let path = "/path/to/.swift-format"
        let sut = ConfigClient.Error.swiftFormatConfigNotFound(path: path)

        // Then
        #expect(sut.errorDescription == "The Swift format config file at '/path/to/.swift-format' could not be found.")
    }

    @Test("errorDescription - with swiftFormatConfigPathNotFound - returns correctly formatted message")
    func errorDescription_withSwiftFormatConfigPathNotFound_returnsCorrectlyFormattedMessage() {
        // Given, When
        let sut = ConfigClient.Error.swiftFormatConfigPathNotFound

        // Then
        let expectedError = "Could not find a 'swift-format-config-path' in the spm-kit-config.yaml configuration."
        #expect(sut.errorDescription == expectedError)
    }
}
