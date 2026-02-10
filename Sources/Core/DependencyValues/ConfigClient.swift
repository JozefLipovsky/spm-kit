//
//  ConfigClient.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-12-18.
//

import Configuration
import Dependencies
import DependenciesMacros
import Foundation
import PathKit
import SystemPackage

/// A client for retrieving project configuration values from the 'spm-kit-config.yaml' file.
@DependencyClient
package struct ConfigClient: Sendable {
    /// Retrieves the path to the modules directory from the configuration file.
    /// - Parameters:
    ///   - configPath: The absolute path to the 'spm-kit-config.yaml' file.
    /// - Returns: The absolute path to the modules directory.
    package var modulesPath: @Sendable (_ atConfigPath: Path) async throws -> Path

    /// Retrieves the path to the Swift format configuration file from the configuration file.
    /// - Parameters:
    ///   - configPath: The absolute path to the 'spm-kit-config.yaml' file.
    /// - Returns: The absolute path to the Swift format configuration file.
    package var swiftFormatConfigPath: @Sendable (_ atConfigPath: Path) async throws -> Path
}

extension ConfigClient: DependencyKey {
    /// The live implementation of `ConfigClient`.
    package static var liveValue: Self {
        Self(
            modulesPath: { configPath in
                let configReader = try await configReader(forConfigFileAt: configPath.systemPackageFilePath)
                return try configReader.modulesPath(configPath: configPath)
            },
            swiftFormatConfigPath: { configPath in
                let configReader = try await configReader(forConfigFileAt: configPath.systemPackageFilePath)
                return try configReader.swiftFormatConfigPath(configPath: configPath)
            }
        )
    }
}

package extension DependencyValues {
    /// A client for managing project configuration.
    var configClient: ConfigClient {
        get { self[ConfigClient.self] }
        set { self[ConfigClient.self] = newValue }
    }
}

package extension ConfigClient {
    /// Errors that can be thrown by the ConfigClient.
    enum Error: LocalizedError, Equatable {
        /// An error indicating that the ConfigReader initialization failed.
        case initializationFailed(underlyingError: String)
        /// An error indicating that the 'modules-path' key was not found in the configuration.
        case modulesPathNotFound
        /// An error indicating that the resolved modules directory path does not exist.
        case modulesDirectoryNotFound(path: String)
        /// An error indicating that the resolved Swift format config file path does not exist.
        case swiftFormatConfigNotFound(path: String)
        /// An error indicating that the 'swift-format-config-path' key was not found in the configuration.
        case swiftFormatConfigPathNotFound

        package var errorDescription: String? {
            switch self {
                case .initializationFailed(let underlyingError):
                    return "Failed to initialize configuration: \(underlyingError)"
                case .modulesPathNotFound:
                    return "Could not find a 'modules-path' in the spm-kit-config.yaml configuration."
                case .modulesDirectoryNotFound(let path):
                    return "The modules directory at '\(path)' could not be found."
                case .swiftFormatConfigNotFound(let path):
                    return "The Swift format config file at '\(path)' could not be found."
                case .swiftFormatConfigPathNotFound:
                    return "Could not find a 'swift-format-config-path' in the spm-kit-config.yaml configuration."
            }
        }
    }
}

private extension ConfigReader {
    func modulesPath(configPath: Path) throws -> Path {
        guard let configValue = string(forKey: "modules-path") else {
            throw ConfigClient.Error.modulesPathNotFound
        }

        let modulesPath = configPath.parent() + configValue
        guard modulesPath.exists else {
            throw ConfigClient.Error.modulesDirectoryNotFound(path: modulesPath.string)
        }

        return modulesPath
    }

    func swiftFormatConfigPath(configPath: Path) throws -> Path {
        guard let configValue = string(forKey: "swift-format-config-path") else {
            throw ConfigClient.Error.swiftFormatConfigPathNotFound
        }

        let swiftFormatConfigPath = configPath.parent() + configValue
        guard swiftFormatConfigPath.exists else {
            throw ConfigClient.Error.swiftFormatConfigNotFound(path: swiftFormatConfigPath.string)
        }

        return swiftFormatConfigPath
    }
}

private extension ConfigClient {
    static func configReader(forConfigFileAt filePath: FilePath) async throws -> ConfigReader {
        do {
            let provider = try await FileProvider<YAMLSnapshot>(filePath: filePath)
            return ConfigReader(provider: provider)
        } catch {
            throw Error.initializationFailed(underlyingError: error.localizedDescription)
        }
    }
}
