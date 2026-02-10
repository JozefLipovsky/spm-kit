//
//  XcodeProjClient.swift
//  SPMKit
//
//  Created by Jozef Lipovsky on 2025-09-27.
//

import Dependencies
import DependenciesMacros
import Foundation
import PathKit
import XcodeProj

/// A client for editing Xcode projects and workspaces.
@DependencyClient
package struct XcodeProjClient: Sendable {
    /// Updates the project reference in the workspace configuration.
    /// - Parameters:
    ///   - inWorkspace: The `Path` to the `.xcworkspace` file.
    ///   - newProjectName: The new name for the `.xcodeproj` file.
    package var updateProjectReference: @Sendable (_ inWorkspace: Path, _ newProjectName: String) async throws -> Void

    /// Configures the `.xcodeproj` and synchronizes associated scheme references.
    /// - Parameter configuration: The `XcodeProjConfiguration` to use for configuring the project.
    package var configureProject: @Sendable (_ configuration: ProjectConfiguration) async throws -> Void
}

extension XcodeProjClient: DependencyKey {
    /// The live implementation of `XcodeProjClient`.
    package static var liveValue: Self {
        Self(
            updateProjectReference: { workspacePath, newProjectName in
                do {
                    let workspace = try XCWorkspace(path: workspacePath)
                    workspace.updateProjectName(newProjectName)
                    try workspace.write(path: workspacePath)
                } catch {
                    throw Error.workspaceUpdateFailed(underlyingError: error.localizedDescription)
                }
            },
            configureProject: { configuration in
                do {
                    // XcodeProj
                    let xcodeProj = try XcodeProj(path: configuration.projectPath)
                    try xcodeProj.remove(targets: configuration.targetsToDelete, at: configuration.projectRootPath)
                    try xcodeProj.configure(
                        targets: configuration.selectedTargets,
                        withProjectName: configuration.newProjectName,
                        bundleIdentifier: configuration.bundleIdentifier,
                        rootModuleName: configuration.rootModuleName,
                        selectedPlatforms: configuration.selectedPlatforms
                    )
                    try xcodeProj.write(path: configuration.projectPath)
                } catch {
                    throw Error.projectConfigurationFailed(underlyingError: error.localizedDescription)
                }
            }
        )
    }
}

package extension DependencyValues {
    /// A client for editing Xcode projects and workspaces.
    var xcodeProjClient: XcodeProjClient {
        get { self[XcodeProjClient.self] }
        set { self[XcodeProjClient.self] = newValue }
    }
}

package extension XcodeProjClient {
    /// An error related to Xcode project operations.
    enum Error: LocalizedError, Equatable {
        /// An error indicating that updating the workspace failed.
        case workspaceUpdateFailed(underlyingError: String)
        /// An error indicating that removing app targets failed.
        case appTargetsRemovalFailed(underlyingError: String)
        /// An error indicating that configuring frameworks build phase failed.
        case buildPhaseConfigurationFailed(underlyingError: String)
        /// An error indicating that project configuration failed.
        case projectConfigurationFailed(underlyingError: String)
        /// An error indicating that a target which is supposed to be deleted was not found.
        case targetToDeleteNotFound(targetName: String)
        /// An error indicating that a selected target was not found.
        case selectedTargetNotFound(targetName: String)

        package var errorDescription: String? {
            switch self {
                case .workspaceUpdateFailed(let underlyingError):
                    return "Workspace configuration failed: " + underlyingError
                case .appTargetsRemovalFailed(let underlyingError):
                    return "Application targets removal failed: " + underlyingError
                case .buildPhaseConfigurationFailed(let underlyingError):
                    return "Frameworks build phase configuration failed: " + underlyingError
                case .projectConfigurationFailed(let underlyingError):
                    return "Project configuration failed: " + underlyingError
                case .targetToDeleteNotFound(let targetName):
                    return "Target to delete not found: " + targetName
                case .selectedTargetNotFound(let targetName):
                    return "Selected target not found: " + targetName
            }
        }
    }
}

private extension XCWorkspace {
    func updateProjectName(_ projectName: String) {
        let updatedChildren = data.children.map { element in
            guard case .file(let fileRef) = element else {
                return element
            }

            let filePath = Path(fileRef.location.path)
            guard filePath.extension == "xcodeproj" else {
                return element
            }

            let updatedPath = filePath.parent() + "\(projectName).xcodeproj"
            return .file(XCWorkspaceDataFileRef(location: .group(updatedPath.string)))
        }

        data.children = updatedChildren
    }
}

private extension XcodeProj {
    func remove(targets targetsToDelete: [ProjectDirectory], at projectRootPath: Path) throws {
        try targetsToDelete.forEach { target in
            guard
                let targetName = target.pathSegments.last,
                let targetToDelete = pbxproj.nativeTargets.first(where: { $0.name == targetName })
            else {
                let targetName = target.pathSegments.last ?? "unknown"
                throw XcodeProjClient.Error.targetToDeleteNotFound(targetName: targetName)
            }

            var directoriesToDelete = [projectRootPath + targetName]

            let filePaths = targetToDelete.filePaths()
            let objectsToDelete = targetToDelete.propertyIdentifiers()

            let filesToDelete = pbxproj.fileReferences.filter { file in
                filePaths.contains(file.path) || filePaths.contains(file.parent?.path)
            }

            let fileObjectsToDelete = filesToDelete.map(\.uuid)

            // Target PBXObject(s)

            pbxproj.forEach { projectObject in
                if objectsToDelete.contains(projectObject.uuid) {
                    pbxproj.delete(object: projectObject)
                }

                if fileObjectsToDelete.contains(projectObject.uuid) {
                    pbxproj.delete(object: projectObject)
                }
            }

            pbxproj.groups.forEach { projectGroup in
                filesToDelete.forEach { fileToDelete in
                    if let groupPath = projectGroup.path, groupPath == fileToDelete.parent?.path {
                        directoriesToDelete.append(projectRootPath + groupPath)
                        pbxproj.delete(object: projectGroup)
                    }

                    projectGroup.children.removeAll { child in
                        child == fileToDelete
                    }
                }
            }

            // PBXProject

            pbxproj.rootObject?.targets.removeAll { $0 == targetToDelete }
            pbxproj.rootObject?.removeTargetAttributes(target: targetToDelete)

            // XCScheme

            sharedData?.schemes.removeAll { $0.name == targetName }

            // Directories cleanup

            do {
                try directoriesToDelete.forEach { try $0.delete() }
            } catch {
                throw XcodeProjClient.Error.appTargetsRemovalFailed(underlyingError: error.localizedDescription)
            }
        }
    }

    func configure(
        targets: [ProjectDirectory],
        withProjectName projectName: String,
        bundleIdentifier: String,
        rootModuleName: String,
        selectedPlatforms: [any PlatformVersion]
    ) throws {
        // The project file has already been renamed using a shell command.
        // This will ensure that the PBXProject reference comments reflect the new name as well.
        let projectName = projectName
        pbxproj.rootObject?.name = projectName

        try targets.forEach { target in
            guard
                let targetName = target.pathSegments.last,
                let platformVersion = selectedPlatforms.first(where: { $0.platform.identifier == targetName }),
                let schemeToUpdate = sharedData?.schemes.first(where: { $0.name == targetName }),
                let targetToUpdate = pbxproj.nativeTargets.first(where: { $0.name == targetName })
            else {
                let targetName = target.pathSegments.last ?? "unknown"
                throw XcodeProjClient.Error.selectedTargetNotFound(targetName: targetName)
            }

            // PBXTarget build settings

            let deploymentTargetSettingKey = platformVersion.platform.deploymentTargetSettingKey
            let deploymentTargetVersionValue = platformVersion.deploymentTargetSettingValue
            let displayNameSettingKey = platformVersion.platform.displayNameSettingKey
            let bundleIdentifierSettingKey = platformVersion.platform.bundleIdentifierSettingKey

            targetToUpdate.buildConfigurationList?.buildConfigurations.forEach { buildConfiguration in
                buildConfiguration.buildSettings[deploymentTargetSettingKey] = .string(deploymentTargetVersionValue)
                buildConfiguration.buildSettings[displayNameSettingKey] = .string(projectName)
                buildConfiguration.buildSettings[bundleIdentifierSettingKey] = .string(bundleIdentifier)
            }

            // XCScheme

            schemeToUpdate.buildAction?.buildActionEntries.forEach { schemeBuildAction in
                let currentContainer = schemeBuildAction.buildableReference.referencedContainer
                let updatedContainer = currentContainer.replacing("App", with: projectName)
                schemeBuildAction.buildableReference.referencedContainer = updatedContainer
            }

            if let launchActionBuildableReference = schemeToUpdate.launchAction?.runnable?.buildableReference {
                let currentContainer = launchActionBuildableReference.referencedContainer
                let updatedContainer = currentContainer.replacing("App", with: projectName)
                schemeToUpdate.launchAction?.runnable?.buildableReference?.referencedContainer = updatedContainer
            }

            if let profileActionBuildableReference = schemeToUpdate.profileAction?.runnable?.buildableReference {
                let currentContainer = profileActionBuildableReference.referencedContainer
                let updatedContainer = currentContainer.replacing("App", with: projectName)
                schemeToUpdate.profileAction?.runnable?.buildableReference?.referencedContainer = updatedContainer
            }

            // XcodeProj & PBXTarget dependencies

            let rootModuleDependency = XCSwiftPackageProductDependency(productName: rootModuleName)
            pbxproj.add(object: rootModuleDependency)

            targetToUpdate.packageProductDependencies?.append(rootModuleDependency)

            let buildFile = PBXBuildFile(product: rootModuleDependency)
            pbxproj.add(object: buildFile)

            do {
                try targetToUpdate.frameworksBuildPhase()?.files?.append(buildFile)
            } catch {
                throw XcodeProjClient.Error.buildPhaseConfigurationFailed(underlyingError: error.localizedDescription)
            }
        }
    }
}
