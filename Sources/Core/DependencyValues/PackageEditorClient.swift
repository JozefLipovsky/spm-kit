//
//  PackageEditorClient.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-08-24.
//

import Dependencies
import DependenciesMacros
import Foundation
import PathKit
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

/// A client for editing Swift Package Manager manifests.
@DependencyClient
package struct PackageEditorClient: Sendable {
    /// Adds the specified platforms to the package manifest at the given path.
    /// - Parameters:
    ///   - platforms: An array of `PlatformVersion` types to add.
    ///   - toManifestAt: The `Path` to the package manifest file.
    package var add: @Sendable (_ platforms: [any PlatformVersion], _ toManifestAt: Path) async throws -> Void
}

extension PackageEditorClient: DependencyKey {
    /// The live implementation of `PackageEditorClient`.
    package static var liveValue: Self {
        Self(
            add: { platforms, packageManifestPath in
                do {
                    let currentPackageSource = try String(packageManifestPath.read(.utf8))
                    let currentPackageSourceFile = Parser.parse(source: currentPackageSource)
                    let rewriter = PlatformsArgumentRewriter(platformVersions: platforms)
                    let updatedPackageSourceFile = rewriter.visit(currentPackageSourceFile)
                    try packageManifestPath.write(updatedPackageSourceFile.description, encoding: .utf8)
                } catch {
                    throw Error.addPlatformsFailed(underlyingError: error.localizedDescription)
                }
            }
        )
    }
}

package extension DependencyValues {
    /// A client for editing Swift Package Manager manifests.
    var packageEditorClient: PackageEditorClient {
        get { self[PackageEditorClient.self] }
        set { self[PackageEditorClient.self] = newValue }
    }
}

package extension PackageEditorClient {
    /// Errors that can be thrown by the PackageEditorClient.
    enum Error: LocalizedError, Equatable {
        /// An error indicating that adding platforms to the package manifest failed.
        case addPlatformsFailed(underlyingError: String)

        package var errorDescription: String? {
            switch self {
                case .addPlatformsFailed(let underlyingError):
                    return "Adding package platforms failed: " + underlyingError
            }
        }
    }
}

private extension PackageEditorClient {
    class PlatformsArgumentRewriter: SyntaxRewriter {
        let platformVersions: [any PlatformVersion]

        init(platformVersions: [any PlatformVersion]) {
            self.platformVersions = platformVersions
        }

        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard
                let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self),
                calledExpression.baseName.text == "Package",
                let nameArgument = node.arguments.first
            else {
                return super.visit(node)
            }

            let updatedNameArgument = nameArgument.with(\.trailingComma, .commaToken())

            let platformsArgument = LabeledExprSyntax(
                leadingTrivia: .newline,
                label: .identifier("platforms", leadingTrivia: .spaces(4)),
                colon: .colonToken(),
                expression: ArrayExprSyntax(
                    leadingTrivia: .space,
                    leftSquare: .leftSquareToken(),
                    elements: ArrayElementListSyntax(
                        platformVersions.enumerated().map { index, platformVersion in
                            let isLastElement = index == platformVersions.count - 1
                            return ArrayElementSyntax(
                                leadingTrivia: .newline,
                                expression: FunctionCallExprSyntax(
                                    callee: MemberAccessExprSyntax(
                                        leadingTrivia: .spaces(8),
                                        period: .periodToken(),
                                        name: .identifier(platformVersion.platform.identifier)
                                    ),
                                    argumentList: { [platformVersion] in
                                        LabeledExprListSyntax(
                                            arrayLiteral: LabeledExprSyntax(
                                                expression: MemberAccessExprSyntax(
                                                    name: .identifier(platformVersion.versionIdentifier)
                                                )
                                            )
                                        )
                                    }
                                ),
                                trailingComma: isLastElement ? nil : .commaToken()
                            )
                        }
                    ),
                    rightSquare: .rightSquareToken(leadingTrivia: .newline + .spaces(4))
                )
            )

            let updatedArguments = LabeledExprListSyntax(arrayLiteral: updatedNameArgument, platformsArgument)
            return ExprSyntax(node.with(\.arguments, updatedArguments))
        }
    }
}
