//
//  StencilTemplateClient.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-05.
//

import Dependencies
import DependenciesMacros
import Foundation
import PathKit
import Stencil

/// A client for processing Stencil templates and injecting project-specific values.
@DependencyClient
package struct StencilTemplateClient: Sendable {
    /// Updates the root module template file in-place.
    /// - Parameters:
    ///   - path: The path to the template file.
    ///   - projectName: The name of the project to inject into the file template.
    ///   - moduleName: The name of the module to inject into the file template.
    package var processRootModuleTemplate:
        @Sendable (
            _ atPath: Path,
            _ projectName: String,
            _ moduleName: String
        ) async throws -> Void

    /// Updates the selected target app template files in-place.
    /// - Parameters:
    ///   - targetAppTemplates: The file paths of the target app templates to process.
    ///   - moduleName: The name of the root module to inject into the templates.
    package var processSelectedTargetsAppTemplates:
        @Sendable (
            _ targetAppTemplates: [Path],
            _ moduleName: String
        ) async throws -> Void
}

extension StencilTemplateClient: DependencyKey {
    /// The live implementation of `StencilTemplateClient`.
    package static var liveValue: Self {
        Self(
            processRootModuleTemplate: { rootModule, projectName, moduleName in
                do {
                    let context = ["projectName": projectName, "moduleName": moduleName]
                    try rootModule.updateTemplateWith(context)
                } catch let error {
                    throw Error.rootModuleProcessingFailed(underlyingError: error.localizedDescription)
                }
            },
            processSelectedTargetsAppTemplates: { targetAppTemplates, moduleName in
                do {
                    let context = ["rootModule": moduleName]
                    try targetAppTemplates.forEach { try $0.updateTemplateWith(context) }
                } catch {
                    throw Error.appTargetsProcessingFailed(underlyingError: error.localizedDescription)
                }
            }
        )
    }
}

package extension DependencyValues {
    /// A client for processing Stencil templates.
    var stencilTemplateClient: StencilTemplateClient {
        get { self[StencilTemplateClient.self] }
        set { self[StencilTemplateClient.self] = newValue }
    }
}

package extension StencilTemplateClient {
    /// Errors that can be thrown by the StencilTemplateClient.
    enum Error: LocalizedError, Equatable {
        /// An error indicating that the provided path for a template is not a file.
        case notAFile(path: String)
        /// An error indicating that processing the root module template failed.
        case rootModuleProcessingFailed(underlyingError: String)
        /// An error indicating that processing the app targets templates failed.
        case appTargetsProcessingFailed(underlyingError: String)

        package var errorDescription: String? {
            switch self {
                case .notAFile(let path):
                    return "The template at \(path) is not a file."
                case .rootModuleProcessingFailed(let underlyingError):
                    return "Failed to update root module stencil template: \(underlyingError)"
                case .appTargetsProcessingFailed(let underlyingError):
                    return "Failed to update app target stencil template: \(underlyingError)"
            }
        }
    }

}

private extension Path {
    func updateTemplateWith(_ context: [String: Any]) throws {
        guard isFile else {
            throw StencilTemplateClient.Error.notAFile(path: string)
        }

        let environment = Environment()
        let templateContent = try read(.utf8)
        let updatedTemplateContent = try environment.renderTemplate(string: templateContent, context: context)
        try write(updatedTemplateContent, encoding: .utf8)
    }
}
