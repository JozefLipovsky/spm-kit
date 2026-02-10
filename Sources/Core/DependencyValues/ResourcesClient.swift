//
//  ResourcesClient.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-08-31.
//

import Dependencies
import DependenciesMacros
import Foundation

/// A client for accessing resources within the application bundle.
@DependencyClient
package struct ResourcesClient: Sendable {
    /// Returns the template item for a given template type.
    /// - Parameters:
    ///   - type: The `TemplateType` to retrieve the item for.
    /// - Returns: The requested `TemplateItem`.
    package var templateItem: @Sendable (_ type: TemplateType) async throws -> TemplateItem
}

extension ResourcesClient: DependencyKey {
    /// The live implementation of `ResourcesClient`.
    package static var liveValue: Self {
        Self(
            templateItem: { type in
                @Dependency(\.bundle) var bundle
                let path = try bundle.path(for: type)
                return type.templateItem(with: path)
            }
        )
    }
}

package extension DependencyValues {
    /// A client for accessing resources within the application bundle.
    var resourcesClient: ResourcesClient {
        get { self[ResourcesClient.self] }
        set { self[ResourcesClient.self] = newValue }
    }
}

package extension ResourcesClient {
    /// Errors that can be thrown by the ResourcesClient.
    enum Error: LocalizedError, Equatable {
        /// An error indicating that the project template was not found.
        case projectTemplateNotFound
        /// An error indicating that the root module template was not found.
        case rootModuleTemplateNotFound
        /// An error indicating that the SPM Kit config template was not found.
        case spmKitConfigTemplateNotFound
        /// An error indicating that the Swift format config template was not found.
        case swiftFormatConfigNotFound

        package var errorDescription: String? {
            switch self {
                case .projectTemplateNotFound:
                    return "The Xcode project template could not be found in the application's bundle."
                case .rootModuleTemplateNotFound:
                    return "The root module template could not be found in the application's bundle."
                case .spmKitConfigTemplateNotFound:
                    return "The SPM Kit config template could not be found in the application's bundle."
                case .swiftFormatConfigNotFound:
                    return "The Swift format config template could not be found in the application's bundle."
            }
        }
    }
}

private extension Bundle {
    func path(for type: TemplateType) throws -> String {
        guard
            let url = url(
                forResource: type.resource,
                withExtension: type.resourceExtension,
                subdirectory: type.subdirectory
            )
        else {
            throw type.resourceError
        }

        return url.path()
    }
}

private extension TemplateType {
    var resourceError: ResourcesClient.Error {
        switch self {
            case .rootModuleView:
                return .rootModuleTemplateNotFound
            case .xcodeProject:
                return .projectTemplateNotFound
            case .spmKitConfig:
                return .spmKitConfigTemplateNotFound
            case .swiftFormatConfig:
                return .swiftFormatConfigNotFound
        }
    }

    func templateItem(with path: String) -> TemplateItem {
        switch self {
            case .rootModuleView:
                return TemplateItem(path: path)
            case .xcodeProject:
                return TemplateItem(path: path, copyFlags: ["-R"])
            case .spmKitConfig:
                return TemplateItem(path: path)
            case .swiftFormatConfig:
                return TemplateItem(path: path)
        }
    }
}
